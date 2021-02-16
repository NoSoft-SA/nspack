# frozen_string_literal: true

module FinishedGoodsApp
  class InspectionRepo < BaseRepo
    # INSPECTIONS
    # --------------------------------------------------------------------------
    build_for_select :inspections,
                     label: :remarks,
                     value: :id,
                     order_by: :remarks
    build_inactive_select :inspections,
                          label: :remarks,
                          value: :id,
                          order_by: :remarks
    crud_calls_for :inspections, name: :inspection, wrapper: Inspection, exclude: %i[create]

    def find_inspection(id)
      hash = find_with_association(:inspections, id,
                                   parent_tables: [{ parent_table: :inspection_types,
                                                     foreign_key: :inspection_type_id,
                                                     columns: [:inspection_type_code],
                                                     flatten_columns: { inspection_type_code: :inspection_type_code } },
                                                   { parent_table: :inspectors,
                                                     foreign_key: :inspector_id,
                                                     columns: [:inspector_party_role_id],
                                                     flatten_columns: { inspector_party_role_id: :inspector_party_role_id } }])
      return nil if hash.nil?

      hash[:inspector] = DB.get(Sequel.function(:fn_party_role_name, hash[:inspector_party_role_id]))
      hash[:inspected] = !hash[:inspector_id].nil?
      hash[:pallet_number] = get(:pallets, hash[:pallet_id], :pallet_number)
      hash[:failure_reasons] = select_values(:inspection_failure_reasons, :failure_reason, id: hash[:inspection_failure_reason_ids].to_a)

      Inspection.new(hash)
    end

    def find_pallet_for_inspection(pallet_number) # rubocop:disable Metrics/AbcSize
      pallet_id = get_id(:pallets, pallet_number: pallet_number)
      return nil unless pallet_id

      hash = { pallet_id: pallet_id, pallet_number: pallet_number }
      hash[:tm_group_ids] = select_values(:pallet_sequences, :packed_tm_group_id, pallet_id: hash[:pallet_id])
      hash[:grade_ids] = select_values(:pallet_sequences, :grade_id, pallet_id: hash[:pallet_id])
      hash[:inspection_type_ids] = []
      hash[:passed_default] = []

      select_values(:inspection_types, :id, active: true).each do |inspection_type_id|
        inspection_type = MasterfilesApp::QualityRepo.new.find_inspection_type(inspection_type_id)
        match_tm = (inspection_type.applicable_tm_group_ids & hash[:tm_group_ids]).any?
        match_grade = (inspection_type.applicable_grade_ids & hash[:grade_ids]).any?
        if match_tm & match_grade
          hash[:inspection_type_ids] << inspection_type_id
          hash[:passed_default] << inspection_type.passed_default
        end
      end
      PalletForInspection.new(hash)
    end

    def create_inspection(params)
      pallet = find_pallet_for_inspection(params[:pallet_number] || params)
      raise Crossbeams::InfoError, 'Pallet not found' unless pallet

      ids = []
      pallet.inspection_type_ids.each do |inspection_type_id|
        inspection_type = MasterfilesApp::QualityRepo.new.find_inspection_type(inspection_type_id)

        args = { pallet_id: pallet.pallet_id, inspection_type_id: inspection_type_id }
        next if exists?(:inspections, args)

        args[:passed] = inspection_type.passed_default
        ids << create(:inspections, args)
      end
      ids
    end
  end
end
