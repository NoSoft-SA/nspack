# frozen_string_literal: true

module Masterfiles
  module Parties
    module ContactMethod
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:contact_method, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              form.view_only!
              form.add_field :contact_method_type
              form.add_field :contact_method_code
              form.add_field :active
            end
          end

          layout
        end
      end
    end
  end
end
