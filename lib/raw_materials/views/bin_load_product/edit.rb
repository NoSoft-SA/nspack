# frozen_string_literal: true

module RawMaterials
  module Dispatch
    module BinLoadProduct
      class Edit
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:bin_load_product, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Product'
              form.action "/raw_materials/dispatch/bin_load_products/#{id}"
              form.remote!
              form.method :update
              form.row do |row|
                row.column do |col|
                  col.add_field :bin_load_id
                  col.add_field :qty_bins
                  col.add_field :cultivar_group_id
                  col.add_field :cultivar_id
                  col.add_field :rmt_container_material_type_id
                  col.add_field :rmt_material_owner_party_role_id
                end
                row.column do |col|
                  col.add_field :farm_id
                  col.add_field :puc_id
                  col.add_field :orchard_id
                  col.add_field :rmt_class_id
                end
              end
            end
          end

          layout
        end
      end
    end
  end
end
