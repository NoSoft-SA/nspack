# frozen_string_literal: true

module Labels
  module Labels
    module Label
      class Import
        def self.call(form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:label, :import, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.action '/labels/labels/labels/add_import'
              form.remote! if remote
              form.multipart!
              form.add_field :import_file
              form.add_field :label_name
              form.add_field :variable_set
              # form.add_field :label_dimension
              # form.add_field :px_per_mm
              # form.add_field :container_type
              # form.add_field :commodity
              # form.add_field :market
              # form.add_field :language
              # form.add_field :category
              # form.add_field :sub_category
              # form.add_field :multi_label
            end
          end

          layout
        end
      end
    end
  end
end
