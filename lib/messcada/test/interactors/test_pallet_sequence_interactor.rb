# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MesscadaApp
  class TestPalletSequenceInteractor < MiniTestWithHooks
    # include MesscadaFactory
    include MasterfilesApp::PartyFactory
    include MasterfilesApp::FarmFactory
    include MasterfilesApp::CommodityFactory
    include MasterfilesApp::CalendarFactory
    include MasterfilesApp::CultivarFactory
    include MasterfilesApp::LocationFactory
    include MasterfilesApp::PackagingFactory
    include MasterfilesApp::FruitFactory
    include MasterfilesApp::TargetMarketFactory
    include MasterfilesApp::MarketingFactory
    include MasterfilesApp::GeneralFactory
    include ProductionApp::ResourceFactory
    include ProductionApp::ProductionRunFactory
    include ProductionApp::ProductSetupFactory
    include RawMaterialsApp::RmtBinFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MesscadaApp::MesscadaRepo)
    end

    # def test_pallet_sequence
    #   MesscadaApp::MesscadaRepo.any_instance.stubs(:find_pallet_sequence).returns(fake_pallet_sequence)
    #   entity = interactor.send(:pallet_sequence, 1)
    #   assert entity.is_a?(PalletSequence)
    # end

    # def test_pallet_sequence_flat
    #   MesscadaApp::MesscadaRepo.any_instance.stubs(:find_pallet_sequence_flat).returns(fake_pallet_sequence)
    #   entity = interactor.send(:pallet_sequence_flat, 1)
    #   assert entity.is_a?(PalletSequenceFlat)
    # end

    # def test_create_pallet_sequence
    #   attrs = fake_pallet_sequence.to_h.reject { |k, _| k == :id }
    #   res = interactor.create_pallet_sequence(attrs)
    #   assert res.success, "#{res.message} : #{res.errors.inspect}"
    #   assert_instance_of(PalletSequence, res.instance)
    #   assert res.instance.id.nonzero?
    # end
    #
    # def test_create_pallet_sequence_fail
    #   attrs = fake_pallet_sequence(pallet_number: nil).to_h.reject { |k, _| k == :id }
    #   res = interactor.create_pallet_sequence(attrs)
    #   refute res.success, 'should fail validation'
    #   assert_equal ['must be filled'], res.errors[:pallet_number]
    # end
    #
    # def test_update_pallet_sequence
    #   id = create_pallet_sequence
    #   attrs = interactor.send(:repo).find_hash(:pallet_sequences, id).reject { |k, _| k == :id }
    #   value = attrs[:pallet_number]
    #   attrs[:pallet_number] = 'a_change'
    #   res = interactor.update_pallet_sequence(id, attrs)
    #   assert res.success, "#{res.message} : #{res.errors.inspect}"
    #   assert_instance_of(PalletSequence, res.instance)
    #   assert_equal 'a_change', res.instance.pallet_number
    #   refute_equal value, res.instance.pallet_number
    # end
    #
    # def test_update_pallet_sequence_fail
    #   id = create_pallet_sequence
    #   attrs = interactor.send(:repo).find_hash(:pallet_sequences, id).reject { |k, _| %i[id pallet_number].include?(k) }
    #   res = interactor.update_pallet_sequence(id, attrs)
    #   refute res.success, "#{res.message} : #{res.errors.inspect}"
    #   assert_equal ['is missing'], res.errors[:pallet_number]
    # end
    #
    # def test_delete_pallet_sequence
    #   id = create_pallet_sequence
    #   assert_count_changed(:pallet_sequences, -1) do
    #     res = interactor.delete_pallet_sequence(id)
    #     assert res.success, res.message
    #   end
    # end

    private

    def pallet_sequence_attrs
      # pallet_id = create_pallet
      production_run_id = create_production_run
      farm_id = create_farm
      puc_id = create_puc
      orchard_id = create_orchard
      cultivar_group_id = create_cultivar_group
      cultivar_id = create_cultivar
      product_resource_allocation_id = create_product_resource_allocation
      packhouse_resource_id = create_plant_resource
      production_line_id = create_plant_resource
      season_id = create_season
      marketing_variety_id = create_marketing_variety
      customer_variety_id = create_customer_variety
      std_fruit_size_count_id = create_std_fruit_size_count
      basic_pack_id = create_basic_pack
      standard_pack_id = create_standard_pack
      fruit_actual_counts_for_pack_id = create_fruit_actual_counts_for_pack
      fruit_size_reference_id = create_fruit_size_reference
      party_role_id = create_party_role
      target_market_group_id = create_target_market_group
      mark_id = create_mark
      inventory_code_id = create_inventory_code
      pallet_format_id = create_pallet_format
      cartons_per_pallet_id = create_cartons_per_pallet
      pm_bom_id = create_pm_bom
      pm_type_id = create_pm_type
      pm_subtype_id = create_pm_subtype
      carton_id = create_carton
      pallet_verification_failure_reason_id = create_pallet_verification_failure_reason
      personnel_identifier_id = create_personnel_identifier
      contract_worker_id = create_contract_worker
      target_market_id = create_target_market
      pm_mark_id = create_pm_mark
      registered_orchard_id = create_registered_orchard
      target_customer_party_role_id = create_party_role(party_type: 'O', name: AppConst::ROLE_TARGET_CUSTOMER)

      {
        id: 1,
        pallet_id: 1,
        pallet_number: Faker::Lorem.unique.word,
        pallet_sequence_number: 1,
        production_run_id: production_run_id,
        farm_id: farm_id,
        puc_id: puc_id,
        orchard_id: orchard_id,
        cultivar_group_id: cultivar_group_id,
        cultivar_id: cultivar_id,
        product_resource_allocation_id: product_resource_allocation_id,
        packhouse_resource_id: packhouse_resource_id,
        production_line_id: production_line_id,
        season_id: season_id,
        marketing_variety_id: marketing_variety_id,
        customer_variety_id: customer_variety_id,
        std_fruit_size_count_id: std_fruit_size_count_id,
        basic_pack_code_id: basic_pack_id,
        standard_pack_code_id: standard_pack_id,
        fruit_actual_counts_for_pack_id: fruit_actual_counts_for_pack_id,
        fruit_size_reference_id: fruit_size_reference_id,
        marketing_org_party_role_id: party_role_id,
        packed_tm_group_id: target_market_group_id,
        mark_id: mark_id,
        inventory_code_id: inventory_code_id,
        pallet_format_id: pallet_format_id,
        cartons_per_pallet_id: cartons_per_pallet_id,
        pm_bom_id: pm_bom_id,
        extended_columns: {},
        client_size_reference: 'ABC',
        client_product_code: 'ABC',
        treatment_ids: [1, 2, 3],
        marketing_order_number: 'ABC',
        pm_type_id: pm_type_id,
        pm_subtype_id: pm_subtype_id,
        carton_quantity: 1,
        scanned_from_carton_id: carton_id,
        exit_ref: 'ABC',
        scrapped_at: '2010-01-01 12:00',
        verification_result: 'ABC',
        pallet_verification_failure_reason_id: pallet_verification_failure_reason_id,
        verified_at: '2010-01-01 12:00',
        nett_weight: 1.0,
        verified: false,
        verification_passed: false,
        pick_ref: 'ABC',
        grade_id: 1,
        scrapped_from_pallet_id: 1,
        removed_from_pallet: false,
        removed_from_pallet_id: 1,
        removed_from_pallet_at: '2010-01-01 12:00',
        sell_by_code: 'ABC',
        product_chars: 'ABC',
        depot_pallet: false,
        personnel_identifier_id: personnel_identifier_id,
        contract_worker_id: contract_worker_id,
        failed_otmc_results: [1, 2, 3],
        phyto_data: 'ABC',
        repacked_at: '2010-01-01 12:00',
        repacked_from_pallet_id: 1,
        created_by: 'ABC',
        verified_by: 'ABC',
        target_market_id: target_market_id,
        pm_mark_id: pm_mark_id,
        marketing_puc_id: 1,
        marketing_orchard_id: registered_orchard_id,
        gtin_code: 'ABC',
        legacy_data: {},
        rmt_class_id: 1,
        packing_specification_item_id: 1,
        tu_labour_product_id: 1,
        ru_labour_product_id: 1,
        fruit_sticker_ids: [1, 2, 3],
        tu_sticker_ids: [1, 2, 3],
        target_customer_party_role_id: target_customer_party_role_id,
        active: true
      }
    end

    def fake_pallet_sequence(overrides = {})
      PalletSequence.new(pallet_sequence_attrs.merge(overrides))
    end

    def fake_pallet_sequence_flat(overrides = {})
      PalletSequenceFlat.new(pallet_sequence_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= MesscadaInteractor.new(current_user, {}, {}, {})
    end
  end
end
