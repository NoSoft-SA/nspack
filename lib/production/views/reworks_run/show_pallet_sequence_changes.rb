# frozen_string_literal: true

module Production
  module Reworks
    module ReworksRun
      class ShowPalletSequenceChanges
        def self.call(id, attrs, back_url:) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:reworks_run_pallet, :show_changes, id: id, attrs: attrs)
          rules   = ui_rule.compile

          notice = if rules[:no_changes_made]
                     'No changes were made'
                   else
                     'The changes below will be made to affected pallets list:'
                   end
          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back',
                                  url: back_url,
                                  style: :back_button)
            end
            page.section do |section|
              section.add_notice notice
              section.add_diff :changes_made
            end
            unless rules[:no_changes_made]
              page.section do |section|
                section.row do |row|
                  row.column do |col|
                    col.add_control(control_type: :link,
                                    text: 'Accept',
                                    url: "/production/reworks/pallet_sequences/#{id}/accept_pallet_sequence_changes",
                                    style: :button)
                    col.add_control(control_type: :link,
                                    text: 'Reject',
                                    url: "/production/reworks/pallet_sequences/#{id}/reject_pallet_sequence_changes",
                                    style: :button)
                  end
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
