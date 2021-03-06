# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestCustomerPaymentTermPermission < Minitest::Test
    include Crossbeams::Responses

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        payment_term_id: 1,
        payment_term: 'ABC',
        customer_payment_term_set_id: 1,
        customer_payment_term_set: 'ABC',
        active: true
      }
      MasterfilesApp::CustomerPaymentTerm.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::CustomerPaymentTerm.call(:create)
      assert res.success, 'Should always be able to create a customer_payment_term'
    end

    def test_edit
      MasterfilesApp::FinanceRepo.any_instance.stubs(:find_customer_payment_term).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::CustomerPaymentTerm.call(:edit, 1)
      assert res.success, 'Should be able to edit a customer_payment_term'
    end

    def test_delete
      MasterfilesApp::FinanceRepo.any_instance.stubs(:find_customer_payment_term).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::CustomerPaymentTerm.call(:delete, 1)
      assert res.success, 'Should be able to delete a customer_payment_term'
    end
  end
end
