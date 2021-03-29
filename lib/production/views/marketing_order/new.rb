# frozen_string_literal: true

module Production
  module Orders
    module MarketingOrder
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:marketing_order, :new, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Marketing Order'
              form.action '/production/orders/marketing_orders'
              form.remote! if remote
              form.add_field :customer_party_role_id
              form.add_field :season_id
              form.add_field :order_number
              form.add_field :order_reference
              form.add_field :carton_qty_required
              # form.add_field :carton_qty_produced
              # form.add_field :completed
              # form.add_field :completed_at
            end
          end

          layout
        end
      end
    end
  end
end
