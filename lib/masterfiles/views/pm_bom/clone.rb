# frozen_string_literal: true

module Masterfiles
  module Packaging
    module PmBom
      class Clone
        def self.call(id, attrs, form_values: nil, form_errors: nil, remote: true) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:pm_bom, :clone, id: id, attrs: attrs, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back',
                                  url: '/list/pm_boms',
                                  style: :back_button)
              section.add_text('Clone PKG Bom to counts', wrapper: :h3)
            end
            page.form do |form|
              form.view_only!
              form.no_submit!
              form.caption 'Clone PKG Bom'
              form.remote! if remote
              form.row do |row|
                row.column do |col|
                  col.add_field :bom_code
                  col.add_field :gross_weight
                end
                row.column do |col|
                  col.add_field :system_code
                  col.add_field :nett_weight
                end
              end
            end

            page.section do |section|
              section.add_notice 'Select PKG Products from the grid below', inline_caption: true
            end

            page.section do |section|
              section.fit_height!
              section.add_grid('pm_products',
                               '/list/pm_products_view/grid_multi/clone_bom_to_counts',
                               height: 35,
                               caption: 'Choose PKG Products',
                               is_multiselect: true,
                               multiselect_url: '/masterfiles/packaging/pm_boms/clone_bom_to_counts',
                               multiselect_key: 'clone_bom_to_counts',
                               multiselect_params: { pm_bom_id: attrs[:pm_bom_id],
                                                     pm_subtype_id: attrs[:pm_subtype_id],
                                                     fruit_count_product_ids: attrs[:fruit_count_product_ids].nil_or_empty? ? 'null' : attrs[:fruit_count_product_ids] })
            end
          end

          layout
        end
      end
    end
  end
end
