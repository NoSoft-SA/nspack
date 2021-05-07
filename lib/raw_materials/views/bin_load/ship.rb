# frozen_string_literal: true

module RawMaterials
  module Dispatch
    module BinLoad
      class Ship
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:bin_load, :ship, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.action "/raw_materials/dispatch/bin_loads/#{id}/shipped_at"
              form.add_field :shipped_at
            end
          end

          layout
        end
      end
    end
  end
end
