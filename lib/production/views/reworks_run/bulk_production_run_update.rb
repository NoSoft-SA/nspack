# frozen_string_literal: true

module Production
  module Reworks
    module ReworksRun
      class BulkProductionRunUpdate
        def self.call(id, attrs)
          ui_rule = UiRules::Compiler.new(:reworks_run_bulk_update, :production_run_bulk_update, id: id, attrs: attrs)
          rules   = ui_rule.compile

          if rules[:bulk_pallet_run_update]
            caption = 'Pallets'
            grid = 'stock_pallets'
            grid_key = 'reworks_bulk_update_pallets'
          elsif rules[:bulk_bin_run_update]
            caption = 'Bins'
            grid = 'rmt_bins_reworks'
            grid_key = 'reworks_bulk_update_bins'
          end

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              form.view_only!
              form.no_submit!
              form.row do |row|
                row.column do |col|
                  col.add_field :reworks_run_type_id
                  col.add_field :reworks_run_type
                  col.add_field :pallets_selected
                  col.add_field :from_production_run_id
                  col.add_field :to_production_run_id
                end
                row.blank_column
              end
            end
            page.section do |section|
              section.add_notice 'The following production run details have changed', inline_caption: true
              section.add_diff :changes_made
            end
            page.section do |section|
              section.row do |row|
                row.column do |col|
                  col.add_notice "Select #{caption} for update from the grid below", inline_caption: true
                  col.add_control(control_type: :link,
                                  text: 'Cancel',
                                  url: "/production/reworks/reworks_run_types/#{id}/reject_bulk_production_run_update",
                                  style: :button)
                end
              end
            end
            page.section do |section|
              section.fit_height!
              section.add_grid(grid.to_s,
                               "/list/#{grid}/grid_multi",
                               height: 10,
                               caption: "Choose #{caption}",
                               is_multiselect: true,
                               can_be_cleared: false,
                               multiselect_url: "/production/reworks/reworks_run_types/#{id}/reworks_runs/multiselect_reworks_run_bulk_production_run_update",
                               multiselect_key: grid_key.to_s,
                               multiselect_params: { key: grid_key.to_s,
                                                     id: id,
                                                     production_run_id: attrs[:from_production_run_id],
                                                     pallets_selected: attrs[:pallets_selected].nil_or_empty? ? '(null)' : "('#{attrs[:pallets_selected].join('\',\'')}')" })
            end
          end

          layout
        end
      end
    end
  end
end
