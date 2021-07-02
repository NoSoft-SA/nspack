# frozen_string_literal: true

module Production
  module Reworks
    module ReworksRun
      class CloneSequence
        def self.call(id, reworks_run_type_id, back_url:, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:reworks_run_sequence, :clone_sequence, reworks_run_type_id: reworks_run_type_id, pallet_sequence_id: id, form_values: form_values)
          rules = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back',
                                  url: back_url,
                                  style: :back_button)
            end
            page.add_text rules[:compact_header]
            page.form do |form|
              form.caption 'Clone Pallet Sequence'
              form.action "/production/reworks/pallet_sequences/#{id}/clone_sequence"
              form.remote!
              form.row do |row|
                row.column do |col|
                  col.add_field :reworks_run_type_id
                  col.add_field :pallet_id
                  col.add_field :pallet_sequence_id
                  col.add_field :allow_cultivar_mixing
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
