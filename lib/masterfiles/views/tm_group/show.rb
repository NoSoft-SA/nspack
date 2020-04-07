# frozen_string_literal: true

module Masterfiles
  module TargetMarkets
    module TmGroup
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:tm_group, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              form.view_only!
              form.add_field :target_market_group_type_id
              form.add_field :target_market_group_name
              form.add_field :description
              form.add_field :regions
            end
          end

          layout
        end
      end
    end
  end
end
