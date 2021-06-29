# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestVehicleTypeInteractor < MiniTestWithHooks
    include FinishedGoodsApp::LoadFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::VehicleTypeRepo)
    end

    def test_vehicle_type
      MasterfilesApp::VehicleTypeRepo.any_instance.stubs(:find_vehicle_type).returns(fake_vehicle_type)
      entity = interactor.send(:vehicle_type, 1)
      assert entity.is_a?(VehicleType)
    end

    def test_create_vehicle_type
      attrs = fake_vehicle_type.to_h.reject { |k, _| k == :id }
      res = interactor.create_vehicle_type(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(VehicleType, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_vehicle_type_fail
      attrs = fake_vehicle_type(vehicle_type_code: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_vehicle_type(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:vehicle_type_code]
    end

    def test_update_vehicle_type
      id = create_vehicle_type
      attrs = interactor.send(:repo).find_hash(:vehicle_types, id).reject { |k, _| k == :id }
      value = attrs[:vehicle_type_code]
      attrs[:vehicle_type_code] = 'a_change'
      res = interactor.update_vehicle_type(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(VehicleType, res.instance)
      assert_equal 'a_change', res.instance.vehicle_type_code
      refute_equal value, res.instance.vehicle_type_code
    end

    def test_update_vehicle_type_fail
      id = create_vehicle_type
      attrs = interactor.send(:repo).find_hash(:vehicle_types, id).reject { |k, _| %i[id vehicle_type_code].include?(k) }
      res = interactor.update_vehicle_type(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:vehicle_type_code]
    end

    def test_delete_vehicle_type
      id = create_vehicle_type
      assert_count_changed(:vehicle_types, -1) do
        res = interactor.delete_vehicle_type(id)
        assert res.success, res.message
      end
    end

    private

    def vehicle_type_attrs
      {
        id: 1,
        vehicle_type_code: Faker::Lorem.unique.word,
        description: 'ABC',
        has_container: false,
        active: true
      }
    end

    def fake_vehicle_type(overrides = {})
      VehicleType.new(vehicle_type_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= VehicleTypeInteractor.new(current_user, {}, {}, {})
    end
  end
end
