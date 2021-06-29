# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestVehicleTypePermission < Minitest::Test
    include Crossbeams::Responses

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        vehicle_type_code: Faker::Lorem.unique.word,
        description: 'ABC',
        has_container: false,
        active: true
      }
      MasterfilesApp::VehicleType.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::VehicleType.call(:create)
      assert res.success, 'Should always be able to create a vehicle_type'
    end

    def test_edit
      MasterfilesApp::VehicleTypeRepo.any_instance.stubs(:find_vehicle_type).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::VehicleType.call(:edit, 1)
      assert res.success, 'Should be able to edit a vehicle_type'
    end

    def test_delete
      MasterfilesApp::VehicleTypeRepo.any_instance.stubs(:find_vehicle_type).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::VehicleType.call(:delete, 1)
      assert res.success, 'Should be able to delete a vehicle_type'
    end
  end
end
