# frozen_string_literal: true

module Masterfiles
  module Finance
    module Customer
      class Edit
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:customer, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Customer'
              form.action "/masterfiles/finance/customers/#{id}"
              form.remote!
              form.method :update
              form.add_field :customer
              form.add_field :customer_party_role_id
              form.add_field :default_currency_id
            end
          end

          layout
        end
      end
    end
  end
end
