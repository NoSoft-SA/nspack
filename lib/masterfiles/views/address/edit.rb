# frozen_string_literal: true

module Masterfiles
  module Parties
    module Address
      class Edit
        def self.call(id, form_values = nil, form_errors = nil)
          ui_rule = UiRules::Compiler.new(:address, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.action "/masterfiles/parties/addresses/#{id}"
              form.remote!
              form.method :update
              form.add_field :address_type_id
              form.add_field :address_line_1
              form.add_field :address_line_2
              form.add_field :address_line_3
              form.add_field :city
              form.add_field :postal_code
              form.add_field :country
            end
          end

          layout
        end
      end
    end
  end
end
