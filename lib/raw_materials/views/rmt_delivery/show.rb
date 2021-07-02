# frozen_string_literal: true

module RawMaterials
  module Deliveries
    module RmtDelivery
      class Show
        def self.call(id, back_url:) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:rmt_delivery, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back',
                                  url: back_url,
                                  style: :back_button)

              section.add_control(control_type: :link,
                                  text: 'Print Bin Barcodes',
                                  url: "/raw_materials/deliveries/rmt_deliveries/#{id}/print_bin_barcodes",
                                  loading_window: true,
                                  style: :button)

              section.add_control(control_type: :link,
                                  text: 'Print Delivery',
                                  url: "/raw_materials/deliveries/rmt_deliveries/#{id}/print_delivery",
                                  loading_window: true,
                                  style: :button)

              section.form do |form|
                form.view_only!
                form.no_submit!
                form.row do |row|
                  row.column do |col|
                    col.add_field :id
                    col.add_field :season_id
                    col.add_field :farm_id
                    col.add_field :puc_id
                    col.add_field :orchard_id
                    col.add_field :farm_section
                    col.add_field :cultivar_id
                    col.add_field :rmt_delivery_destination_id
                    col.add_field :reference_number
                    col.add_field :truck_registration_number
                    col.add_field :qty_damaged_bins
                    col.add_field :qty_empty_bins
                    col.add_field :quantity_bins_with_fruit
                    col.add_field :bin_scan_mode
                  end

                  row.column do |col|
                    col.add_field :current
                    col.add_field :date_picked
                    col.add_field :received
                    col.add_field :date_delivered
                    col.add_field :delivery_tipped
                    col.add_field :tipping_complete_date_time
                    col.add_field :keep_open
                    col.add_field :active
                    col.add_field :batch_number
                    col.add_field :batch_number_updated_at
                  end
                end
              end
            end
            if ui_rule.form_object.keep_open
              page.section do |section|
                bin_type = nil
                if ui_rule.form_object.bin_scan_mode == AppConst::AUTO_ALLOCATE_BIN_NUMBERS
                  section.add_control(control_type: :link,
                                      text: 'Create Bin Groups(Auto Allocate)',
                                      url: "/raw_materials/deliveries/rmt_deliveries/#{id}/rmt_bins/create_bin_groups",
                                      style: :button,
                                      grid_id: 'rmt_bins_deliveries',
                                      behaviour: :popup)
                  bin_type = 'asset_number_'
                elsif ui_rule.form_object.bin_scan_mode == AppConst::SCAN_BIN_GROUPS
                  section.add_control(control_type: :link,
                                      text: 'Scan Bin Groups',
                                      url: "/raw_materials/deliveries/rmt_deliveries/#{id}/rmt_bins/create_scanned_bin_groups",
                                      style: :button,
                                      grid_id: 'rmt_bins_deliveries',
                                      behaviour: :popup)
                  bin_type = 'asset_number_'
                elsif ui_rule.form_object.bin_scan_mode == AppConst::SCAN_BINS_INDIVIDUALLY
                  section.add_control(control_type: :link,
                                      text: 'New RMT Bin',
                                      url: "/rmd/rmt_deliveries/rmt_bins/#{id}/new_delivery_bin",
                                      style: :button,
                                      grid_id: 'rmt_bins_deliveries',
                                      behaviour: false)
                  bin_type = 'asset_number_'
                else
                  section.add_control(control_type: :link,
                                      text: 'New RMT Bin',
                                      url: "/raw_materials/deliveries/rmt_deliveries/#{id}/rmt_bins/new",
                                      style: :button,
                                      grid_id: 'rmt_bins_deliveries',
                                      behaviour: :popup)
                end
                section.add_grid('rmt_bins_deliveries',
                                 "/list/#{bin_type}rmt_bins/grid?key=standard&delivery_id=#{id}",
                                 caption: 'Bins')
              end
            else
              page.section do |section|
                section.add_grid('rmt_bins_deliveries',
                                 "/list/rmt_bins_deliveries/grid?key=standard&delivery_id=#{id}",
                                 caption: 'Bins')
              end
            end
          end
          layout
        end
      end
    end
  end
end
