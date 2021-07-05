# frozen_string_literal: true

module Masterfiles
  module Fruit
    module StandardPack
      class Edit
        def self.call(id, form_values = nil, form_errors = nil)
          ui_rule = UiRules::Compiler.new(:standard_pack, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.action "/masterfiles/fruit/standard_pack_codes/#{id}"
              form.remote!
              form.method :update
              form.add_field :standard_pack_code
              form.add_field :description
              form.add_field :std_pack_label_code
              form.add_field :material_mass
              form.add_field :plant_resource_button_indicator
              form.add_field :use_size_ref_for_edi
              form.add_field :palletizer_incentive_rate
              form.add_field :bin
              form.add_field :rmt_container_type_id
              form.add_field :rmt_container_material_type_id
              form.add_field :basic_pack_ids
            end
          end

          layout
        end
      end
    end
  end
end
