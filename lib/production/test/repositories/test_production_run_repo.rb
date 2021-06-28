# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module ProductionApp
  class TestProductionRunRepo < MiniTestWithHooks
    include MasterfilesApp::PartyFactory
    include MasterfilesApp::CommodityFactory
    include MasterfilesApp::CultivarFactory
    include MasterfilesApp::FarmFactory
    include MasterfilesApp::CalendarFactory
    include MasterfilesApp::LocationFactory
    include ResourceFactory
    include ProductSetupFactory
    include ProductionRunFactory

    def test_crud_calls
      test_crud_calls_for :production_runs, name: :production_run, wrapper: ProductionRun
    end

    def test_create_production_run
      attrs = fake_production_run.to_h.reject { |k, _| k == :id }
      AppConst::TEST_SETTINGS.client_code = 'hl'
      id = repo.create_production_run(attrs)
      alloc = repo.get(:production_runs, id, :allocation_required)
      assert alloc

      skip 'Temporarily set HB to allow allocations to runs (for Citrus ph)'
      AppConst::TEST_SETTINGS.client_code = 'hb'
      id = repo.create_production_run(attrs)
      alloc = repo.get(:production_runs, id, :allocation_required)
      refute alloc
    ensure
      AppConst::TEST_SETTINGS.client_code = AppConst::TEST_SETTINGS.boot_client_code
    end

    private

    def production_run_attrs
      farm_id = create_farm
      puc_id = create_puc
      ph_resource_id = create_plant_resource
      line_resource_id = create_plant_resource
      season_id = create_season
      orchard_id = create_orchard
      cultivar_group_id = create_cultivar_group
      cultivar_id = create_cultivar
      product_setup_template_id = create_product_setup_template
      production_run_id = create_production_run

      {
        id: 1,
        farm_id: farm_id,
        puc_id: puc_id,
        packhouse_resource_id: ph_resource_id,
        production_line_id: line_resource_id,
        season_id: season_id,
        orchard_id: orchard_id,
        cultivar_group_id: cultivar_group_id,
        cultivar_id: cultivar_id,
        product_setup_template_id: product_setup_template_id,
        cloned_from_run_id: production_run_id,
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
        allow_cultivar_group_mixing: false,
        legacy_data: {},
        legacy_bintip_criteria: {}
      }
    end

    def fake_production_run(overrides = {})
      ProductionRun.new(production_run_attrs.merge(overrides))
    end

    def repo
      ProductionRunRepo.new
    end
  end
end
