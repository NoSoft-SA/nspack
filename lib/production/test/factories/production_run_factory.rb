# frozen_string_literal: true

module ProductionApp
  module ProductionRunFactory
    def create_production_run(opts = {}) # rubocop:disable Metrics/AbcSize
      farm_id = create_farm
      puc_id = create_puc
      ph_resource_id = create_plant_resource
      line_resource_id = create_plant_resource
      season_id = create_season
      orchard_id = create_orchard
      cultivar_group_id = create_cultivar_group
      cultivar_id = create_cultivar
      product_setup_template_id = create_product_setup_template

      default = {
        farm_id: farm_id,
        puc_id: puc_id,
        packhouse_resource_id: ph_resource_id,
        production_line_id: line_resource_id,
        season_id: season_id,
        orchard_id: orchard_id,
        cultivar_group_id: cultivar_group_id,
        cultivar_id: cultivar_id,
        product_setup_template_id: product_setup_template_id,
        cloned_from_run_id: opts[:cloned_run_id],
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
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
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
  end
end
