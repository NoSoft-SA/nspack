# frozen_string_literal: true

module Masterfiles
  module Quality
    module InspectionType
      class Edit
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:inspection_type, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page| # rubocop:disable Metrics/BlockLength
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Inspection Type'
              form.action "/masterfiles/quality/inspection_types/#{id}"
              form.remote!
              form.method :update
              form.row do |row|
                row.column do |col|
                  col.add_field :inspection_type_code
                  col.add_field :description
                  col.add_field :inspection_failure_type_id
                end
                row.column do |col|
                  col.add_field :applies_to_all_tm_groups
                  col.add_field :applicable_tm_group_ids

                  col.add_field :applies_to_all_grades
                  col.add_field :applicable_grade_ids

                  col.add_field :applies_to_all_cultivars
                  col.add_field :applicable_cultivar_ids

                  col.add_field :applies_to_all_orchards
                  col.add_field :applicable_orchard_ids
                end
              end
            end
          end

          layout
        end
      end
    end
  end
end
