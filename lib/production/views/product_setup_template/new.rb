# frozen_string_literal: true

module Production
  module ProductSetups
    module ProductSetupTemplate
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:product_setup_template, :new, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Product Setup Template'
              form.action '/production/product_setups/product_setup_templates'
              form.remote! if remote
              form.add_field :template_name
              form.add_field :description
              form.add_field :cultivar_group_id
              form.add_field :cultivar_id
              form.add_field :packhouse_resource_id
              form.add_field :production_line_id
              form.add_field :season_group_id
              form.add_field :season_id
            end
          end

          layout
        end
      end
    end
  end
end
