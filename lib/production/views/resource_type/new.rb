# frozen_string_literal: true

module Production
  module Resources
    module ResourceType
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:resource_type, :new, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Resource Type'
              form.action '/production/resources/resource_types'
              form.remote! if remote
              form.add_field :resource_type_code
              form.add_field :description
              # form.add_field :attribute_rules
              # form.add_field :behaviour_rules
            end
          end

          layout
        end
      end
    end
  end
end
