# frozen_string_literal: true

module Masterfiles
  module Shipping
    module VesselType
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:vessel_type, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Vessel Type'
              form.view_only!
              form.add_field :voyage_type_id
              form.add_field :vessel_type_code
              form.add_field :description
              form.add_field :active
            end
          end

          layout
        end
      end
    end
  end
end
