# frozen_string_literal: true

module Production
  module Resources
    module Resource
      class Edit
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:resource, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Resource'
              form.action "/production/resources/resources/#{id}"
              form.remote!
              form.method :update
              form.add_field :resource_type_id
              form.add_field :system_resource_id
              form.add_field :resource_code
              form.add_field :description
              form.add_field :resource_attributes
            end
          end

          layout
        end
      end
    end
  end
end
