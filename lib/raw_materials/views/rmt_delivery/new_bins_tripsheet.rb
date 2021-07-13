# frozen_string_literal: true

module RawMaterials
  module Deliveries
    module RmtDelivery
      class NewBinsTripsheet
        def self.call(id, mode: :new, form_values: nil, form_errors: nil, remote: false)
          ui_rule = UiRules::Compiler.new(:bins_tripsheet, mode, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.action "/raw_materials/deliveries/rmt_deliveries/#{id}/create_tripsheet"
              form.remote! if remote
              form.add_field :planned_location_to_id
            end
          end

          layout
        end
      end
    end
  end
end
