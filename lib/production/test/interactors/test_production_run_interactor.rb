# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module ProductionApp
  class TestProductionRunInteractor < MiniTestWithHooks
    include MasterfilesApp::PartyFactory
    include MasterfilesApp::CommodityFactory
    include MasterfilesApp::CultivarFactory
    include MasterfilesApp::FarmFactory
    include MasterfilesApp::CalendarFactory
    include MasterfilesApp::LocationFactory
    include ResourceFactory
    include ProductSetupFactory
    include ProductionRunFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(ProductionApp::ProductionRunRepo)
    end

    def test_production_run
      ProductionApp::ProductionRunRepo.any_instance.stubs(:find_production_run).returns(fake_production_run)
      entity = interactor.send(:production_run, 1)
      assert entity.is_a?(ProductionRun)
    end

    def test_create_production_run
      attrs = fake_production_run.to_h.reject { |k, _| k == :id }
      res = interactor.create_production_run(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(ProductionRunFlat, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_production_run_fail
      attrs = fake_production_run(season_id: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_production_run(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:season_id]
    end

    def test_update_production_run
      # Make template null to bypass template validation
      id = create_production_run(product_setup_template_id: nil)
      attrs = interactor.send(:repo).find_hash(:production_runs, id).reject { |k, _| k == :id }
      value = attrs[:active_run_stage]
      attrs[:active_run_stage] = 'a_change'
      res = interactor.update_production_run(id, attrs)
      assert res.success, "#{res.message} : #{res.inspect}"
      assert_instance_of(ProductionRunFlat, res.instance)
      assert_equal 'a_change', res.instance.active_run_stage
      refute_equal value, res.instance.active_run_stage
    end

    def test_update_production_run_fail
      id = create_production_run
      attrs = interactor.send(:repo).find_hash(:production_runs, id).reject { |k, _| %i[id season_id].include?(k) }
      res = interactor.update_production_run(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:season_id]
    end

    def test_delete_production_run
      id = create_production_run
      assert_count_changed(:production_runs, -1) do
        res = interactor.delete_production_run(id)
        assert res.success, res.message
      end
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

    def interactor
      @interactor ||= ProductionRunInteractor.new(current_user, {}, {}, {})
    end
  end
end
