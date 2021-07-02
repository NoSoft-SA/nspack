# frozen_string_literal: true

module Production
  module Reworks
    module ReworksRun
      class Show
        def self.call(id) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:reworks_run, :show, id: id)
          rules   = ui_rule.compile

          caption = rules[:bin_run_type] ? 'Bins' : 'Pallets'
          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Reworks Run'
              form.view_only!
              form.add_field :created_at
              form.add_field :reworks_run_type_id
              form.add_field :scrap_reason_id
              form.add_field :remarks
              form.add_field :reworks_action
              form.add_field :user
              form.add_field :pallets_selected
              form.add_field :pallets_affected
              form.add_field :pallet_number
              form.add_field :pallet_sequence_number
              form.add_field :allow_cultivar_group_mixing
              form.add_field :allow_cultivar_mixing
              if rules[:has_children]
                form.add_text 'Affected Objects'
                form.add_text rules[:compact_header]
              end
            end
            if rules[:show_changes_made]
              page.add_notice "The changes below were made to the affected #{caption}:", inline_caption: true
              page.section do |section|
                if rules[:array_of_changes_made]
                  rules[:changes_made_array_count].times do |i|
                    section.add_diff "changes_made_#{i}".to_sym
                  end
                else
                  section.add_diff :changes_made
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
