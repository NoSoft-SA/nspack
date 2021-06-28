# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MesscadaApp
  class TestCreateCartonEqualsPalletPallet < Minitest::Test
    include Crossbeams::Responses
    include CartonLabelFactory
    include CartonFactory
    include ProductionApp::ProductionRunFactory
    include ProductionApp::ResourceFactory
    include ProductionApp::ProductSetupFactory
    include MasterfilesApp::FarmFactory
    include MasterfilesApp::FruitFactory
    include MasterfilesApp::PartyFactory
    include MasterfilesApp::CalendarFactory
    include MasterfilesApp::CommodityFactory
    include MasterfilesApp::CultivarFactory
    include MasterfilesApp::TargetMarketFactory
    include MasterfilesApp::GeneralFactory
    include MasterfilesApp::MarketingFactory
    # include MasterfilesApp::PackagingFactory

    def test_create_pallet
      carton_id = create_carton
      res = MesscadaApp::CreateCartonEqualsPalletPallet.call(user, carton_id)
      refute res.success, 'should fail validation'
    end

    def user
      OpenStruct.new(user_name: 'Test')
    end
  end
end
