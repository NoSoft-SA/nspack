# frozen_string_literal: true

module RawMaterials
  module BinAssets
    module BinAssetTransaction
      class AdhocMove
        def self.call(form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:bin_asset_transaction, :adhoc, form_values: form_values, adhoc_type: 'move')
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Adhoc Move Bin Assets'
              form.action '/raw_materials/bin_assets/bin_asset_transactions/adhoc_transaction'
              form.remote! if remote
              form.add_field :asset_transaction_type_id
              form.add_field :bin_asset_from_location_id
              form.add_field :bin_asset_to_location_id
              form.add_field :business_process_id
              form.add_field :quantity_bins
              form.add_field :reference_number
              form.add_field :is_adhoc
            end
          end

          layout
        end
      end
    end
  end
end
