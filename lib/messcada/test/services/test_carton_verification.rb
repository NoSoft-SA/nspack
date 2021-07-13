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
      start_pallets = DB[:pallets].count

      scanned_number = carton_label_id
      res = MesscadaApp::CartonVerification.call(current_user, { carton_number: scanned_number })
      assert res.success, 'Should be able to verify carton'

      res = MesscadaApp::CartonVerification.call(current_user, { carton_number: scanned_number })
      assert res.success, 'Revalidation should return success'

      end_pallets = DB[:pallets].count
      assert_equal start_pallets, end_pallets, "Carton verification should not create a pallet: was #{start_pallets}, now: #{end_pallets}"
    end

    def test_carton_verification_scan_carton_label_and_create_pallet
      carton_label_id = create_carton_label(carton_equals_pallet: true)
      start_pallets = DB[:pallets].count
      scanned_number = carton_label_id

      res = MesscadaApp::CartonVerification.call(current_user, { carton_number: scanned_number })
      assert res.success, 'Should be able to verify carton'

      end_pallets = DB[:pallets].count
      assert_equal start_pallets + 1, end_pallets, "Carton verification should create one pallet: was #{start_pallets}, now: #{end_pallets}"
    end

    def test_carton_verification_scan_pallet
      pallet_id = create_pallet
      pallet_number = DB[:pallets].where(id: pallet_id).get(:pallet_number)

      create_carton_label(pallet_number: pallet_number)

      scanned_number = pallet_number
      res = MesscadaApp::CartonVerification.call(current_user, { carton_number: scanned_number })
      assert res.success, 'Should be able to verify pallet'

      res = MesscadaApp::CartonVerification.call(current_user, { carton_number: scanned_number })
      assert res.success, 'Revalidation should return success'
    end

    def test_carton_verification_scan_pallet_fail
      pallet_id = create_pallet
      pallet_number = DB[:pallets].where(id: pallet_id).get(:pallet_number)

      scanned_number = pallet_number
      res = MesscadaApp::CartonVerification.call(current_user, { carton_number: scanned_number })
      refute res.success, 'Should not be able to verify pallet, pallet number not on carton label'
    end
  end
end
