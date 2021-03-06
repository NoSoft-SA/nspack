# frozen_string_literal: true

module Masterfiles
  module Parties
    module Registration
      class New
        def self.call(party_id: nil, form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:registration, :new, party_id: party_id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Party Role Registration'
              form.action '/masterfiles/parties/registrations'
              form.remote! if remote
              form.add_field :party_id
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
