# frozen_string_literal: true

module Labels
  module Labels
    module Label
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:label, :new, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.action '/labels/labels/labels'
              form.remote! if remote
              form.add_field :label_name
              form.add_field :label_dimension
              form.add_field :px_per_mm
              form.add_field :variable_set
              form.add_field :print_rotation
              form.add_field :multi_label
              Crossbeams::Config::ExtendedColumnDefinitions.extended_columns_for_view(:labels, form)
            end
          end

          layout
        end
      end
    end
  end
end
