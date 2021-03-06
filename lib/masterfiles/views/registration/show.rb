# frozen_string_literal: true

module Masterfiles
  module Parties
    module Registration
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:registration, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Party Registration'
              form.view_only!
              form.add_field :party_role_id
              form.add_field :registration_type
              form.add_field :registration_code
            end
          end

          layout
        end
      end
    end
  end
end
