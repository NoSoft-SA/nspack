# frozen_string_literal: true

module Masterfiles
  module Shipping
    module VoyageType
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:voyage_type, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Voyage Type'
              form.view_only!
              form.add_field :voyage_type_code
              form.add_field :description
              form.add_field :industry_description
              form.add_field :active
            end
          end

          layout
        end
      end
    end
  end
end
