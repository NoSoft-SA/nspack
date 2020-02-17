# frozen_string_literal: true

module Masterfiles
  module Quality
    module Inspector
      class Show
        def self.call(id) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:inspector, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Inspector'
              form.view_only!
              form.add_field :title
              form.add_field :first_name
              form.add_field :surname
              form.add_field :role_ids
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
