# frozen_string_literal: true

module MesscadaApp
  module CartonFactory
    def create_carton(opts = {})
      id = get_available_factory_record(:cartons, opts)
      return id unless id.nil?

      opts[:carton_label_id] ||= create_carton_label
      opts[:palletizer_identifier_id] ||= create_personnel_identifier
      opts[:pallet_sequence_id] ||= create_pallet_sequence
      opts[:palletizing_bay_resource_id] ||= create_plant_resource
      opts[:palletizer_contract_worker_id] ||= create_contract_worker

      default = {
        gross_weight: Faker::Number.decimal,
        nett_weight: Faker::Number.decimal,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        is_virtual: false,
        scrapped: false,
        scrapped_reason: Faker::Lorem.unique.word,
        scrapped_at: '2010-01-01 12:00',
        scrapped_sequence_id: nil
      }
      DB[:cartons].insert(default.merge(opts))
    end

    def create_carton_label(opts = {})
      id = get_available_factory_record(:carton_labels, opts)
      return id unless id.nil?

      opts[:production_run_id] ||= create_production_run
      opts[:farm_id] ||= create_farm
      opts[:puc_id] ||= create_puc
      opts[:orchard_id] ||= create_orchard
      opts[:cultivar_group_id] ||= create_cultivar_group
      opts[:cultivar_id] ||= create_cultivar
      opts[:product_resource_allocation_id] ||= create_product_resource_allocation
      opts[:season_id] ||= create_season
      opts[:marketing_variety_id] ||= create_marketing_variety
      opts[:customer_variety_id] ||= create_customer_variety
      opts[:std_fruit_size_count_id] ||= create_std_fruit_size_count
      opts[:basic_pack_code_id] ||= create_basic_pack
      opts[:standard_pack_code_id] ||= create_standard_pack
      opts[:fruit_actual_counts_for_pack_id] ||= create_fruit_actual_counts_for_pack
      opts[:fruit_size_reference_id] ||= create_fruit_size_reference
      opts[:marketing_org_party_role_id] ||= create_party_role(name: AppConst::ROLE_MARKETER)
      opts[:packed_tm_group_id] ||= create_target_market_group
      opts[:mark_id] ||= create_mark
      opts[:inventory_code_id] ||= create_inventory_code
      opts[:pallet_format_id] ||= create_pallet_format
      opts[:cartons_per_pallet_id] ||= create_cartons_per_pallet
      opts[:pm_bom_id] ||= create_pm_bom
      opts[:packhouse_resource_id] ||= create_plant_resource
      opts[:production_line_id] ||= create_plant_resource
      opts[:fruit_sticker_pm_product_id] ||= create_pm_product
      opts[:pm_type_id] ||= create_pm_type
      opts[:pm_subtype_id] ||= create_pm_subtype
      opts[:resource_id] ||= create_plant_resource
      opts[:grade_id] ||= create_grade
      opts[:personnel_identifier_id] ||= create_personnel_identifier
      opts[:contract_worker_id] ||= create_contract_worker
      opts[:packing_method_id] ||= create_packing_method
      opts[:group_incentive_id] ||= create_group_incentive
      opts[:target_market_id] ||= create_target_market
      opts[:pm_mark_id] ||= create_pm_mark
      opts[:marketing_puc_id] ||= create_puc
      opts[:marketing_orchard_id] ||= create_registered_orchard
      opts[:rmt_class_id] ||= create_rmt_class
      opts[:target_customer_party_role_id] ||= create_party_role(name: AppConst::ROLE_TARGET_CUSTOMER)

      default = {
        extended_columns: BaseRepo.new.hash_for_jsonb_col({}),
        client_size_reference: Faker::Lorem.unique.word,
        client_product_code: Faker::Lorem.word,
        treatment_ids: BaseRepo.new.array_for_db_col([]),
        marketing_order_number: Faker::Lorem.word,
        label_name: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        sell_by_code: Faker::Lorem.word,
        product_chars: Faker::Lorem.word,
        pallet_label_name: Faker::Lorem.word,
        pick_ref: Faker::Lorem.word,
        carton_equals_pallet: false,
        pallet_number: nil,
        phc: Faker::Lorem.word,
        rmt_bin_id: nil,
        dp_carton: false,
        gtin_code: Faker::Lorem.word,
        packing_specification_item_id: nil,
        tu_labour_product_id: nil,
        ru_labour_product_id: nil,
        fruit_sticker_ids: BaseRepo.new.array_for_db_col([]),
        tu_sticker_ids: BaseRepo.new.array_for_db_col([]),
        work_order_item_id: nil
      }
      DB[:carton_labels].insert(default.merge(opts))
    end
  end
end
