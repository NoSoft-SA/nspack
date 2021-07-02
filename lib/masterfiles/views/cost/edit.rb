# frozen_string_literal: true

module Masterfiles
  module Costs
    module Cost
      class Edit
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:cost, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Cost'
              form.action "/masterfiles/costs/costs/#{id}"
              form.remote!
              form.method :update
              form.add_field :cost_type_id
              form.add_field :cost_code
              form.add_field :default_amount
              form.add_field :description
            end
          end

          layout
        end
      end
    end
  end
end
