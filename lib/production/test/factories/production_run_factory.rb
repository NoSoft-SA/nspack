# frozen_string_literal: true

module ProductionApp
  module ProductionRunFactory
    def create_production_run(opts = {})
      id = get_available_factory_record(:production_runs, opts)
      return id unless id.nil?

      opts[:farm_id] ||= create_farm
      opts[:puc_id] ||= create_puc
      opts[:packhouse_resource_id] ||= create_plant_resource
      opts[:production_line_id] ||= create_plant_resource
      opts[:season_id] ||= create_season
      opts[:orchard_id] ||= create_orchard
      opts[:cultivar_group_id] ||= create_cultivar_group
      opts[:cultivar_id] ||= create_cultivar
      opts[:product_setup_template_id] ||= create_product_setup_template

      default = {
        cloned_from_run_id: nil,
        active_run_stage: Faker::Lorem.unique.word,
        started_at: '2010-01-01 12:00',
        closed_at: '2010-01-01 12:00',
        re_executed_at: '2010-01-01 12:00',
        completed_at: '2010-01-01 12:00',
        allow_cultivar_mixing: false,
        allow_orchard_mixing: false,
        reconfiguring: false,
        closed: false,
        setup_complete: false,
        completed: false,
        running: false,
        tipping: false,
        labeling: false,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        allow_cultivar_group_mixing: false
      }
      DB[:production_runs].insert(default.merge(opts))
    end

    def create_production_region(opts = {})
      default = {
        production_region_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:production_regions].insert(default.merge(opts))
    end

    def create_product_resource_allocation(opts = {})
      id = get_available_factory_record(:product_resource_allocations, opts)
      return id unless id.nil?

      opts[:production_run_id] ||= create_production_run
      opts[:product_setup_id]  ||= create_product_setup
      opts[:label_template_id] ||= create_label_template
      opts[:packing_method_id] ||= create_packing_method
      opts[:plant_resource_id] ||= create_plant_resource
      opts[:target_customer_party_role_id] ||= create_party_role(party_type: 'O', name: AppConst::ROLE_TARGET_CUSTOMER)

      default = {
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:product_resource_allocations].insert(default.merge(opts))
    end
  end
end
