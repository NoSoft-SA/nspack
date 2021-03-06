# frozen_string_literal: true

module RawMaterials
  module BinAssets
    module BinAssetTransactionItem
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true, interactor: nil)
          ui_rule = UiRules::Compiler.new(:bin_asset_transaction_item, :new, form_values: form_values, interactor: interactor)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.add_text rules[:compact_header]
            page.section do |sec|
              sec.form do |form|
                form.form_id 'bin_asset_transaction_item'
                form.caption 'Add Bin Asset Type'
                form.action '/raw_materials/bin_assets/bin_asset_transactions/bin_asset_transaction_items/add'
                form.remote! if remote
                form.add_field :rmt_material_owner_party_role_id
                form.add_field :rmt_container_material_type_id
                form.add_field :quantity_bins
                form.add_field :bin_sets

                form.submit_captions 'Add Bin Set', 'Adding'
              end
            end

            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Done',
                                  url: '/raw_materials/bin_assets/bin_asset_transactions/bin_asset_transaction_items/done',
                                  behaviour: :replace_dialog,
                                  style: :button)
            end
          end

          layout
        end
      end
    end
  end
end
