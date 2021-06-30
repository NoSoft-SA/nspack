# frozen_string_literal: true

module MesscadaApp
  class MesscadaRepo < BaseRepo # rubocop:disable Metrics/ClassLength
    crud_calls_for :carton_labels, name: :carton_label, wrapper: CartonLabel
    crud_calls_for :cartons, name: :carton, wrapper: CartonFlat
    crud_calls_for :pallets, name: :pallet, wrapper: Pallet
    crud_calls_for :pallet_sequences, name: :pallet_sequence, wrapper: PalletSequence

    def find_pallet_flat(id) # rubocop:disable Metrics/AbcSize
      hash = find_with_association(:pallets, id,
                                   lookup_functions: [{ function: :fn_current_status,
                                                        args: ['pallets', :id],
                                                        col_name: :status }])
      return nil if hash.nil?

      hash[:last_govt_inspection_sheet_id] = get(:govt_inspection_pallets, hash[:last_govt_inspection_pallet_id], :govt_inspection_sheet_id)
      hash[:oldest_pallet_sequence_id] = DB[:pallet_sequences].where(pallet_id: id).order(:created_at).get(:id)
      hash[:pallet_sequence_ids] = DB[:pallet_sequences].where(pallet_id: id).order(:created_at).select_map(:id)
      hash[:nett_weight] = hash[:nett_weight].to_f.round(2)
      hash[:gross_weight] = hash[:gross_weight].to_f.round(2)

      PalletFlat.new(hash)
    end

    def find_pallet_by_pallet_number(pallet_number)
      id = get_id(:pallets, pallet_number: pallet_number)
      find_pallet_flat(id)
    end

    def find_pallet_sequence_flat(id)
      hash = find_with_association(:pallet_sequences, id,
                                   parent_tables: [{ parent_table: :farms,
                                                     foreign_key: :farm_id,
                                                     flatten_columns: { farm_code: :farm_code,
                                                                        pdn_region_id: :production_region_id } },
                                                   { parent_table: :production_regions,
                                                     foreign_key: :production_region_id,
                                                     flatten_columns: { production_region_code: :production_region_code } },
                                                   { parent_table: :pucs,
                                                     foreign_key: :puc_id,
                                                     flatten_columns: { puc_code: :puc_code } },
                                                   { parent_table: :orchards,
                                                     foreign_key: :orchard_id,
                                                     flatten_columns: { orchard_code: :orchard_code } },
                                                   { parent_table: :cultivars,
                                                     foreign_key: :cultivar_id,
                                                     flatten_columns: { cultivar_code: :cultivar_code,
                                                                        cultivar_name: :cultivar_name,
                                                                        commodity_id: :commodity_id } },
                                                   { parent_table: :cultivar_groups,
                                                     foreign_key: :cultivar_group_id,
                                                     flatten_columns: { cultivar_group_code: :cultivar_group_code } },
                                                   { parent_table: :commodities,
                                                     foreign_key: :commodity_id,
                                                     flatten_columns: { code: :commodity_code,
                                                                        description: :commodity_description } },
                                                   { parent_table: :standard_pack_codes,
                                                     foreign_key: :standard_pack_code_id,
                                                     flatten_columns: { standard_pack_code: :standard_pack_code } },
                                                   { parent_table: :marketing_varieties,
                                                     foreign_key: :marketing_variety_id,
                                                     flatten_columns: { marketing_variety_code: :marketing_variety_code } },
                                                   { parent_table: :target_markets,
                                                     flatten_columns: { target_market_name: :target_market_name } },
                                                   { parent_table: :grades,
                                                     foreign_key: :grade_id,
                                                     flatten_columns: { grade_code: :grade_code } },
                                                   { parent_table: :rmt_classes,
                                                     foreign_key: :rmt_class_id,
                                                     flatten_columns: { rmt_class_code: :rmt_class_code } }],
                                   lookup_functions: [{ function: :fn_current_status,
                                                        args: ['pallet_sequences', :id],
                                                        col_name: :status },
                                                      { function: :fn_party_role_name,
                                                        args: [:target_customer_party_role_id],
                                                        col_name: :target_customer }])
      return nil if hash.nil?

      hash[:pallet_carton_quantity] = get(:pallets, hash[:pallet_id], :carton_quantity) || 0
      hash[:pallet_percentage] = hash[:pallet_carton_quantity].zero? ? 0 : (hash[:carton_quantity] / hash[:pallet_carton_quantity].to_f).round(3)
      hash[:nett_weight] = hash[:nett_weight].to_f.round(2)
      PalletSequenceFlat.new(hash)
    end

    def find_carton(id)
      hash = DB[<<~SQL, id].first
        SELECT cartons.id,
          cartons.carton_label_id,
          cartons.gross_weight,
          cartons.nett_weight,
          cartons.pallet_sequence_id,
          cartons.palletizer_contract_worker_id,
          cartons.palletizer_identifier_id,
          cartons.palletizing_bay_resource_id,
          cartons.scrapped,
          cartons.scrapped_at,
          cartons.scrapped_reason,
          cartons.scrapped_sequence_id,
          cartons.is_virtual,
          cartons.active,
          cl.production_run_id,
          cl.farm_id,
          cl.puc_id,
          cl.orchard_id,
          cl.cultivar_group_id,
          cl.cultivar_id,
          cl.product_resource_allocation_id,
          cl.packhouse_resource_id,
          cl.production_line_id,
          cl.season_id,
          cl.marketing_variety_id,
          cl.customer_variety_id,
          cl.std_fruit_size_count_id,
          cl.basic_pack_code_id,
          cl.standard_pack_code_id,
          cl.fruit_actual_counts_for_pack_id,
          cl.fruit_size_reference_id,
          cl.marketing_org_party_role_id,
          cl.packed_tm_group_id,
          cl.target_market_id,
          cl.mark_id,
          cl.pm_mark_id,
          cl.inventory_code_id,
          cl.pallet_format_id,
          cl.cartons_per_pallet_id,
          cl.pm_bom_id,
          cl.extended_columns,
          cl.client_size_reference,
          cl.client_product_code,
          cl.treatment_ids,
          cl.marketing_order_number,
          cl.fruit_sticker_pm_product_id,
          cl.pm_type_id,
          cl.pm_subtype_id,
          cl.sell_by_code,
          cl.grade_id,
          cl.product_chars,
          cl.pallet_label_name,
          cl.pick_ref,
          cl.pallet_number,
          cl.phc,
          cl.personnel_identifier_id,
          cl.contract_worker_id,
          cl.packing_method_id,
          cl.marketing_puc_id,
          cl.marketing_orchard_id,
          cl.group_incentive_id,
          cl.rmt_bin_id,
          cl.dp_carton,
          cl.gtin_code,
          cl.rmt_class_id,
          cl.packing_specification_item_id,
          cl.tu_labour_product_id,
          cl.ru_labour_product_id,
          cl.fruit_sticker_ids,
          cl.tu_sticker_ids,
          cl.target_customer_party_role_id

        FROM cartons
        JOIN carton_labels cl ON cl.id = cartons.carton_label_id
        WHERE cartons.id = ?
      SQL
      return nil if hash.nil?

      CartonFlat.new(hash)
    end

    def find_stock_item(stock_item_id, stock_type)
      return find_pallet(stock_item_id) if stock_type == AppConst::PALLET_STOCK_TYPE

      find(:rmt_bins, RawMaterialsApp::RmtBin, stock_item_id)
    end

    def update_stock_item(stock_item_id, upd, stock_type)
      return update_pallet(stock_item_id, upd) if stock_type == AppConst::PALLET_STOCK_TYPE

      DB[:rmt_bins].where(id: stock_item_id).update(upd)
    end

    def carton_label_exists?(carton_label_id)
      exists?(:carton_labels, id: carton_label_id)
    end

    def carton_label_carton_exists?(carton_label_id)
      exists?(:cartons, carton_label_id: carton_label_id)
    end

    def carton_exists?(carton_id)
      exists?(:cartons, id: carton_id)
    end

    def carton_pallet_sequence(carton_id)
      DB[:cartons].where(id: carton_id).get(:pallet_sequence_id)
    end

    def carton_label_carton_id(carton_label_id)
      DB[:cartons].where(carton_label_id: carton_label_id).get(:id)
    end

    def carton_carton_label(carton_id)
      DB[:cartons].where(id: carton_id).get(:carton_label_id)
    end

    def carton_label_id_for_pallet_no(pallet_no)
      DB[:carton_labels].where(pallet_number: pallet_no.to_s).get(:id)
    end

    def pallet_exists?(pallet_number)
      exists?(:pallets, pallet_number: pallet_number)
    end

    def pallet_id_for_pallet_number(pallet_number)
      DB[:pallets].where(pallet_number: pallet_number).get(:id)
    end

    def resource_code_exists?(resource_code)
      exists?(:system_resources, system_resource_code: resource_code)
    end

    def identifier_exists?(identifier)
      exists?(:personnel_identifiers, identifier: identifier)
    end

    def production_run_exists?(production_run_id)
      exists?(:production_runs, id: production_run_id)
    end

    def standard_pack_code_exists?(plant_resource_button_indicator)
      exists?(:standard_pack_codes, plant_resource_button_indicator: plant_resource_button_indicator)
    end

    def one_standard_pack_code?(plant_resource_button_indicator)
      DB[:standard_pack_codes].where(plant_resource_button_indicator: plant_resource_button_indicator).count == 1
    end

    def find_standard_pack(plant_resource_button_indicator)
      DB[:standard_pack_codes].where(plant_resource_button_indicator: plant_resource_button_indicator).get(:id)
    end

    def find_standard_pack_material_mass(id)
      DB[:standard_pack_codes].where(id: id).get(:material_mass)
    end

    def find_pallet_from_carton(carton_id)
      DB[:pallet_sequences].where(scanned_from_carton_id: carton_id).get(:pallet_id)
    end

    def find_resource_location_id(id)
      DB[:plant_resources].where(id: id).get(:location_id)
    end

    def find_allocation_target_customer_id(allocation_id)
      DB[:product_resource_allocations].where(id: allocation_id).get(:target_customer_party_role_id)
    end

    def find_resource_phc(id)
      DB[:plant_resources].where(id: id).get(Sequel.lit("resource_properties ->> 'phc'"))
    end

    def find_resource_packhouse_no(id)
      DB[:plant_resources].where(id: id).get(Sequel.lit("resource_properties ->> 'packhouse_no'"))
    end

    def find_resource_edi_out_value(id)
      DB[:plant_resources].where(id: id).get(Sequel.lit("resource_properties ->> 'edi_out_value'"))
    end

    def find_cartons_per_pallet(id)
      DB[:cartons_per_pallet].where(id: id).get(:cartons_per_pallet)
    end

    # Create several carton_labels records returning an array of the newly-created ids
    def create_carton_labels(no_of_prints, attrs)
      prep_attrs = prepare_values_for_db(:carton_labels, attrs.merge(carton_equals_pallet: AppConst::CR_PROD.carton_equals_pallet?))
      DB[:carton_labels].multi_insert(no_of_prints.to_i.times.map { prep_attrs }, return: :primary_key)
    end

    def carton_label_pallet_number(carton_label_id)
      DB[:carton_labels].where(id: carton_label_id).get(:pallet_number)
    end

    def create_pallet(user_name, pallet)
      id = DB[:pallets].insert(pallet)
      log_status('pallets', id, AppConst::PALLETIZED_NEW_PALLET, user_name: user_name)

      id
    end

    def create_serialized_stock_movement_log(serialized_stock_movement_log)
      DB[:serialized_stock_movement_logs].insert(serialized_stock_movement_log)
    end

    def find_business_process(process)
      DB[:business_processes].where(process: process).first
    end

    def find_stock_type(stock_type_code)
      DB[:stock_types].where(stock_type_code: stock_type_code).first
    end

    def create_sequences(pallet_sequence, pallet_id)
      pallet_sequence = pallet_sequence.merge(pallet_params(pallet_id))
      create(:pallet_sequences, pallet_sequence)
    end

    def find_orchard_by_variant_and_puc_and_farm(variant_code, puc_id, farm_id)
      DB[:masterfile_variants]
        .join(:orchards, id: :masterfile_id)
        .join(:pucs, id: Sequel[:orchards][:puc_id])
        .join(:farms, id: Sequel[:orchards][:farm_id])
        .where(variant_code: variant_code, puc_id: puc_id, farm_id: farm_id)
        .get(Sequel[:orchards][:id])
    end

    def find_external_bin_delivery(delivery_number)
      query = <<~SQL
        select *
        from rmt_deliveries
        where legacy_data  @> '{\"delivery_number\": \"#{delivery_number}\"}';
      SQL
      DB[query].select_map(:id).first
    end

    def fetch_delivery_from_external_system(delivery_number)
      url = "#{AppConst::RMT_INTEGRATION_SERVER_URI}/services/integration/get_delivery_info?delivery_number=#{delivery_number}"
      http = Crossbeams::HTTPCalls.new
      res = http.request_get(url)
      return failed_response(res.message) unless res.success

      instance = JSON.parse(res.instance.body)
      return failed_response(instance['error']) unless instance['error'].nil_or_empty?

      success_response('ok', instance)
    end

    def fetch_bin_from_external_system(bin_number)
      url = "#{AppConst::RMT_INTEGRATION_SERVER_URI}/services/integration/get_bin_info?bin_number=#{bin_number}"
      http = Crossbeams::HTTPCalls.new
      res = http.request_get(url)
      return failed_response(res.message) unless res.success

      instance = JSON.parse(res.instance.body)
      return failed_response(instance['error']) unless instance['error'].nil_or_empty?

      success_response('ok', instance)
    end

    def complete_external_bin_tipping(bin_number, run_id)
      url = "#{AppConst::RMT_INTEGRATION_SERVER_URI}/services/integration/integrate?type=bin_tipped&record_id=#{bin_number}&model=BinsTipped&nspack_run_id=#{run_id}"
      http = Crossbeams::HTTPCalls.new
      res = http.request_get(url)
      err = res.message unless res.success

      unless err
        packet = Nokogiri::XML(res.instance.body)
        err = packet.root.child.text if packet.root.child.name == 'error'
      end

      return unless err

      mail = <<~STR
        Bin:#{bin_number} could not be tipped successfully

        #{err}
      STR

      ErrorMailer.send_error_email(subject: 'LEGACY BIN TIP FAIL', message: mail, append_recipients: AppConst::LEGACY_SYSTEM_ERROR_RECIPIENTS)
    end

    def can_bin_be_tipped?(bin_number)
      url = "#{AppConst::RMT_INTEGRATION_SERVER_URI}/services/integration/can_bin_be_tipped?bin_number=#{bin_number}"
      http = Crossbeams::HTTPCalls.new
      res = http.request_get(url)
      return failed_response(res.message) unless res.success

      instance = JSON.parse(res.instance.body)
      return failed_response(instance['msg']) unless instance['can_tip_bin']

      success_response('ok')
    end

    def run_treatment_codes
      url = "#{AppConst::RMT_INTEGRATION_SERVER_URI}/services/integration/get_run_treatment_codes"
      http = Crossbeams::HTTPCalls.new
      res = http.request_get(url)
      raise res.message unless res.success

      JSON.parse(res.instance.body)
    end

    def ripe_point_codes(ripe_point_code: nil)
      params = ripe_point_code ? "ripe_point_code=#{ripe_point_code}" : nil
      url = "#{AppConst::RMT_INTEGRATION_SERVER_URI}/services/integration/get_run_ripe_point_codes?#{params}"
      http = Crossbeams::HTTPCalls.new
      res = http.request_get(url)
      raise res.message unless res.success

      JSON.parse(res.instance.body)
    end

    def track_indicator_codes(cultivar)
      url = "#{AppConst::RMT_INTEGRATION_SERVER_URI}/services/integration/get_run_track_indicator_codes?rmt_variety_code=#{cultivar}"
      http = Crossbeams::HTTPCalls.new
      res = http.request_get(url)
      raise res.message unless res.success

      JSON.parse(res.instance.body)
    end

    def pallet_params(pallet_id)
      {
        pallet_id: pallet_id,
        pallet_number: find_pallet_number(pallet_id)
      }
    end

    def find_pallet_number(id)
      DB[:pallets].where(id: id).get(:pallet_number)
    end

    def get_rmt_bin_setup_reqs(bin_id)
      DB[<<~SQL, bin_id].first
        SELECT b.id, b.farm_id, b.orchard_id, b.cultivar_id
        ,c.cultivar_name, c.cultivar_group_id, cg.cultivar_group_code,f.farm_code, o.orchard_code
        FROM rmt_bins b
        JOIN cultivars c ON c.id=b.cultivar_id
        JOIN cultivar_groups cg ON cg.id=c.cultivar_group_id
        JOIN farms f ON f.id=b.farm_id
        JOIN orchards o ON o.id=b.orchard_id
        WHERE b.id = ?
      SQL
    end

    def get_run_setup_reqs(run_id)
      ProductionApp::ProductionRunRepo.new.find_production_run_flat(run_id).to_h
      # DB["select r.id, r.farm_id, r.orchard_id, r.cultivar_group_id, r.cultivar_id, r.allow_cultivar_mixing, r.allow_orchard_mixing
      #   ,c.cultivar_name, cg.cultivar_group_code,f.farm_code, o.orchard_code, p.puc_code
      #   from production_runs r
      #   left join cultivars c on c.id=r.cultivar_id
      #   join cultivar_groups cg on cg.id=r.cultivar_group_id
      #   join farms f on f.id=r.farm_id
      #   join orchards o on o.id=r.orchard_id
      #   join pucs p on p.id=r.puc_id
      #   WHERE r.id = ?", run_id].first
    end

    def get_pallet_sequence_id_from_carton_label(carton_label_id)
      pallet_sequence_id = carton_label_carton_palletizing_sequence(carton_label_id)
      pallet_sequence_id = carton_label_scanned_from_carton_sequence(carton_label_id) if pallet_sequence_id.nil?
      pallet_sequence_id
    end

    def find_pallet_by_carton_number(carton_label_id)
      pallet_sequence_id = get_pallet_sequence_id_from_carton_label(carton_label_id)
      pallet_id = get(:pallet_sequences, pallet_sequence_id, :pallet_id)
      find_pallet_flat(pallet_id)
    end

    def production_run_stats(run_id)
      DB[:production_run_stats].where(production_run_id: run_id).map { |p| p[:bins_tipped] }.first
    end

    def get_oldest_pallet_sequence(pallet_id)
      query = <<~SQL
        SELECT i.inventory_code, tm.target_market_group_name, target_markets.target_market_name, g.grade_code, m.mark_code,fs.size_reference, sp.standard_pack_code, sf.size_count_value
        ,c.cultivar_name, cg.cultivar_group_code, p.puc_code, o,orchard_code, s.*
        FROM pallet_sequences s
        JOIN inventory_codes i ON i.id = s.inventory_code_id
        JOIN target_market_groups tm on tm.id=s.packed_tm_group_id
        LEFT JOIN target_markets on target_markets.id=s.target_market_id
        LEFT JOIN fruit_size_references fs on fs.id=s.fruit_size_reference_id
        JOIN standard_pack_codes sp on sp.id=s.standard_pack_code_id
        LEFT JOIN std_fruit_size_counts sf on sf.id=s.std_fruit_size_count_id
        JOIN grades g on g.id=s.grade_id
        JOIN marks m on m.id=s.mark_id
        JOIN cultivars c on c.id=s.cultivar_id
        JOIN cultivar_groups cg on cg.id=s.cultivar_group_id
        JOIN pucs p on p.id=s.puc_id
        JOIN orchards o on o.id=s.orchard_id
        WHERE s.pallet_id = ?
        ORDER BY s.pallet_sequence_number ASC
      SQL
      DB[query, pallet_id].first
    end

    def find_pallet_sequences_by_pallet_number(pallet_number)
      filters = ['WHERE pallet_sequences.pallet_number = ?']
      filters << 'ORDER BY pallet_sequences.pallet_sequence_number'
      query = MesscadaApp::DatasetPalletSequence.call(filters)
      DB[query, pallet_number]
    end

    def find_pallet_sequences_from_same_pallet(id)
      DB["select sis.id
          from pallet_sequences s
          join pallet_sequences sis on sis.pallet_id=s.pallet_id
          where s.id = #{id}
          order by sis.pallet_sequence_number asc"].map { |s| s[:id] }
    end

    def find_pallet_sequence_attrs(id)
      query = MesscadaApp::DatasetPalletSequence.call('WHERE pallet_sequences.id = ?')
      DB[query, id].first
    end

    def find_pallet_sequences_by_pallet(id)
      query = MesscadaApp::DatasetPalletSequence.call('WHERE pallet_sequences.pallet_id = ?')
      DB[query, id].all
    end

    def update_pallet_sequence_verification_result(pallet_sequence_id, params)
      nett_weight_upd = ", nett_weight=#{params[:nett_weight]} " if params[:nett_weight]
      upd = "UPDATE pallet_sequences SET verified=true,verified_at='#{Time.now}',verified_by='#{params[:verified_by]}',verification_result = '#{params[:verification_result]}', verification_passed=#{params[:verification_result] != 'failed'}, pallet_verification_failure_reason_id = #{(params[:verification_result] != 'failed' ? 'Null' : "'#{params[:verification_failure_reason]}'")} #{nett_weight_upd} WHERE id = #{pallet_sequence_id};"
      DB[upd].update
    end

    def pallet_verified?(pallet_id)
      !exists?(:pallet_sequences, pallet_id: pallet_id, verified: false)
    end

    # instance of a carton label with all its relevant lookup columns
    def carton_label_printing_instance(id)
      DB[:vw_carton_label_lbl].where(carton_label_id: id).first
    end

    # instance of an allocated product setup with all its relevant lookup columns
    def allocated_product_setup_label_printing_instance(id)
      DB[:vw_carton_label_pset].where(product_resource_allocation_id: id).first
    end

    def get_run_bins_tipped(run_id)
      query = <<~SQL
        SELECT COALESCE(SUM(COALESCE(qty_bins, 0)), 0) as bins_tipped
        FROM rmt_bins
        WHERE rmt_bins.production_run_tipped_id = ?
        AND NOT scrapped
      SQL
      DB[query, run_id].first[:bins_tipped]
    end

    def find_rebin_pallet_sequences(pallet_number)
      query = <<~SQL
        SELECT s.*, p.gross_weight
        FROM pallet_sequences s
        JOIN pallets p on p.id=s.pallet_id
        WHERE s.pallet_number = ?
      SQL
      DB[query, pallet_number].all
    end

    def display_lines_for(device)
      server_ip = URI.parse(AppConst::LABEL_SERVER_URI).host
      mtype = DB[:mes_modules]
              .where(module_code: device, server_ip: server_ip)
              .get(:module_type)
      mtype == 'robot-T200' ? 4 : 6
    end

    def carton_attributes(carton_id)
      query = <<~SQL
        SELECT i.inventory_code, tm.target_market_group_name, target_markets.target_market_name, g.grade_code, m.mark_code,fs.size_reference,
               sp.standard_pack_code, sf.size_count_value ,clt.cultivar_name, cg.cultivar_group_code, c.*
        FROM cartons c
        JOIN carton_labels cl on cl.id = c.carton_label_id
        JOIN inventory_codes i ON i.id = cl.inventory_code_id
        JOIN target_market_groups tm on tm.id = cl.packed_tm_group_id
        LEFT JOIN target_markets on target_markets.id=cl.target_market_id
        LEFT JOIN fruit_size_references fs on fs.id = cl.fruit_size_reference_id
        JOIN standard_pack_codes sp on sp.id = cl.standard_pack_code_id
        LEFT JOIN std_fruit_size_counts sf on sf.id = cl.std_fruit_size_count_id
        JOIN grades g on g.id = cl.grade_id
        JOIN marks m on m.id = cl.mark_id
        JOIN cultivars clt on clt.id = cl.cultivar_id
        JOIN cultivar_groups cg on cg.id = cl.cultivar_group_id
        WHERE c.id = ?
      SQL
      DB[query, carton_id].first
    end

    def new_sequence?(carton_id, pallet_id)
      matching_sequences = matching_sequence_for_carton(carton_id, pallet_id)
      matching_sequences.nil? ? true : false
    end

    def matching_sequence_for_carton(carton_id, pallet_id) # rubocop:disable Metrics/AbcSize
      carton_rejected_fields = %i[id carton_label_id pallet_number product_resource_allocation_id fruit_sticker_pm_product_id
                                  gross_weight nett_weight sell_by_code pallet_label_name pick_ref phc packing_method_id palletizer_contract_worker_id
                                  palletizer_identifier_id pallet_sequence_id created_at updated_at personnel_identifier_id contract_worker_id
                                  palletizing_bay_resource_id is_virtual scrapped scrapped_reason scrapped_at scrapped_sequence_id
                                  group_incentive_id rmt_bin_id dp_carton gtin_code]
      attrs = find_carton(carton_id).to_h.reject { |k, _| carton_rejected_fields.include?(k) }
      attrs[:treatment_ids] = array_for_db_col(attrs[:treatment_ids]) if attrs.key?(:treatment_ids)
      attrs[:fruit_sticker_ids] = array_for_db_col(attrs[:fruit_sticker_ids]) if attrs.key?(:fruit_sticker_ids)
      attrs[:tu_sticker_ids] = array_for_db_col(attrs[:tu_sticker_ids]) if attrs.key?(:tu_sticker_ids)

      DB[:pallet_sequences].where(pallet_id: pallet_id).where(attrs).get(:id)
    end

    def sequence_has_cartons?(id)
      !DB[:cartons].where(pallet_sequence_id: id).count.zero?
    end

    # Return status of GLN numbers as specified in AppConst.
    def gln_status
      AppConst::GLN_OR_LINE_NUMBERS.map do |gln|
        no = if exists?(:pg_class, relname: "gln_seq_for_#{gln}")
               DB["SELECT last_value FROM gln_seq_for_#{gln}"].get(:last_value)
             else
               0
             end
        max = ('9' * (17 - gln.length)).to_i
        # If max - no <= 0 then GLN has run its course...
        remain = (max - no) < 1 ? 0 : max - no

        per_year = AppConst::EST_PALLETS_PACKED_PER_YEAR
        season_left = if remain.zero?
                        0
                      else
                        remain / per_year.to_f
                      end
        {
          gln: gln,
          used_numbers: no,
          remaining_numbers: remain,
          est_per_year: per_year,
          est_season: season_left
        }
      end
    end

    def find_marketing_puc(marketing_org_party_role_id, farm_id)
      DB[:farm_puc_orgs]
        .where(organization_id: DB[:party_roles]
                                  .where(id: marketing_org_party_role_id)
                                  .get(:organization_id))
        .where(farm_id: farm_id)
        .get(:puc_id)
    end

    def find_marketing_orchard(puc_id, cultivar_id)
      DB[:registered_orchards]
        .where(puc_code: find_puc_code(puc_id))
        .where(cultivar_code: find_cultivar_code(cultivar_id))
        .where(marketing_orchard: true)
        .get(:id)
    end

    def find_puc_code(puc_id)
      DB[:pucs]
        .where(id: puc_id)
        .get(:puc_code)
    end

    def find_cultivar_code(cultivar_id)
      DB[:cultivars]
        .where(id: cultivar_id)
        .get(:cultivar_code)
    end

    def parse_pallet_or_carton_number(res = {})
      # TODO - replace method with ScanCartonLabelOrPallet service
        params = res.to_h
        if params[:pallet_number]
          params[:pallet_number] = MesscadaApp::ScannedPalletNumber.new(scanned_pallet_number: params[:pallet_number]).pallet_number
          return params
        end
        raise Crossbeams::InfoError, 'scanned number not given' if params[:scanned_number].nil_or_empty?

        if params[:scanned_number].length > 8
          params[:pallet_number] = MesscadaApp::ScannedPalletNumber.new(scanned_pallet_number: params[:scanned_number]).pallet_number
        else
          params[:carton_number] = MesscadaApp::ScannedCartonNumber.new(scanned_carton_number: params[:scanned_number]).carton_number
        end
        params
    end

    def find_rmt_bin_by_tipped_asset_number(bin_number)
      get_id(:rmt_bins, tipped_asset_number: bin_number)
    end

    def rmt_bin_exists?(rmt_bin_id)
      exists?(:rmt_bins, id: rmt_bin_id)
    end

    def find_rmt_bin_farm(rmt_bin_id)
      DB[:rmt_bins]
        .where(id: rmt_bin_id)
        .get(:farm_id)
    end

    def find_rmt_bin_farm_attrs(rmt_bin_id)
      DB[:rmt_bins]
        .where(id: rmt_bin_id)
        .select(:farm_id, :puc_id, :orchard_id)
        .first
    end

    def active_run?(production_run_id)
      DB[:production_runs]
        .where(id: production_run_id)
        .get(:running)
    end

    def run_start_date(production_run_id)
      time = get(:production_runs, production_run_id, :started_at)
      time.nil? ? nil : time.to_date
    end

    def carton_label_carton_equals_pallet(carton_label_id)
      DB[:carton_labels].where(id: carton_label_id).get(:carton_equals_pallet)
    end

    def carton_label_carton_palletizing_sequence(carton_label_id)
      get_value(:cartons, :pallet_sequence_id, carton_label_id: carton_label_id)
    end

    def carton_label_scanned_from_carton_sequence(carton_label_id)
      DB[:pallet_sequences]
        .join(:cartons, id: :scanned_from_carton_id)
        .where(carton_label_id: carton_label_id)
        .get(Sequel[:pallet_sequences][:id])
    end

    def pallet_number_carton_exists?(pallet_number)
      pallet_sequence_ids = DB[:pallet_sequences].where(pallet_number: pallet_number).select_map(:id)
      return false if pallet_sequence_ids.nil_or_empty?

      return true if exists?(:cartons, pallet_sequence_id: pallet_sequence_ids)

      scanned_cartons = get(:pallet_sequences, pallet_sequence_ids, :scanned_from_carton_id)
      !scanned_cartons.nil_or_empty?
    end

    def can_pallet_become_rebin?(pallet_number)
      !DB[:cartons]
        .select(:carton_label_id)
        .join(:carton_labels, id: :carton_label_id)
        .join(:standard_pack_codes, id: :standard_pack_code_id)
        .join(:grades, id: Sequel[:carton_labels][:grade_id])
        .join(:pallet_sequences, id: Sequel[:cartons][:pallet_sequence_id])
        .where(Sequel[:pallet_sequences][:pallet_number] => pallet_number)
        .where(bin: true)
        .where(rmt_grade: true)
        .empty?
    end
  end
end
