# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestOrchardTestTypePermission < Minitest::Test
    include Crossbeams::Responses
    include OrchardTestTypeFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        test_type_code: Faker::Lorem.unique.word,
        description: 'ABC',
        applies_to_all_markets: false,
        applies_to_all_cultivars: false,
        applies_to_orchard: false,
        applies_to_orchard_set: false,
        allow_result_capturing: false,
        pallet_level_result: false,
        api_name: 'ABC',
        result_type: 'ABC',
        result_attributes: 'ABC',
        applicable_tm_group_ids: %w[1 2 3],
        applicable_cultivar_ids: %w[1 2 3],
        applicable_commodity_group_ids: %w[1 2 3],
        active: true
      }
      MasterfilesApp::OrchardTestType.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::OrchardTestType.call(:create)
      assert res.success, 'Should always be able to create a orchard_test_type'
    end

    def test_edit
      MasterfilesApp::OrchardTestRepo.any_instance.stubs(:find_orchard_test_type).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::OrchardTestType.call(:edit, 1)
      assert res.success, 'Should be able to edit a orchard_test_type'
    end

    def test_delete
      MasterfilesApp::OrchardTestRepo.any_instance.stubs(:find_orchard_test_type).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::OrchardTestType.call(:delete, 1)
      assert res.success, 'Should be able to delete a orchard_test_type'
    end
  end
end
