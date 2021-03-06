# frozen_string_literal: true

module Masterfiles
  module Packaging
    module PackingMethod
      class Edit
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:packing_method, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Packing Method'
              form.action "/masterfiles/packaging/packing_methods/#{id}"
              form.remote!
              form.method :update
              form.add_field :packing_method_code
              form.add_field :description
              form.add_field :actual_count_reduction_factor
            end
          end

          layout
        end
      end
    end
  end
end
