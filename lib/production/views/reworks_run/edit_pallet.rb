# frozen_string_literal: true

module Production
  module Reworks
    module ReworksRun
      class EditPallet
        def self.call(reworks_run_type_id, pallet_number, back_url:)
          ui_rule = UiRules::Compiler.new(:reworks_run_pallet, :edit_pallet, reworks_run_type_id: reworks_run_type_id, pallet_number: pallet_number)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back',
                                  url: back_url,
                                  style: :back_button)
            end
            page.add_text rules[:compact_header]
            page.section do |section|
              section.row do |row|
                row.column do |col|
                  col.add_control(control_type: :link,
                                  text: 'shipping details',
                                  url: "/production/reworks/pallets/#{pallet_number}/pallet_shipping_details",
                                  behaviour: :popup,
                                  style: :button,
                                  visible: rules[:show_shipping_details])
                  col.add_control(control_type: :link,
                                  text: 'Edit Pallet details',
                                  url: "/production/reworks/pallets/#{pallet_number}/edit_pallet_details",
                                  behaviour: :popup,
                                  style: :button)
                  col.add_control(control_type: :link,
                                  text: 'Print pallet label',
                                  url: "/production/reworks/pallets/#{pallet_number}/print_reworks_pallet_label",
                                  behaviour: :popup,
                                  style: :button)
                  col.add_control(control_type: :link,
                                  text: 'Set Gross Weight',
                                  url: "/production/reworks/pallets/#{pallet_number}/set_gross_weight",
                                  behaviour: :popup,
                                  style: :button)
                  unless rules[:has_individual_cartons]
                    col.add_control(control_type: :link,
                                    text: 'Edit Carton quantities',
                                    url: "/production/reworks/pallets/#{pallet_number}/edit_carton_quantities",
                                    style: :button)
                  end
                end
              end
            end
            page.section do |section|
              section.add_grid('pallet_sequences',
                               "/list/reworks_pallet_sequences/grid?key=pallet_number&pallet_number=#{pallet_number}",
                               caption: 'Pallet Sequences')
            end
          end

          layout
        end
      end
    end
  end
end
