# frozen_string_literal: true

module MesscadaApp
  module CartonFactory
    def create_carton(opts = {})
      # id = get_available_factory_record(:cartons, opts)
      # return id unless id.nil?

      default = {
        carton_label_id: create_carton_label,
        gross_weight: Faker::Number.decimal,
        nett_weight: Faker::Number.decimal,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        palletizer_identifier_id: create_personnel_identifier,
        pallet_sequence_id: create_pallet_sequence,
        palletizing_bay_resource_id: create_plant_resource,
        is_virtual: false,
        scrapped: false,
        scrapped_reason: Faker::Lorem.unique.word,
        scrapped_at: '2010-01-01 12:00',
        scrapped_sequence_id: Faker::Number.number(digits: 4),
        palletizer_contract_worker_id: create_contract_worker
      }
      DB[:cartons].insert(default.merge(opts))
    end

    def create_carton_label(opts = {}) # rubocop:disable Metrics/AbcSize
      # id = get_available_factory_record(:carton_labels, opts)
      # return id unless id.nil?

      default = {
        production_run_id: create_production_run,
        farm_id: create_farm,
        puc_id: create_puc,
        orchard_id: create_orchard,
        cultivar_group_id: create_cultivar_group,
        cultivar_id: create_cultivar,
        product_resource_allocation_id: create_product_resource_allocation,
        packhouse_resource_id: create_plant_resource,
        production_line_id: create_plant_resource,
        season_id: create_season,
        marketing_variety_id: create_marketing_variety,
        customer_variety_id: create_customer_variety,
        std_fruit_size_count_id: create_std_fruit_size_count,
        basic_pack_code_id: create_basic_pack,
        standard_pack_code_id: create_standard_pack,
        fruit_actual_counts_for_pack_id: create_fruit_actual_counts_for_pack,
        fruit_size_reference_id: create_fruit_size_reference,
        marketing_org_party_role_id: create_party_role(name: AppConst::ROLE_MARKETER),
        packed_tm_group_id: create_target_market_group,
        mark_id: create_mark,
        inventory_code_id: create_inventory_code,
        pallet_format_id: create_pallet_format,
        cartons_per_pallet_id: create_cartons_per_pallet,
        pm_bom_id: create_pm_bom,
        extended_columns: BaseRepo.new.hash_for_jsonb_col({}),
        client_size_reference: Faker::Lorem.unique.word,
        client_product_code: Faker::Lorem.word,
        treatment_ids: BaseRepo.new.array_for_db_col([1, 2, 3]),
        marketing_order_number: Faker::Lorem.word,
        fruit_sticker_pm_product_id: create_pm_product,
        pm_type_id: create_pm_type,
        pm_subtype_id: create_pm_subtype,
        resource_id: create_plant_resource,
        label_name: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        sell_by_code: Faker::Lorem.word,
        grade_id: create_grade,
        product_chars: Faker::Lorem.word,
        pallet_label_name: Faker::Lorem.word,
        pick_ref: Faker::Lorem.word,
        carton_equals_pallet: false,
        pallet_number: Faker::Lorem.word,
        phc: Faker::Lorem.word,
        personnel_identifier_id: create_personnel_identifier,
        contract_worker_id: create_contract_worker,
        packing_method_id: create_packing_method,
        group_incentive_id: create_group_incentive,
        target_market_id: create_target_market,
        pm_mark_id: create_pm_mark,
        marketing_puc_id: create_puc,
        marketing_orchard_id: create_registered_orchard,
        rmt_bin_id: nil,
        dp_carton: false,
        gtin_code: Faker::Lorem.word,
        rmt_class_id: create_rmt_class,
        packing_specification_item_id: nil,
        tu_labour_product_id: nil,
        ru_labour_product_id: nil,
        fruit_sticker_ids: BaseRepo.new.array_for_db_col([1, 2, 3]),
        tu_sticker_ids: BaseRepo.new.array_for_db_col([1, 2, 3]),
        target_customer_party_role_id: create_party_role(name: AppConst::ROLE_TARGET_CUSTOMER),
        work_order_item_id: nil
      }
      DB[:carton_labels].insert(default.merge(opts))
    end
  end
end
