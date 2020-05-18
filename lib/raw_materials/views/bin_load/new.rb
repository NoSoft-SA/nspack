# frozen_string_literal: true

module RawMaterials
  module Dispatch
    module BinLoad
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:bin_load, :new, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.action '/raw_materials/dispatch/bin_loads'
              form.remote! if remote
              form.add_field :bin_load_purpose_id
              form.add_field :customer_party_role_id
              form.add_field :transporter_party_role_id
              form.add_field :dest_depot_id
              form.add_field :qty_bins
            end
          end

          layout
        end
      end
    end
  end
end
