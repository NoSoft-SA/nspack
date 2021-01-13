# frozen_string_literal: true

module Production
  module PackingSpecifications
    module PackingSpecification
      class Edit
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:packing_specification, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Packing Specification'
              form.action "/production/packing_specifications/packing_specifications/#{id}"
              form.remote!
              form.method :update
              form.add_field :product_setup_template_id
              form.add_field :packing_specification_code
              form.add_field :description
            end
          end

          layout
        end
      end
    end
  end
end
