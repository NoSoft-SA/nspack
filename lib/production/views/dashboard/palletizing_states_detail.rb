# frozen_string_literal: true

module Production
  module Dashboards
    module Dashboard
      class PalletizingStatesDetail
        def self.call
          layout = Crossbeams::Layout::Page.build({}) do |page|
            page.add_text draw_boxes
          end

          layout
        end

        def self.draw_boxes
          recs = ProductionApp::DashboardRepo.new.palletizing_bay_states
          <<~HTML
            <div class="flex flex-wrap pa3 bg-mid-gray">
              #{pbay_items(recs).join("\n")}
            </div>
          HTML
        end
        # UPDATE palletizing_bay_states SET palletizing_bay_resource_id = (
        #   SELECT p.id FROM tree_plant_resources t
        # 	JOIN plant_resources p ON p.id = t.descendant_plant_resource_id
        # 	WHERE t.ancestor_plant_resource_id = (SELECT id FROM plant_resources WHERE system_resource_id = (
        # 		SELECT id FROM system_resources WHERE system_resource_code = palletizing_bay_states.palletizing_robot_code
        # 	))
        # 	AND t.path_length = 1
        # 	ORDER BY id LIMIT 1
        # )
        # WHERE scanner_code = '1'
        #   AND palletizing_bay_resource_id IS NULL;
        #
        # UPDATE palletizing_bay_states SET palletizing_bay_resource_id = (
        #   SELECT p.id FROM tree_plant_resources t
        # 	JOIN plant_resources p ON p.id = t.descendant_plant_resource_id
        # 	WHERE t.ancestor_plant_resource_id = (SELECT id FROM plant_resources WHERE system_resource_id = (
        # 		SELECT id FROM system_resources WHERE system_resource_code = palletizing_bay_states.palletizing_robot_code
        # 	))
        # 	AND t.path_length = 1
        # 	ORDER BY id DESC LIMIT 1
        # )
        # WHERE scanner_code = '2'
        #   AND palletizing_bay_resource_id IS NULL;

        def self.pbay_items(recs) # rubocop:disable Metrics/AbcSize
          recs.map do |rec|
            # code = rec[:plant_resource_code] || "#{rec[:palletizing_robot_code]} - #{rec[:scanner_code]}"
            code = rec[:description] || "#{rec[:palletizing_robot_code]} - #{rec[:scanner_code]}"
            if rec[:current_state] == 'empty'
              <<~HTML
                <div class="outline pa2 mr3 mt2 bg-white" style="min-width:230px">
                  <p class="fw6 f4 mt0 pb1 bb">#{code}</p>
                  <div class="fw6 tc pa2 mid-gray " style="background-color:#e6f4f1"><span class="f2">EMPTY</span><br>&nbsp;</div>
                  <p class="mt5">Last used: <span class="fw7">#{rec[:updated_at].strftime('%d %b %H:%M')}</span></p>
                </div>
              HTML
            elsif rec[:current_state] == 'return_to_bay'
              <<~HTML
                <div class="outline pa2 mr3 mt2 bg-white" style="min-width:230px">
                  <p class="fw6 f4 mt0 pb1 bb">#{code}</p>
                  <div class="fw6 tc pa2 mid-gray " style="background-color:#e6f4f1"><span class="f2">RTB</span><br>&nbsp;</div>
                  <p class="mt5">Last used: <span class="fw7">#{rec[:updated_at].strftime('%d %b %H:%M')}</span></p>
                </div>
              HTML
            else
              <<~HTML
                <div class="outline pa2 mr3 mt2 bg-white" style="min-width:230px">
                  <p class="fw6 f4 mt0 pb1 bb">#{code}</p>
                  <div class="tc pa2" style="background: linear-gradient(90deg, #8ABDEA #{rec[:percentage].to_i}%, #e6f4f1 #{rec[:percentage].to_i}%);">
                    <span class="fw6 f2 mid-gray ">#{rec[:percentage].to_i}%</span><br>
                  <table style="width:100%"><tr><td>#{rec[:pallet_qty] || 0} cartons</td><td>#{rec[:cartons_per_pallet] || 0} cpp</td></tr></table></div>
                  <p class="fw7 tc">#{rec[:pallet_number]}</p>
                  <p><table class="thinbordertable" style="width:100%"><tr><td>#{rec[:commodity]}</td><td>#{rec[:variety]}</td><td>#{rec[:size]}</td></tr></table></p>
                  <p>#{rec[:palletizer]}</p>
                </div>
              HTML
            end
          end
        end
      end
    end
  end
end
