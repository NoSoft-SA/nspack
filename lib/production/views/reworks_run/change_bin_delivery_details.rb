# frozen_string_literal: true

module Production
  module Reworks
    module ReworksRun
      class ChangeBinDeliveryDetails
        def self.call(attrs) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:change_bin_delivery, :details, attrs: attrs)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back',
                                  url: '/production/reworks/reworks_run_types/change_bin_delivery/reworks_runs/new',
                                  style: :back_button)
            end
            page.form do |form|
              form.view_only!
              form.no_submit!
              form.row do |row|
                row.column do |col|
                  col.add_field :reworks_run_type_id
                  col.add_field :reworks_run_type
                  col.add_field :from_delivery_id
                  col.add_field :to_delivery_id
                end
                row.blank_column
              end
            end
            page.section do |section|
              section.row do |row|
                row.column do |col|
                  col.add_notice 'Select Bins for update from the grid below', inline_caption: true
                end
              end
            end
            page.section do |section|
              section.fit_height!
              section.add_grid('rmt_bins_reworks',
                               '/list/rmt_bins_reworks/grid_multi',
                               height: 10,
                               caption: 'Choose Bins',
                               is_multiselect: true,
                               can_be_cleared: false,
                               multiselect_url: '/production/reworks/change_bin_delivery/multiselect_rmt_bin_deliveries_submit',
                               multiselect_key: 'reworks_change_bin_delivery',
                               multiselect_params: { key: 'reworks_change_bin_delivery',
                                                     id: attrs[:reworks_run_type_id].to_i,
                                                     rmt_delivery_id: attrs[:from_delivery_id].to_i })
            end
          end

          layout
        end
      end
    end
  end
end
