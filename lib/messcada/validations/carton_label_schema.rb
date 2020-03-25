# frozen_string_literal: true

module MesscadaApp
  CartonLabelSchema = Dry::Validation.Params do # rubocop:disable Metrics/BlockLength
    configure do
      config.type_specs = true

      def self.messages
        super.merge(en: { errors: { fruit_size_reference_or_fruit_actual_count: 'must provide either fruit_size_reference or fruit_actual_count' } })
      end
    end

    optional(:id, :integer).filled(:int?)
    required(:production_run_id, :integer).filled(:int?)
    required(:farm_id, :integer).filled(:int?)
    required(:puc_id, :integer).filled(:int?)
    required(:orchard_id, :integer).filled(:int?)
    required(:cultivar_group_id, :integer).filled(:int?)
    optional(:cultivar_id, :integer).maybe(:int?)
    required(:product_resource_allocation_id, :integer).maybe(:int?)
    required(:packhouse_resource_id, :integer).filled(:int?)
    required(:production_line_id, :integer).filled(:int?)
    required(:season_id, :integer).filled(:int?)
    required(:marketing_variety_id, :integer).filled(:int?)
    optional(:customer_variety_variety_id, :integer).maybe(:int?)
    optional(:std_fruit_size_count_id, :integer).maybe(:int?)
    required(:basic_pack_code_id, :integer).filled(:int?)
    required(:standard_pack_code_id, :integer).filled(:int?)
    required(:fruit_actual_counts_for_pack_id, :integer).maybe(:int?)
    required(:fruit_size_reference_id, :integer).maybe(:int?)
    required(:marketing_org_party_role_id, :integer).filled(:int?)
    required(:packed_tm_group_id, :integer).filled(:int?)
    required(:mark_id, :integer).filled(:int?)
    required(:inventory_code_id, :integer).filled(:int?)
    required(:pallet_format_id, :integer).filled(:int?)
    required(:cartons_per_pallet_id, :integer).filled(:int?)
    optional(:pm_bom_id, :integer).maybe(:int?)
    optional(:extended_columns, :hash).maybe(:hash?)
    optional(:client_size_reference, Types::StrippedString).maybe(:str?)
    optional(:client_product_code, Types::StrippedString).maybe(:str?)
    optional(:treatment_ids, Types::IntArray).maybe { each(:int?) }
    optional(:marketing_order_number, Types::StrippedString).maybe(:str?)
    optional(:fruit_sticker_pm_product_id, :integer).maybe(:int?)
    optional(:pm_type_id, :integer).maybe(:int?)
    optional(:pm_subtype_id, :integer).maybe(:int?)
    optional(:resource_id, :integer).maybe(:int?)
    optional(:label_name, Types::StrippedString).maybe(:str?)
    optional(:pick_ref, Types::StrippedString).maybe(:str?)
    required(:grade_id, :integer).filled(:int?)
    required(:product_chars, Types::StrippedString).maybe(:str?)
    required(:sell_by_code, Types::StrippedString).maybe(:str?)
    required(:pallet_label_name, Types::StrippedString).maybe(:str?)
    optional(:pallet_number, Types::StrippedString).maybe(:str?)
    optional(:phc, Types::StrippedString).filled(:str?)
    optional(:personnel_identifier_id, :integer).maybe(:int?)
    optional(:contract_worker_id, :integer).maybe(:int?)
    required(:packing_method_id, :integer).filled(:int?)

    validate(fruit_size_reference_or_fruit_actual_count: %i[fruit_size_reference_id fruit_actual_counts_for_pack_id]) do |fruit_size_reference_id, fruit_actual_counts_for_pack_id|
      fruit_size_reference_id || fruit_actual_counts_for_pack_id
    end
  end
end
