# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestGovtInspectionPalletPermission < Minitest::Test
    include Crossbeams::Responses

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        pallet_id: 1,
        govt_inspection_sheet_id: 1,
        passed: false,
        inspected: false,
        inspected_at: '2010-01-01 12:00',
        failure_reason_id: 1,
        failure_remarks: Faker::Lorem.unique.word,
        active: true
      }
      FinishedGoodsApp::GovtInspectionPallet.new(base_attrs.merge(attrs))
    end

    def test_create
      res = FinishedGoodsApp::TaskPermissionCheck::GovtInspectionPallet.call(:create)
      assert res.success, 'Should always be able to create a govt_inspection_pallet'
    end

    def test_edit
      FinishedGoodsApp::GovtInspectionRepo.any_instance.stubs(:find_govt_inspection_pallet).returns(entity)
      res = FinishedGoodsApp::TaskPermissionCheck::GovtInspectionPallet.call(:edit, 1)
      assert res.success, 'Should be able to edit a govt_inspection_pallet'
    end

    def test_delete
      FinishedGoodsApp::GovtInspectionRepo.any_instance.stubs(:find_govt_inspection_pallet).returns(entity)
      res = FinishedGoodsApp::TaskPermissionCheck::GovtInspectionPallet.call(:delete, 1)
      assert res.success, 'Should be able to delete a govt_inspection_pallet'
    end
  end
end
