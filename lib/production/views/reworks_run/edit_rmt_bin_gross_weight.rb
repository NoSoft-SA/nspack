# frozen_string_literal: true

module Production
  module Reworks
    module ReworksRun
      class EditRmtBinGrossWeight
        def self.call(reworks_run_type_id, bin_number,  form_values: nil, form_errors: nil, back_url:) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:reworks_run_rmt_bin, :set_rmt_bin_gross_weight, bin_number: bin_number, reworks_run_type_id: reworks_run_type_id, form_values: form_values)
          rules   = ui_rule.compile

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
              form.action "/production/reworks/reworks_run_types/#{reworks_run_type_id}/pallets/#{bin_number}/edit_rmt_bin_gross_weight"
              form.add_field :bin_number
              form.add_field :reworks_run_type_id
              form.add_field :gross_weight
              form.add_field :measurement_unit
            end
          end

          layout
        end
      end
    end
  end
end
