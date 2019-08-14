# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestBOMsRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_pm_types
      assert_respond_to repo, :for_select_pm_subtypes
      assert_respond_to repo, :for_select_pm_products
      assert_respond_to repo, :for_select_units_of_measure
    end

    def test_crud_calls
      test_crud_calls_for :pm_types, name: :pm_type, wrapper: PmType
      test_crud_calls_for :pm_subtypes, name: :pm_subtype, wrapper: PmSubtype
      test_crud_calls_for :pm_products, name: :pm_product, wrapper: PmProduct
      test_crud_calls_for :units_of_measure, name: :units_of_measure, wrapper: UnitsOfMeasure
    end

    private

    def repo
      BOMsRepo.new
    end
  end
end
