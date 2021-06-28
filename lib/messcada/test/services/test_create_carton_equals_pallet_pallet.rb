# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MesscadaApp
  class TestCreateCartonEqualsPalletPallet < MiniTestWithHooks
    include Crossbeams::Responses
    include CartonFactory
    include PalletFactory
    include ProductionApp::ProductionRunFactory
    include ProductionApp::ResourceFactory
    include ProductionApp::ProductSetupFactory
    include MasterfilesApp::FarmFactory
    include MasterfilesApp::FruitFactory
    include MasterfilesApp::PartyFactory
    include MasterfilesApp::HRFactory
    include MasterfilesApp::LocationFactory
    include MasterfilesApp::CalendarFactory
    include MasterfilesApp::CommodityFactory
    include MasterfilesApp::CultivarFactory
    include MasterfilesApp::TargetMarketFactory
    include MasterfilesApp::GeneralFactory
    include MasterfilesApp::MarketingFactory
    include MasterfilesApp::PackagingFactory
    include RawMaterialsApp::RmtBinFactory
    include RawMaterialsApp::RmtDeliveryFactory
    include MasterfilesApp::RmtContainerFactory

    def test_create_pallet
      carton_label_id = create_carton_label(pallet_number: Faker::Number.number(digits: 9))
      params = { carton_id: create_carton(carton_label_id: carton_label_id) }
      params[:carton_quantity] = 1
      params[:carton_equals_pallet] = true

      res = MesscadaApp::CreateCartonEqualsPalletPallet.call(current_user, params)
      assert res.success, 'Should be able to create Pallet'
    end
  end
end
