# frozen_string_literal: true

module Masterfiles
  module Packaging
    module CartonsPerPallet
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:cartons_per_pallet, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Cartons Per Pallet'
              form.view_only!
              form.add_field :description
              form.add_field :pallet_format_id
              form.add_field :basic_pack_id
              form.add_field :cartons_per_pallet
              form.add_field :layers_per_pallet
              form.add_field :active
            end
          end

          layout
        end
      end
    end
  end
end
