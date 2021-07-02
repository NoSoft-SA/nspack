# frozen_string_literal: true

module Production
  module ProductSetups
    module ProductSetupTemplate
      class Clone
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:product_setup_template, :clone, id: id, form_values: form_values)
          rules   = ui_rule.compile

          cloned_from = ProductionApp::ProductSetupRepo.new.find_product_setup_template(id)&.template_name
          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back',
                                  url: '/list/product_setup_templates',
                                  style: :back_button)
              section.add_text("Cloned from Product Setup Template: #{cloned_from}", wrapper: :h3)
            end
            page.form do |form|
              form.caption 'Clone Product Setup Template'
              form.action "/production/product_setups/product_setup_templates/#{id}/clone_product_setup_template"
              form.remote!
              form.row do |row|
                row.column do |col|
                  col.add_field :id
                  col.add_field :template_name
                  col.add_field :description
                  col.add_field :cultivar_group_id
                  col.add_field :cultivar_group_code
                  col.add_field :cultivar_id
                  col.add_field :cultivar_name
                  col.add_field :marketing_variety_id
                end
                row.column do |col|
                  col.add_field :packhouse_resource_id
                  col.add_field :production_line_id
                  col.add_field :season_group_id
                  col.add_field :season_id
                end
              end
            end

            page.section do |section|
              section.add_grid('product_setups',
                               "/list/product_setups_view/grid?key=standard&product_setups.product_setup_template_id=#{id}",
                               caption: 'Product Setups')
            end
          end

          layout
        end
      end
    end
  end
end
