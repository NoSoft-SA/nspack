# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MesscadaApp
  class TestCartonVerification < MiniTestWithHooks
    include Crossbeams::Responses
    include CartonFactory
    include PalletFactory
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
    include MasterfilesApp::PackagingFactory
    include MasterfilesApp::HRFactory
    include MasterfilesApp::LocationFactory
    include MasterfilesApp::DepotFactory
    include MasterfilesApp::VesselFactory
    include MasterfilesApp::PortFactory
    include MasterfilesApp::QualityFactory
    include MasterfilesApp::RmtContainerFactory
    include RawMaterialsApp::RmtBinFactory
    include RawMaterialsApp::RmtDeliveryFactory
    include FinishedGoodsApp::LoadFactory
    include FinishedGoodsApp::VoyageFactory

    def test_carton_verification_scan_carton_label
      carton_label_id = create_carton_label

      params = { carton_number: carton_label_id }
      res = MesscadaApp::CartonVerification.call(user, params)
      assert res.success, 'Should be able to verify carton'

      res = MesscadaApp::CartonVerification.call(user, params)
      assert res.success, 'Revalidation should return success'
      # p res
      # p DB[:cartons].where(carton_label_id: carton_label_id).all
    end

    def test_carton_verification_scan_pallet
      pallet_id = create_pallet
      pallet_number = DB[:pallets].where(id: pallet_id).get(:pallet_number)
      # p pallet_number
      params = { carton_number: pallet_number }
      res = MesscadaApp::CartonVerification.call(user, params)
      assert res.success, 'Should be able to verify pallet'

      res = MesscadaApp::CartonVerification.call(user, params)
      assert res.success, 'Revalidation should return success'

      # p res
      # p DB[:pallets].where(id: pallet_id).all
    end

    def user
      OpenStruct.new(user_name: 'Test')
    end
  end
end
