# frozen_string_literal: true

module Production
  module Reports
    module Packout
      class Edit
        def self.call
          ui_rule = UiRules::Compiler.new(:packout_report, :edit)
          rules   = ui_rule.compile
          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              form.submit_in_loading_page!
              form.caption 'Packout Report'
              form.action '/production/reports/aggregate_packout_print'
              form.row do |row|
                row.column do |col|
                  col.add_field :from_date
                  col.add_field :to_date
                  col.add_field :detail_level
                  col.add_field :dispatched_only
                  col.add_field :packhouse_resource_id
                  col.add_field :line_resource_id
                  col.add_field :puc_id
                  col.add_field :orchard_id
                  col.add_field :cultivar_id
                end
                row.blank_column
              end
            end
          end
          layout
        end
      end
    end
  end
end
