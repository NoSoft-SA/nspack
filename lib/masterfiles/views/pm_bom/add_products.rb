# frozen_string_literal: true

module Masterfiles
  module Packaging
    module PmBom
      class AddProducts
        def self.call(attrs, back_url:, form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:pm_bom, :add_products, attrs: attrs, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back',
                                  url: back_url,
                                  style: :back_button)
            end
            page.form do |form|
              form.view_only!
              form.no_submit!
              form.remote! if remote
              form.add_field :pm_subtype_ids
              form.add_field :pm_subtypes
            end

            page.section do |section|
              section.add_grid('pm_products',
                               '/list/pm_products_view/grid_multi/standard',
                               height: 35,
                               caption: 'Choose PKG Products',
                               is_multiselect: true,
                               multiselect_url: '/masterfiles/packaging/pm_boms/multiselect_pm_products',
                               multiselect_key: 'standard',
                               multiselect_params: { pm_subtype_ids: attrs[:pm_subtype_ids].nil_or_empty? ? '(null)' : attrs[:pm_subtype_ids],
                                                     selected_product_ids: attrs[:selected_product_ids].nil_or_empty? ? '(null)' : "(#{attrs[:selected_product_ids].join(',')})" })
            end
          end

          layout
        end
      end
    end
  end
end
