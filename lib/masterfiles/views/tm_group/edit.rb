# frozen_string_literal: true

module Masterfiles
  module TargetMarkets
    module TmGroup
      class Edit
        def self.call(id, form_values = nil, form_errors = nil)
          ui_rule = UiRules::Compiler.new(:tm_group, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.action "/masterfiles/target_markets/target_market_groups/#{id}"
              form.remote!
              form.method :update
              form.add_field :target_market_group_type_id
              form.add_field :target_market_group_name
            end
          end

          layout
        end
      end
    end
  end
end
