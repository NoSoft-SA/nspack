# frozen_string_literal: true

module Production
  module Shifts
    module Shift
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:shift, :new, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Shift'
              form.action '/production/shifts/shifts'
              form.remote! if remote
              form.add_field :shift_type_id
              form.add_field :date
              Crossbeams::Config::ExtendedColumnDefinitions.extended_columns_for_view(:shifts, form)
            end
          end

          layout
        end
      end
    end
  end
end
