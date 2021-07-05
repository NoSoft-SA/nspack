# frozen_string_literal: true

module Production
  module Reworks
    module ReworksRun
      class EditFarmDetails
        def self.call(id, reworks_run_type_id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:reworks_run_sequence, :edit_farm_details, reworks_run_type_id: reworks_run_type_id, pallet_sequence_id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.add_text rules[:compact_header]
            page.form do |form|
              form.action "/production/reworks/pallet_sequences/#{id}/edit_reworks_farm_details"
              form.remote!
              form.add_field :pallet_sequence_id
              form.add_field :reworks_run_type_id
              form.add_field :farm_id
              form.add_field :puc_id
              form.add_field :orchard_id
              form.add_field :cultivar_group_id
              form.add_field :cultivar_group
              form.add_field :cultivar_id
              form.add_field :season_id
            end
          end

          layout
        end
      end
    end
  end
end
