# frozen_string_literal: true

module MesscadaApp
  class PalletSequence < Dry::Struct
    attribute :id, Types::Integer
    attribute :pallet_id, Types::Integer
    attribute :pallet_number, Types::String
    attribute :pallet_sequence_number, Types::Integer
    attribute :production_run_id, Types::Integer
    attribute :farm_id, Types::Integer
    attribute :puc_id, Types::Integer
    attribute :orchard_id, Types::Integer
    attribute :cultivar_group_id, Types::Integer
    attribute :cultivar_id, Types::Integer
    attribute :product_resource_allocation_id, Types::Integer
    attribute :packhouse_resource_id, Types::Integer
    attribute :production_line_id, Types::Integer
    attribute :season_id, Types::Integer
    attribute :marketing_variety_id, Types::Integer
    attribute :customer_variety_id, Types::Integer
    attribute :std_fruit_size_count_id, Types::Integer
    attribute :basic_pack_code_id, Types::Integer
    attribute :standard_pack_code_id, Types::Integer
    attribute :fruit_actual_counts_for_pack_id, Types::Integer
    attribute :fruit_size_reference_id, Types::Integer
    attribute :marketing_org_party_role_id, Types::Integer
    attribute :packed_tm_group_id, Types::Integer
    attribute :mark_id, Types::Integer
    attribute :inventory_code_id, Types::Integer
    attribute :pallet_format_id, Types::Integer
    attribute :cartons_per_pallet_id, Types::Integer
    attribute :pm_bom_id, Types::Integer
    attribute :extended_columns, Types::Hash
    attribute :client_size_reference, Types::String
    attribute :client_product_code, Types::String
    attribute :treatment_ids, Types::Array
    attribute :marketing_order_number, Types::String
    attribute :pm_type_id, Types::Integer
    attribute :pm_subtype_id, Types::Integer
    attribute :carton_quantity, Types::Integer
    attribute :scanned_from_carton_id, Types::Integer
    attribute :exit_ref, Types::String
    attribute :scrapped_at, Types::DateTime
    attribute :verification_result, Types::String
    attribute :pallet_verification_failure_reason_id, Types::Integer
    attribute :verified_at, Types::DateTime
    attribute :nett_weight, Types::Decimal
    attribute? :verified, Types::Bool
    attribute? :verification_passed, Types::Bool
    attribute :pick_ref, Types::String
    attribute :grade_id, Types::Integer
    attribute :verified_by, Types::String
    attribute :scrapped_from_pallet_id, Types::Integer
    attribute :removed_from_pallet, Types::Bool
    attribute :removed_from_pallet_id, Types::Integer
    attribute :removed_from_pallet_at, Types::DateTime
    attribute :sell_by_code, Types::String
    attribute :product_chars, Types::String
    attribute :depot_pallet, Types::Bool
    attribute :personnel_identifier_id, Types::Integer
    attribute :contract_worker_id, Types::Integer
    attribute :repacked_at, Types::DateTime
    attribute :repacked_from_pallet_id, Types::Integer
    attribute :failed_otmc_results, Types::Array
    attribute :phyto_data, Types::String
    attribute :created_by, Types::String
    attribute :target_market_id, Types::Integer
    attribute :pm_mark_id, Types::Integer
    attribute :marketing_puc_id, Types::Integer
    attribute :marketing_orchard_id, Types::Integer
    attribute :gtin_code, Types::String
    attribute :rmt_class_id, Types::Integer
    attribute :packing_specification_item_id, Types::Integer
    attribute :tu_labour_product_id, Types::Integer
    attribute :ru_labour_product_id, Types::Integer
    attribute :fruit_sticker_ids, Types::Array
    attribute :tu_sticker_ids, Types::Array
    attribute? :legacy_data, Types::Hash.optional
    attribute? :active, Types::Bool
  end

  class PalletSequenceFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :pallet_id, Types::Integer
    attribute :pallet_number, Types::String
    attribute :pallet_sequence_number, Types::Integer
    attribute :production_run_id, Types::Integer
    attribute :farm_id, Types::Integer
    attribute :farm_code, Types::String
    attribute :production_region_code, Types::String
    attribute :puc_id, Types::Integer
    attribute :puc_code, Types::String
    attribute :orchard_id, Types::Integer
    attribute :orchard_code, Types::String

    attribute :cultivar_group_id, Types::Integer
    attribute :cultivar_group_code, Types::String
    attribute :cultivar_id, Types::Integer
    attribute :cultivar_code, Types::String
    attribute :cultivar_name, Types::String
    attribute :commodity_id, Types::Integer
    attribute :commodity_code, Types::String
    attribute :commodity_description, Types::String

    attribute :product_resource_allocation_id, Types::Integer
    attribute :packhouse_resource_id, Types::Integer
    attribute :production_line_id, Types::Integer
    attribute :season_id, Types::Integer
    attribute :marketing_variety_id, Types::Integer
    attribute :marketing_variety_code, Types::String
    attribute :customer_variety_id, Types::Integer
    attribute :std_fruit_size_count_id, Types::Integer
    attribute :basic_pack_code_id, Types::Integer
    attribute :standard_pack_code_id, Types::Integer
    attribute :standard_pack_code, Types::String
    attribute :fruit_actual_counts_for_pack_id, Types::Integer
    attribute :fruit_size_reference_id, Types::Integer
    attribute :marketing_org_party_role_id, Types::Integer
    attribute :packed_tm_group_id, Types::Integer
    attribute :mark_id, Types::Integer
    attribute :inventory_code_id, Types::Integer
    attribute :pallet_format_id, Types::Integer
    attribute :cartons_per_pallet_id, Types::Integer
    attribute :pm_bom_id, Types::Integer
    attribute :extended_columns, Types::Hash
    attribute :client_size_reference, Types::String
    attribute :client_product_code, Types::String
    attribute :treatment_ids, Types::Array
    attribute :marketing_order_number, Types::String
    attribute :pm_type_id, Types::Integer
    attribute :pm_subtype_id, Types::Integer
    attribute :carton_quantity, Types::Integer
    attribute :pallet_carton_quantity, Types::Integer
    attribute :pallet_percentage, Types::Decimal
    attribute :scanned_from_carton_id, Types::Integer
    attribute :exit_ref, Types::String
    attribute :scrapped_at, Types::DateTime
    attribute :verification_result, Types::String
    attribute :pallet_verification_failure_reason_id, Types::Integer
    attribute :verified_at, Types::DateTime
    attribute :nett_weight, Types::Decimal
    attribute :verified, Types::Bool
    attribute :verification_passed, Types::Bool
    attribute :pick_ref, Types::String
    attribute :grade_id, Types::Integer
    attribute :grade_code, Types::String
    attribute :scrapped_from_pallet_id, Types::Integer
    attribute :removed_from_pallet, Types::Bool
    attribute :removed_from_pallet_id, Types::Integer
    attribute :removed_from_pallet_at, Types::DateTime
    attribute :sell_by_code, Types::String
    attribute :product_chars, Types::String
    attribute :depot_pallet, Types::Bool
    attribute :personnel_identifier_id, Types::Integer
    attribute :contract_worker_id, Types::Integer
    attribute :repacked_at, Types::DateTime
    attribute :repacked_from_pallet_id, Types::Integer
    attribute :failed_otmc_results, Types::Array
    attribute :phyto_data, Types::String
    attribute :created_by, Types::String
    attribute :verified_by, Types::String
    attribute :pm_mark_id, Types::Integer
    attribute :target_market_id, Types::Integer
    attribute :target_market_name, Types::String
    attribute :gtin_code, Types::String
    attribute? :active, Types::Bool
  end
end
