# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestCustomerPermission < Minitest::Test
    include Crossbeams::Responses
    include FinanceFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        default_currency_id: 1,
        default_currency: 'ZAR',
        customer_party_role_id: 1,
        customer: 'ABC',
        active: true
      }
      MasterfilesApp::Customer.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::Customer.call(:create)
      assert res.success, 'Should always be able to create a customer'
    end

    def test_edit
      MasterfilesApp::FinanceRepo.any_instance.stubs(:find_customer).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::Customer.call(:edit, 1)
      assert res.success, 'Should be able to edit a customer'
    end

    def test_delete
      MasterfilesApp::FinanceRepo.any_instance.stubs(:find_customer).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::Customer.call(:delete, 1)
      assert res.success, 'Should be able to delete a customer'
    end
  end
end
