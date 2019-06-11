# frozen_string_literal: true

module Masterfiles
  module TargetMarkets
    module Country
      class New
        def self.call(parent_id, form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:country, :new, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.action "/masterfiles/target_markets/destination_regions/#{parent_id}/destination_countries"
              form.remote! if remote
              # form.add_field :destination_region_id
              form.add_field :country_name
            end
          end

          layout
        end
      end
    end
  end
end
