# frozen_string_literal: true

module MesscadaApp
  CartonSchema = Dry::Schema.Params do # rubocop:disable Metrics/BlockLength
    configure do
      def self.messages
        super.merge(en: { errors: { fruit_size_reference_or_fruit_actual_count: 'must provide either fruit_size_reference or fruit_actual_count' } })
      end
    end

    optional(:id).filled(:integer)
    required(:production_run_id).filled(:integer)
    required(:farm_id).filled(:integer)
    required(:puc_id).filled(:integer)
    required(:orchard_id).filled(:integer)
    required(:cultivar_group_id).filled(:integer)
    optional(:cultivar_id).maybe(:integer)
    required(:product_resource_allocation_id).maybe(:integer)
    required(:packhouse_resource_id).filled(:integer)
    required(:production_line_id).filled(:integer)
    required(:season_id).filled(:integer)
    required(:marketing_variety_id).filled(:integer)
    optional(:customer_variety_id).maybe(:integer)
    optional(:std_fruit_size_count_id).maybe(:integer)
    required(:basic_pack_code_id).filled(:integer)
    required(:standard_pack_code_id).filled(:integer)
    required(:fruit_actual_counts_for_pack_id).maybe(:integer)
    required(:fruit_size_reference_id).maybe(:integer)
    required(:marketing_org_party_role_id).filled(:integer)
    required(:packed_tm_group_id).filled(:integer)
    required(:mark_id).filled(:integer)
    required(:inventory_code_id).filled(:integer)
    required(:pallet_format_id).filled(:integer)
    required(:cartons_per_pallet_id).filled(:integer)
    optional(:pm_bom_id).maybe(:integer)
    optional(:extended_columns).maybe(:hash)
    optional(:client_size_reference).maybe(Types::StrippedString)
    optional(:client_product_code).maybe(Types::StrippedString)
    optional(:treatment_ids).filled(:array).each(:integer)
    optional(:marketing_order_number).maybe(Types::StrippedString)
    optional(:fruit_sticker_pm_product_id).maybe(:integer)
    optional(:pm_type_id).maybe(:integer)
    optional(:pm_subtype_id).maybe(:integer)
    required(:carton_label_id).filled(:integer)
    optional(:gross_weight).maybe(:decimal)
    optional(:nett_weight).maybe(:decimal)
    optional(:pick_ref).maybe(Types::StrippedString)
    required(:grade_id).filled(:integer)
    required(:product_chars).maybe(Types::StrippedString)
    required(:sell_by_code).maybe(Types::StrippedString)
    required(:pallet_label_name).maybe(Types::StrippedString)
    optional(:pallet_number).maybe(Types::StrippedString)
    required(:phc).filled(Types::StrippedString)
    required(:packing_method_id).filled(:integer)
    optional(:palletizer_identifier_id).maybe(:integer)
    optional(:pallet_sequence_id).maybe(:integer)
    optional(:palletizing_bay_resource_id).maybe(:integer)
    optional(:is_virtual).maybe(:bool)
    optional(:scrapped).maybe(:bool)
    optional(:scrapped_at).maybe(:time)
    optional(:scrapped_sequence_id).maybe(:integer)

    # FIXME: Dry-upgrade
    # validate(fruit_size_reference_or_fruit_actual_count: %i[fruit_size_reference_id fruit_actual_counts_for_pack_id]) do |fruit_size_reference_id, fruit_actual_counts_for_pack_id|
    #   fruit_size_reference_id || fruit_actual_counts_for_pack_id
    # end
  end
end
