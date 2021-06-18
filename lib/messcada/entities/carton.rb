# frozen_string_literal: true

module MesscadaApp
  class Carton < Dry::Struct
    attribute :id, Types::Integer
    attribute :carton_label_id, Types::Integer
    attribute :gross_weight, Types::Decimal
    attribute :nett_weight, Types::Decimal
    attribute? :active, Types::Bool
    attribute :palletizer_identifier_id, Types::Integer
    attribute :pallet_sequence_id, Types::Integer
    attribute :palletizing_bay_resource_id, Types::Integer
    attribute? :is_virtual, Types::Bool
    attribute? :scrapped, Types::Bool
    attribute :scrapped_reason, Types::String
    attribute :scrapped_at, Types::DateTime
    attribute :scrapped_sequence_id, Types::Integer
    attribute :palletizer_contract_worker_id, Types::Integer
  end

  class CartonFlat < Dry::Struct
    attribute :id, Types::Integer
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
    attribute :fruit_sticker_pm_product_id, Types::Integer
    attribute :pm_type_id, Types::Integer
    attribute :pm_subtype_id, Types::Integer
    attribute :carton_label_id, Types::Integer
    attribute :gross_weight, Types::Decimal
    attribute :nett_weight, Types::Decimal
    attribute? :active, Types::Bool
    attribute :pick_ref, Types::String
    attribute :grade_id, Types::Integer
    attribute :pallet_number, Types::String
    attribute :phc, Types::String
    attribute :packing_method_id, Types::Integer
    attribute :palletizer_identifier_id, Types::Integer
    attribute :pallet_sequence_id, Types::Integer
    attribute :palletizing_bay_resource_id, Types::Integer
    attribute? :is_virtual, Types::Bool
    attribute? :scrapped, Types::Bool
    attribute :scrapped_reason, Types::String
    attribute :scrapped_at, Types::DateTime
    attribute :scrapped_sequence_id, Types::Integer
    attribute :palletizer_contract_worker_id, Types::Integer
    attribute :target_market_id, Types::Integer
    attribute :pm_mark_id, Types::Integer
    attribute :marketing_puc_id, Types::Integer
    attribute :marketing_orchard_id, Types::Integer
    attribute :group_incentive_id, Types::Integer
    attribute :rmt_bin_id, Types::Integer
    attribute? :dp_carton, Types::Bool
    attribute :gtin_code, Types::String
    attribute :rmt_class_id, Types::Integer
    attribute :packing_specification_item_id, Types::Integer
    attribute :tu_labour_product_id, Types::Integer
    attribute :ru_labour_product_id, Types::Integer
    attribute :fruit_sticker_ids, Types::Array
    attribute :tu_sticker_ids, Types::Array
    attribute :target_customer_party_role_id, Types::Integer
    attribute :product_chars, Types::String
  end

  class ScannedCartonNumber < Dry::Struct
    attribute :scanned_carton_number, Types::String

    def carton_number
      raise Crossbeams::InfoError, 'Scan field empty.' if scanned_carton_number.nil_or_empty?

      raise Crossbeams::InfoError, "#{scanned_carton_number} is not a recognised carton number length." unless scanned_carton_number.length < 8

      scanned_carton_number
    end

    def legacy_carton_number
      raise Crossbeams::InfoError, 'Scan field empty.' if scanned_carton_number.nil_or_empty?

      raise Crossbeams::InfoError, "#{scanned_carton_number} is not a recognised legacy carton number length." unless scanned_carton_number.length == 12

      scanned_carton_number
    end
  end
end
