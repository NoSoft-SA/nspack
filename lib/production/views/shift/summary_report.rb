# frozen_string_literal: true

module Production
  module Production
    module Shift
      class SummaryReport
        def self.call(employment_type, attrs, back_url:) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:shift, :summary_report, employment_type: employment_type, attrs: attrs)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back',
                                  url: back_url,
                                  style: :back_button)
            end
            page.form do |form|
              form.no_submit!
              form.row do |row|
                row.column do |col|
                  col.add_field :from_date
                  col.add_field :from_date_label
                  col.add_field :to_date
                  col.add_field :to_date_label
                  col.add_field :employment_type_id
                  col.add_field :employment_type
                end
                row.blank_column
              end
            end
            page.section do |section|
              section.fit_height!
              section.add_grid('contract_workers',
                               '/list/contract_workers/grid_multi',
                               height: 35,
                               caption: employment_type.to_s.capitalize.gsub('_', ' '),
                               is_multiselect: true,
                               can_be_cleared: false,
                               multiselect_save_method: 'loading',
                               multiselect_url: "/production/shifts/summary_reports/#{employment_type}/incentive_summary_report",
                               multiselect_key: 'employment_type',
                               multiselect_params: { key: 'employment_type',
                                                     employment_type_id: attrs[:employment_type_id] })
            end
          end

          layout
        end
      end
    end
  end
end
