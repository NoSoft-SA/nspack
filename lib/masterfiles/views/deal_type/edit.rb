# frozen_string_literal: true

module Masterfiles
  module Finance
    module DealType
      class Edit
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:deal_type, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Deal Type'
              form.action "/masterfiles/finance/deal_types/#{id}"
              form.remote!
              form.method :update
              form.add_field :deal_type
              form.add_field :fixed_amount
            end
          end

          layout
        end
      end
    end
  end
end
