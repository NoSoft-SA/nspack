# frozen_string_literal: true

module Masterfiles
  module Quality
    module Inspector
      class Edit
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:inspector, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Inspector'
              form.action "/masterfiles/quality/inspectors/#{id}"
              form.remote!
              form.method :update
              form.add_field :inspector
              form.add_field :party_role_id
              form.add_field :inspector_code
              form.add_field :tablet_ip_address
              form.add_field :tablet_port_number
            end
          end

          layout
        end
      end
    end
  end
end
