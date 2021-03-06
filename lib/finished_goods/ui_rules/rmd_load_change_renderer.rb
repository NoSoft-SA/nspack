# frozen_string_literal: true

module UiRules
  class RmdLoadChangeRenderer < BaseChangeRenderer
    def change_container_use # rubocop:disable Metrics/AbcSize
      container = options[:use_container]
      actions = {}
      actions[:set_checked] = [{ dom_id: 'truck_arrival_container', checked: container }]
      # hides show if container
      row_ids = %w[container_info_section
                   truck_arrival_container_code_row
                   truck_arrival_container_vents_row
                   truck_arrival_container_seal_code_row
                   truck_arrival_container_temperature_rhine_row
                   truck_arrival_container_temperature_rhine2_row
                   truck_arrival_max_gross_weight_row
                   truck_arrival_cargo_temperature_id_row
                   truck_arrival_stack_type_id_row]
      if AppConst::CR_FG.verified_gross_mass_required_for_loads?
        row_ids << 'truck_arrival_tare_weight_row'
        row_ids << 'truck_arrival_max_payload_row'
        row_ids << 'truck_arrival_actual_payload_row'
      end
      actions[container ? :show_element : :hide_element] = row_ids.map { |a| { dom_id: a } }

      # test delete flash warning
      container_id = BaseRepo.new.get_id(:load_containers, load_id: options[:load_id])
      unless container_id.nil?
        if container
          actions[:hide_element] = [{ dom_id: 'rmd-error' }]
          actions[:replace_inner_html] = [{ dom_id: 'rmd-error', value: '' }]
        else
          actions[:show_element] = [{ dom_id: 'rmd-error' }]
          actions[:replace_inner_html] = [{ dom_id: 'rmd-error', value: 'Container info will be lost' }]
        end
      end

      # set_required
      req_ids = %w[truck_arrival_container_code
                   truck_arrival_container_temperature_rhine
                   truck_arrival_max_gross_weight
                   truck_arrival_cargo_temperature_id
                   truck_arrival_stack_type_id]
      if AppConst::CR_FG.verified_gross_mass_required_for_loads?
        req_ids << 'truck_arrival_tare_weight'
        req_ids << 'truck_arrival_max_payload'
        req_ids << 'truck_arrival_actual_payload'
      end
      actions[:set_required] = req_ids.map { |a| { dom_id: a, required: container } }
      build_actions(actions)
    end
  end
end
