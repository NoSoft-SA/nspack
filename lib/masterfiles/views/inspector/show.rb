# frozen_string_literal: true

module Masterfiles
  module Quality
    module Inspector
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:inspector, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Inspector'
              form.view_only!
              form.add_field :inspector_party_role_id
              form.add_field :inspector_code
              form.add_field :tablet_ip_address
              form.add_field :tablet_port_number
              form.add_field :active
            end
          end

          layout
        end
      end
    end
  end
end
