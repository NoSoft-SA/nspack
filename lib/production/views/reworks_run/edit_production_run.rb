# frozen_string_literal: true

module Production
  module Reworks
    module ReworksRun
      class EditProductionRun
        def self.call(id, production_run_id, reworks_run_type_id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:reworks_run_sequence, :change_production_run, reworks_run_type_id: reworks_run_type_id, old_production_run_id: production_run_id, pallet_sequence_id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.add_text rules[:compact_header]
            page.form do |form|
              form.caption 'Change Production Run'
              form.action "/production/reworks/pallet_sequences/#{id}/edit_reworks_production_run"
              form.remote!
              form.row do |row|
                row.column do |col|
                  col.add_field :pallet_sequence_id
                  col.add_field :old_production_run_id
                  col.add_field :allow_cultivar_group_mixing
                  col.add_field :production_run_id
                  col.add_field :reworks_run_type_id
                  col.add_table [],
                                %i[id packhouse line farm puc orchard cultivar_group cultivar],
                                pivot: true,
                                top_margin: 2,
                                dom_id: 'reworks_run_pallet_production_run_details'
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
