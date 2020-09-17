# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
module FinishedGoods
  module Dispatch
    module Load
      class Show # rubocop:disable Metrics/ClassLength
        def self.call(id) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:load, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back',
                                  url: '/list/loads',
                                  style: :back_button)
              ui_rule.form_object.instance_controls.each do |control|
                section.add_control(control)
              end
              if ui_rule.form_object.allocated
                section.add_control(control_type: :link,
                                    text: 'Dispatch Note',
                                    url: "/finished_goods/reports/dispatch_note/#{id}",
                                    loading_window: true,
                                    style: :button)
                section.add_control(control_type: :link,
                                    text: 'Dispatch Note - Summarised',
                                    url: "/finished_goods/reports/dispatch_note_summarised/#{id}",
                                    loading_window: true,
                                    style: :button)
                section.add_control(control_type: :link,
                                    text: 'Dispatch Picklist',
                                    url: "/finished_goods/reports/picklist/#{id}",
                                    loading_window: true,
                                    style: :button)
                section.add_control(control_type: :link,
                                    text: 'Addendum',
                                    url: "/finished_goods/reports/addendum/#{id}",
                                    loading_window: true,
                                    style: :button)
                section.add_control(control_type: :link,
                                    text: 'Verified Gross Mass',
                                    url: "/finished_goods/reports/verified_gross_mass/#{id}",
                                    visible: ui_rule.form_object.container,
                                    loading_window: true,
                                    style: :button)
              end
            end
            page.form do |form|
              form.no_submit!
              form.fold_up do |fold|
                fold.caption 'Parties'
                fold.open!
                fold.row do |row|
                  row.column do |col|
                    col.add_field :customer_party_role_id
                    col.add_field :consignee_party_role_id
                    col.add_field :final_receiver_party_role_id
                  end
                  row.column do |col|
                    col.add_field :exporter_party_role_id
                    col.add_field :billing_client_party_role_id
                  end
                end
              end
              form.fold_up do |fold|
                fold.caption 'Load Details'
                fold.open!
                fold.row do |row|
                  row.column do |col|
                    col.add_field :id
                    col.add_field :load_id
                    col.add_field :order_number
                    col.add_field :customer_order_number
                    col.add_field :customer_reference
                    col.add_field :depot_id
                    col.add_field :rmt_load
                  end
                  row.column do |col|
                    col.add_field :status
                    col.add_field :exporter_certificate_code
                    col.add_field :edi_file_name
                    col.add_field :shipped_at
                    col.add_field :requires_temp_tail
                    col.add_field :temp_tail_pallet_number
                    col.add_field :temp_tail
                  end
                end
              end
              if ui_rule.form_object.edi
                form.fold_up do |fold|
                  fold.caption 'EDI'
                  fold.open!
                  fold.add_grid('load_edi',
                                "/list/load_edi/grid?key=standard&record_id=#{id}",
                                caption: 'EDI Transactions',
                                height: 8)
                end
              end
              form.fold_up do |fold|
                fold.caption 'Voyage Ports and Locations'
                fold.row do |row|
                  row.column do |col|
                    col.add_field :voyage_type_id
                    col.add_field :vessel_id
                    col.add_field :voyage_number
                    col.add_field :year
                    col.add_field :final_destination_id
                    col.add_field :transfer_load
                    col.add_control(control_type: :link,
                                    text: 'Go to Voyage',
                                    url: "/finished_goods/dispatch/voyages/#{ui_rule.form_object.voyage_id}",
                                    style: :action_button)
                  end
                  row.column do |col|
                    col.add_field :spacer
                    col.add_field :pol_port_id
                    col.add_field :eta
                    col.add_field :ata
                    col.add_field :pod_port_id
                    col.add_field :etd
                    col.add_field :atd
                  end
                end
              end
              form.fold_up do |fold|
                fold.caption 'Load Voyage'
                fold.row do |row|
                  row.column do |col|
                    col.add_field :shipping_line_party_role_id
                    col.add_field :shipper_party_role_id
                    col.add_field :booking_reference
                  end
                  row.column do |col|
                    col.add_field :memo_pad
                  end
                end
              end
              if ui_rule.form_object.vehicle
                form.fold_up do |fold|
                  fold.caption 'Load Vehicle - Truck Arrival'
                  fold.row do |row|
                    row.column do |col|
                      col.add_field :vehicle_number
                      col.add_field :driver
                      col.add_field :driver_number
                    end
                    row.column do |col|
                      col.add_field :vehicle_type
                      col.add_field :haulier
                      col.add_field :vehicle_weight_out
                    end
                  end
                end
              end
              if ui_rule.form_object.container
                form.fold_up do |fold|
                  fold.caption 'Load Container'
                  fold.row do |row|
                    row.column do |col|
                      col.add_field :container_code
                      col.add_field :container_vents
                      col.add_field :container_seal_code
                      col.add_field :internal_container_code
                      col.add_field :stack_type
                    end
                    row.column do |col|
                      col.add_field :temperature_rhine
                      col.add_field :temperature_rhine2
                      if AppConst::VGM_REQUIRED
                        col.add_field :max_payload
                        col.add_field :tare_weight
                        col.add_field :actual_payload
                      end
                      col.add_field :max_gross_weight
                      col.add_field :cargo_temperature
                      col.add_field :verified_gross_weight
                      col.add_field :verified_gross_weight_date
                    end
                  end
                end
              end
            end
            page.section do |section|
              section.add_progress_step ui_rule.form_object.steps, position: ui_rule.form_object.step
              section.show_border!
              ui_rule.form_object.progress_controls.each do |control|
                section.add_control(control)
              end
            end
            page.form do |form|
              form.action '/list/loads'
              form.submit_captions 'Close'
            end
            page.section do |section|
              section.add_grid('stock_pallets',
                               "/list/stock_pallets/grid?key=on_load&load_id=#{id}",
                               caption: 'Load Pallets',
                               height: 40)
            end
          end

          layout
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
