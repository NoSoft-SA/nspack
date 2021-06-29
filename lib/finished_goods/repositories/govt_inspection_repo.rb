# frozen_string_literal: true

module FinishedGoodsApp
  class GovtInspectionRepo < BaseRepo # rubocop:disable Metrics/ClassLength
    build_for_select :pallets,
                     label: :pallet_number,
                     value: :id,
                     order_by: :pallet_number

    build_for_select :govt_inspection_sheets,
                     label: :id,
                     value: :id,
                     order_by: :id
    build_inactive_select :govt_inspection_sheets,
                          label: :id,
                          value: :id,
                          order_by: :id
    crud_calls_for :govt_inspection_sheets, name: :govt_inspection_sheet, exclude: [:create]

    build_for_select :govt_inspection_pallets,
                     label: :failure_remarks,
                     value: :id,
                     order_by: :failure_remarks
    build_inactive_select :govt_inspection_pallets,
                          label: :failure_remarks,
                          value: :id,
                          order_by: :failure_remarks
    crud_calls_for :govt_inspection_pallets, name: :govt_inspection_pallet, wrapper: GovtInspectionPallet

    crud_calls_for :vehicle_jobs, name: :vehicle_job, wrapper: VehicleJob
    crud_calls_for :vehicle_job_units, name: :vehicle_job_unit, wrapper: VehicleJobUnit

    def find_govt_inspection_sheet(id) # rubocop:disable Metrics/AbcSize
      hash = find_with_association(:govt_inspection_sheets, id,
                                   parent_tables: [{ parent_table: :target_market_groups,
                                                     columns: %i[target_market_group_name],
                                                     foreign_key: :packed_tm_group_id,
                                                     flatten_columns: { target_market_group_name: :packed_tm_group } },
                                                   { parent_table: :inspectors,
                                                     columns: %i[inspector_code],
                                                     foreign_key: :inspector_id,
                                                     flatten_columns: { inspector_code: :inspector_code } },
                                                   { parent_table: :destination_regions,
                                                     columns: %i[destination_region_name],
                                                     foreign_key: :destination_region_id,
                                                     flatten_columns: { destination_region_name: :destination_region } },
                                                   { parent_table: :destination_countries,
                                                     columns: %i[country_name],
                                                     foreign_key: :destination_country_id,
                                                     flatten_columns: { country_name: :destination_country } }])
      return nil unless hash

      hash[:allocated] = exists?(:govt_inspection_pallets, govt_inspection_sheet_id: id)
      hash[:passed_pallets] = exists?(:govt_inspection_pallets, govt_inspection_sheet_id: id, inspected: true, passed: true)
      hash[:failed_pallets] = exists?(:govt_inspection_pallets, govt_inspection_sheet_id: id, inspected: true, passed: false)
      hash[:inspection_billing] = DB.get(Sequel.function(:fn_party_role_name, hash[:inspection_billing_party_role_id]))
      hash[:exporter] = DB.get(Sequel.function(:fn_party_role_name, hash[:exporter_party_role_id]))
      inspector_party_role_id = get(:inspectors, hash[:inspector_id], :inspector_party_role_id)
      hash[:inspector] = DB.get(Sequel.function(:fn_party_role_name, inspector_party_role_id))
      hash[:status] = DB.get(Sequel.function(:fn_current_status, 'govt_inspection_sheets', id))
      pallet_ids = select_values(:govt_inspection_pallets, :pallet_id, govt_inspection_sheet_id: id)
      ecert_passed = select_values(:ecert_tracking_units, :passed, pallet_id: pallet_ids)
      hash[:allow_titan_inspection] = (pallet_ids.length == ecert_passed.length) & ecert_passed.all?
      GovtInspectionSheet.new(hash)
    end

    def pallet_in_different_tripsheet?(pallet_id, vehicle_job_id)
      query = <<~SQL
        SELECT u.id
        FROM  vehicle_job_units u
        JOIN vehicle_jobs j on j.id=u.vehicle_job_id
        WHERE u.stock_item_id = ? and u.vehicle_job_id <> ? and j.offloaded_at is null
      SQL
      !DB[query, pallet_id, vehicle_job_id].empty?
    end

    def clone_govt_inspection_sheet(id, user)
      attrs = where_hash(:govt_inspection_sheets, id: id) || {}
      attrs = attrs.slice(:inspector_id,
                          :inspection_billing_party_role_id,
                          :exporter_party_role_id,
                          :booking_reference,
                          :inspection_point,
                          :destination_region_id)
      attrs[:cancelled_id] = id
      clone_id = create_govt_inspection_sheet(attrs)
      log_status(:govt_inspection_sheets, clone_id, 'CREATED FROM CANCELLED', user_name: user.user_name)

      all_hash(:govt_inspection_pallets, govt_inspection_sheet_id: id).each do |govt_inspection_pallet|
        params = { pallet_id: govt_inspection_pallet[:pallet_id],  govt_inspection_sheet_id: clone_id }
        create_govt_inspection_pallet(params)
      end
    end

    def cancel_govt_inspection_sheet(id, user)
      clone_govt_inspection_sheet(id, user)

      attrs = { cancelled: true, cancelled_at: Time.now }
      update_govt_inspection_sheet(id, attrs)
      log_status(:govt_inspection_sheets, id, 'CANCELLED', user_name: user.user_name)

      govt_inspection_pallets = all_hash(:govt_inspection_pallets,  govt_inspection_sheet_id: id)
      govt_inspection_pallets.each do |govt_inspection_pallet|
        attrs = { inspected: false, govt_inspection_passed: false, last_govt_inspection_pallet_id: nil, in_stock: false, stock_created_at: nil }
        update(:pallets, govt_inspection_pallet[:pallet_id], attrs)
        log_status(:pallets, govt_inspection_pallet[:pallet_id], 'INSPECTION CANCELLED', user_name: user.user_name)
      end
    end

    def finish_govt_inspection_sheet(id, user) # rubocop:disable Metrics/AbcSize
      reinspection = get(:govt_inspection_sheets, id, :reinspection)
      status = reinspection ? 'MANUALLY REINSPECTED BY GOVT' : 'MANUALLY INSPECTED BY GOVT'

      attrs = { inspected: true, results_captured: true, results_captured_at: Time.now }
      update_govt_inspection_sheet(id, attrs)
      log_status(:govt_inspection_sheets, id, status, user_name: user.user_name)

      all_hash(:govt_inspection_pallets, govt_inspection_sheet_id: id).each do |govt_inspection_pallet|
        pallet_id = govt_inspection_pallet[:pallet_id]
        pallet = find_hash(:pallets, pallet_id)

        params = { inspected: true,
                   govt_inspection_passed: govt_inspection_pallet[:passed],
                   last_govt_inspection_pallet_id: govt_inspection_pallet[:id] }
        params[:govt_first_inspection_at] = Time.now if pallet[:govt_first_inspection_at].nil?
        params[:govt_reinspection_at] = Time.now if reinspection
        if govt_inspection_pallet[:passed] && !AppConst::CREATE_STOCK_AT_FIRST_INTAKE
          params[:in_stock] = true
          params[:stock_created_at] = Time.now
        end

        update(:pallets, pallet_id, params)
        log_status(:pallets, pallet_id, "INSPECTION_#{status}", user_name: user.user_name)
      end
    end

    def reopen_govt_inspection_sheet(id, user)
      attrs = { inspected: false, results_captured: false, results_captured_at: nil }
      update_govt_inspection_sheet(id, attrs)
      log_status(:govt_inspection_sheets, id, 'REOPENED', user_name: user.user_name)

      all_hash(:govt_inspection_pallets, govt_inspection_sheet_id: id).each do |govt_inspection_pallet|
        pallet_id = govt_inspection_pallet[:pallet_id]
        next unless govt_inspection_pallet[:id] == get(:pallets, pallet_id, :last_govt_inspection_pallet_id)

        params = { inspected: false,
                   govt_inspection_passed: nil,
                   last_govt_inspection_pallet_id: nil }

        unless AppConst::CREATE_STOCK_AT_FIRST_INTAKE
          params[:in_stock] = false
          params[:stock_created_at] = nil
        end

        update(:pallets, pallet_id, params)
        log_status(:pallets, pallet_id, 'INSPECTION REOPENED', user_name: user.user_name)
      end
    end

    def create_govt_inspection_sheet(res)
      id = create(:govt_inspection_sheets, res.to_h)
      consignment_note_number = "#{AppConst::CLIENT_CODE.upcase}#{id.to_s.rjust(10 - AppConst::CLIENT_CODE.length, '0')}"
      update(:govt_inspection_sheets, id, consignment_note_number: consignment_note_number)
      id
    end

    def get_last(table_name, column, args = {})
      DB[table_name].where(args).exclude(column => nil).reverse(:id).get(column)
    end

    def find_govt_inspection_pallet_flat(id)
      query = <<~SQL
        SELECT
          pallets.pallet_number,
          govt_inspection_pallets.id,
          govt_inspection_pallets.pallet_id,
          govt_inspection_pallets.govt_inspection_sheet_id,
          govt_inspection_sheets.completed,
          govt_inspection_pallets.passed,
          govt_inspection_pallets.inspected,
          govt_inspection_pallets.inspected_at,
          govt_inspection_pallets.failure_reason_id,
          inspection_failure_reasons.failure_reason,
          inspection_failure_reasons.description,
          inspection_failure_reasons.main_factor,
          inspection_failure_reasons.secondary_factor,
          govt_inspection_pallets.failure_remarks,
          govt_inspection_sheets.inspected AS sheet_inspected,
          pallets.nett_weight,
          pallets.gross_weight,
          pallets.carton_quantity,
          array_agg(distinct marketing_varieties.marketing_variety_code) AS marketing_varieties,
          array_agg(distinct target_market_groups.target_market_group_name) AS packed_tm_groups,
          pallet_bases.pallet_base_code AS pallet_base,
          govt_inspection_pallets.active,
          govt_inspection_pallets.created_at,
          govt_inspection_pallets.updated_at,
          CASE
            WHEN govt_inspection_pallets.inspected AND NOT govt_inspection_pallets.passed THEN 'error'
            WHEN govt_inspection_pallets.passed THEN 'ok'
          END AS colour_rule

        FROM govt_inspection_pallets
        JOIN govt_inspection_sheets ON govt_inspection_sheets.id = govt_inspection_pallets.govt_inspection_sheet_id
        LEFT JOIN inspection_failure_reasons ON inspection_failure_reasons.id = govt_inspection_pallets.failure_reason_id
        LEFT JOIN pallets ON pallets.id = govt_inspection_pallets.pallet_id
        LEFT JOIN pallet_sequences ps ON pallets.id = ps.pallet_id
        LEFT JOIN marketing_varieties ON marketing_varieties.id = ps.marketing_variety_id
        LEFT JOIN target_market_groups ON target_market_groups.id = ps.packed_tm_group_id
        LEFT JOIN pallet_formats ON pallet_formats.id = pallets.pallet_format_id
        LEFT JOIN pallet_bases ON pallet_bases.id = pallet_formats.pallet_base_id
        WHERE govt_inspection_pallets.id = ?

        GROUP BY
          govt_inspection_pallets.id,
          govt_inspection_sheets.id,
          pallets.id,
          inspection_failure_reasons.id,
          pallet_bases.id
      SQL
      hash = DB[query, id].first
      return nil if hash.nil?

      GovtInspectionPalletFlat.new(hash)
    end

    def find_pallet_flat(id)
      query = <<~SQL
        SELECT
          pallets.pallet_number,
          pallets.gross_weight,
          pallets.carton_quantity,
          array_agg(distinct marketing_varieties.marketing_variety_code) AS marketing_varieties,
          array_agg(distinct target_market_groups.target_market_group_name) AS packed_tm_groups,
          pallet_bases.pallet_base_code AS pallet_base

        FROM pallets
        LEFT JOIN pallet_sequences ps ON pallets.id = ps.pallet_id
        LEFT JOIN marketing_varieties ON marketing_varieties.id = ps.marketing_variety_id
        LEFT JOIN target_market_groups ON target_market_groups.id = ps.packed_tm_group_id
        LEFT JOIN pallet_formats ON pallet_formats.id = pallets.pallet_format_id
        LEFT JOIN pallet_bases ON pallet_bases.id = pallet_formats.pallet_base_id
        WHERE pallets.id = ?
        GROUP BY
          pallets.id,
          pallet_bases.id
      SQL
      hash = DB[query, id].first
      return nil if hash.nil?

      FinishedGoodsApp::PalletFlat.new(hash)
    end

    def update_govt_inspection_pallet(id, res)
      attrs = res.to_h
      attrs[:passed] = attrs[:failure_reason_id].nil?
      update(:govt_inspection_pallets, id, attrs)
    end

    def load_vehicle_job_units(vehicle_job_id)
      DB[:vehicle_job_units].where(vehicle_job_id: vehicle_job_id).update(loaded_at: Time.now)
    end

    def get_vehicle_job_units(vehicle_job_id)
      # DB[:vehicle_job_units].where(vehicle_job_id: vehicle_job_id)
      query = <<~SQL
        SELECT u.*, p.pallet_number
        FROM  vehicle_job_units u
        JOIN pallets p on p.id=u.stock_item_id
        WHERE u.vehicle_job_id = ?
      SQL
      DB[query, vehicle_job_id]
    end

    def get_vehicle_job_location(vehicle_job_id)
      query = <<~SQL
        SELECT l.location_long_code
        FROM  vehicle_jobs v
        JOIN locations l on l.id=v.planned_location_to_id
        WHERE v.id = ?
      SQL
      DB[query, vehicle_job_id].select_map(:location_long_code).first
    end

    def get_tripsheet_pallet_ids(vehicle_job_id)
      DB[:vehicle_job_units].where(vehicle_job_id: vehicle_job_id).select_map(:stock_item_id)
    end

    def offloaded_vehicle_pallets(govt_inspection_sheet_id)
      query = <<~SQL
        SELECT count(u.id) as num_offloaded_plts
        FROM vehicle_jobs v
        JOIN vehicle_job_units u on u.vehicle_job_id = v.id
        WHERE v.govt_inspection_sheet_id = ? and u.offloaded_at is not null
      SQL
      DB[query, govt_inspection_sheet_id].first[:num_offloaded_plts]
    end

    def find_vehicle_job_unit_by(key, val)
      hash = DB[:vehicle_job_units].where(Sequel[:vehicle_job_units][key] => val).first
      return nil if hash.nil?

      VehicleJobUnit.new(hash)
    end

    def delete_vehicle_job(vehicle_job_id)
      DB[:vehicle_job_units].where(vehicle_job_id: vehicle_job_id).delete
      DB[:vehicle_jobs].where(id: vehicle_job_id).delete
    end

    def refresh_tripsheet?(govt_inspection_sheet_id)
      vehicle_job_id = get_id(:vehicle_jobs, govt_inspection_sheet_id: govt_inspection_sheet_id)
      govt_inspection_pallets = all_hash(:govt_inspection_pallets,  govt_inspection_sheet_id: govt_inspection_sheet_id)
      tripsheet_pallets = get_vehicle_job_units(vehicle_job_id)

      tripsheet_pallets.map { |p| p[:stock_item_id] }.sort != govt_inspection_pallets.map { |p| p[:pallet_id] }.sort
    end

    def get_vehicle_jobs_pallets(vehicle_job_id)
      query = <<~SQL
        SELECT p.pallet_number
        FROM vehicle_jobs v
        JOIN vehicle_job_units u on u.vehicle_job_id = v.id
        JOIN pallets p on p.id = u.stock_item_id
        WHERE v.id = ?
      SQL
      DB[query, vehicle_job_id].map { |p| p[:pallet_number] }
    end

    def tripsheet_offload_complete?(vehicle_job_id)
      tripsheet_pallets = get_vehicle_job_units(vehicle_job_id)
      (tripsheet_pallets.all.find_all { |p| !p[:offloaded_at] }).empty?
    end

    def refresh_to_complete_offload?(govt_inspection_sheet_id)
      query = <<~SQL
        SELECT EXISTS(SELECT u.id
        FROM  vehicle_job_units u
        JOIN pallets p on p.id=u.stock_item_id
        JOIN govt_inspection_pallets g on g.pallet_id=p.id
        WHERE g.govt_inspection_sheet_id = ?
          AND u.offloaded_at IS NULL)
      SQL
      !DB[query, govt_inspection_sheet_id].single_value
    end

    def valid_carton_for_pallet?(pallet_number, carton_number)
      # exists?(:carton_labels, id: carton_number, pallet_number: pallet_number)
      !DB[:pallets]
        .join(:pallet_sequences, pallet_id: :id)
        .join(:cartons, pallet_sequence_id: :id)
        .join(:carton_labels, id: :carton_label_id)
        .where(Sequel[:pallets][:pallet_number] => pallet_number, Sequel[:carton_labels][:id] => carton_number)
        .empty?
    end

    def palletizing_bay_for_pallet(pallet_number)
      DB[:palletizing_bay_states]
        .join(:pallet_sequences, id: :pallet_sequence_id)
        .where(pallet_number: pallet_number)
        .get(:palletizing_robot_code)
    end

    def tripsheet_destination(vehicle_job_id)
      DB[:vehicle_jobs]
        .join(:locations, id: :planned_location_to_id)
        .where(Sequel[:vehicle_jobs][:id] => vehicle_job_id)
        .get(:location_long_code)
    end
  end
end
