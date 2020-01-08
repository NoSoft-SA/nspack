# frozen_string_literal: true

module Masterfiles
  module Shipping
    module Port
      class Edit
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:port, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Port'
              form.action "/masterfiles/shipping/ports/#{id}"
              form.remote!
              form.method :update
              form.add_field :port_code
              form.add_field :description
              form.add_field :city_id
              form.add_field :port_type_ids
              form.add_field :voyage_type_ids
            end
          end

          layout
        end
      end
    end
  end
end
