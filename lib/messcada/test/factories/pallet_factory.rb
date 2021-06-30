# frozen_string_literal: true

module MesscadaApp
  module PalletFactory # rubocop:disable Metrics/ModuleLength
    def create_pallet(opts = {}) # rubocop:disable Metrics/AbcSize
      id = get_available_factory_record(:pallets, opts)
      return id unless id.nil?

      opts[:pallet_number] ||= Faker::Number.number(digits: 9)
      opts[:pallet_format_id] ||= create_pallet_format
      opts[:plt_packhouse_resource_id] ||= create_plant_resource
      opts[:plt_line_resource_id] ||= create_plant_resource
      opts[:fruit_sticker_pm_product_2_id] ||= create_pm_product
      opts[:palletizing_bay_resource_id] ||= create_plant_resource
      opts[:fruit_sticker_pm_product_id] ||= create_pm_product
      # opts[:load_id] ||= create_load
      opts[:location_id] ||= create_location

      default = {
        exit_ref: Faker::Lorem.word,
        scrapped_at: '2010-01-01 12:00',
        shipped: false,
        in_stock: false,
        inspected: false,
        shipped_at: '2010-01-01 12:00',
        govt_first_inspection_at: '2010-01-01 12:00',
        govt_reinspection_at: '2010-01-01 12:00',
        stock_created_at: '2010-01-01 12:00',
        phc: Faker::Lorem.word,
        intake_created_at: '2010-01-01 12:00',
        first_cold_storage_at: '2010-01-01 12:00',
        build_status: Faker::Lorem.word,
        gross_weight: Faker::Number.decimal,
        gross_weight_measured_at: '2010-01-01 12:00',
        palletized: false,
        partially_palletized: false,
        palletized_at: '2010-01-01 12:00',
        partially_palletized_at: '2010-01-01 12:00',
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        allocated: false,
        allocated_at: '2010-01-01 12:00',
        reinspected: false,
        scrapped: false,
        carton_quantity: Faker::Number.number(digits: 4),
        govt_inspection_passed: false,
        nett_weight: Faker::Number.decimal,
        last_govt_inspection_pallet_id: nil,
        temp_tail: Faker::Lorem.word,
        depot_pallet: false,
        edi_in_transaction_id: nil,
        edi_in_consignment_note_number: Faker::Lorem.word,
        re_calculate_nett: false,
        edi_in_inspection_point: Faker::Lorem.word,
        repacked: false,
        repacked_at: '2010-01-01 12:00',
        has_individual_cartons: false,
        nett_weight_externally_calculated: false,
        legacy_data: BaseRepo.new.hash_for_jsonb_col({}),
        verified: false,
        verified_at: '2010-01-01 12:00',
        derived_weight: false
      }
      DB[:pallets].insert(default.merge(opts))
    end

    def create_pallet_sequence(opts = {}) # rubocop:disable Metrics/AbcSize
      id = get_available_factory_record(:pallet_sequences, opts)
      return id unless id.nil?

      opts[:pallet_id] ||= create_pallet
      opts[:pallet_number] ||= DB[:pallets].where(id: opts[:pallet_id]).get(:pallet_number)
      opts[:pallet_sequence_number] ||= (DB[:pallet_sequences].where(pallet_id: opts[:pallet_id]).max(:pallet_sequence_number) || 0) + 1
      opts[:production_run_id] ||= create_production_run
      opts[:farm_id] ||= create_farm
      opts[:puc_id] ||= create_puc
      opts[:orchard_id] ||= create_orchard
      opts[:cultivar_group_id] ||= create_cultivar_group
      opts[:cultivar_id] ||= create_cultivar
      opts[:product_resource_allocation_id] ||= create_product_resource_allocation
      opts[:packhouse_resource_id] ||= create_plant_resource
      opts[:production_line_id] ||= create_plant_resource
      opts[:season_id] ||= create_season
      opts[:marketing_variety_id] ||= create_marketing_variety
      opts[:customer_variety_id] ||= create_customer_variety
      opts[:std_fruit_size_count_id] ||= create_std_fruit_size_count
      opts[:basic_pack_code_id] ||= create_basic_pack
      opts[:standard_pack_code_id] ||= create_standard_pack
      opts[:fruit_actual_counts_for_pack_id] ||= create_fruit_actual_counts_for_pack
      opts[:fruit_size_reference_id] ||= create_fruit_size_reference
      opts[:marketing_org_party_role_id] ||= create_party_role
      opts[:packed_tm_group_id] ||= create_target_market_group
      opts[:mark_id] ||= create_mark
      opts[:inventory_code_id] ||= create_inventory_code
      opts[:pallet_format_id] ||= create_pallet_format
      opts[:cartons_per_pallet_id] ||= create_cartons_per_pallet
      opts[:pm_bom_id] ||= create_pm_bom
      opts[:pm_type_id] ||= create_pm_type
      opts[:pm_subtype_id] ||= create_pm_subtype
      opts[:pallet_verification_failure_reason_id] ||= nil
      opts[:grade_id] ||= create_grade
      opts[:personnel_identifier_id] ||= create_personnel_identifier
      opts[:contract_worker_id] ||= create_contract_worker
      opts[:target_market_id] ||= create_target_market
      opts[:pm_mark_id] ||= create_pm_mark
      opts[:marketing_puc_id] ||= create_puc
      opts[:marketing_orchard_id] ||= create_registered_orchard
      opts[:target_customer_party_role_id] ||= create_party_role(name: AppConst::ROLE_TARGET_CUSTOMER)
      opts[:source_bin_id] ||= create_rmt_bin

      default = {
        extended_columns: BaseRepo.new.hash_for_jsonb_col({}),
        client_size_reference: Faker::Lorem.word,
        client_product_code: Faker::Lorem.word,
        treatment_ids: BaseRepo.new.array_for_db_col([1, 2, 3]),
        marketing_order_number: Faker::Lorem.word,
        carton_quantity: Faker::Number.number(digits: 4),
        scanned_from_carton_id: nil,
        exit_ref: Faker::Lorem.word,
        scrapped_at: '2010-01-01 12:00',
        verification_result: Faker::Lorem.word,
        verified_at: '2010-01-01 12:00',
        nett_weight: Faker::Number.decimal,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        verified: false,
        verification_passed: false,
        pick_ref: Faker::Lorem.word,
        scrapped_from_pallet_id: nil,
        removed_from_pallet: false,
        removed_from_pallet_id: nil,
        removed_from_pallet_at: '2010-01-01 12:00',
        sell_by_code: Faker::Lorem.word,
        product_chars: Faker::Lorem.word,
        depot_pallet: false,
        failed_otmc_results: BaseRepo.new.array_for_db_col([1, 2, 3]),
        phyto_data: Faker::Lorem.word,
        repacked_at: '2010-01-01 12:00',
        repacked_from_pallet_id: nil,
        created_by: Faker::Lorem.word,
        verified_by: Faker::Lorem.word,
        gtin_code: Faker::Lorem.word,
        legacy_data: BaseRepo.new.hash_for_jsonb_col({}),
        rmt_class_id: nil,
        packing_specification_item_id: nil,
        tu_labour_product_id: nil,
        ru_labour_product_id: nil,
        fruit_sticker_ids: BaseRepo.new.array_for_db_col([1, 2, 3]),
        tu_sticker_ids: BaseRepo.new.array_for_db_col([1, 2, 3]),
        work_order_item_id: nil
      }
      DB[:pallet_sequences].insert(default.merge(opts))
    end
  end
end
