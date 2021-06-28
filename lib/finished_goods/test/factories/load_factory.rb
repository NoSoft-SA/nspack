# frozen_string_literal: true

module FinishedGoodsApp
  module LoadFactory
    def create_load(opts = {}) # rubocop:disable Metrics/AbcSize
      id = get_available_factory_record(:loads, opts)
      return id unless id.nil?

      repo = BaseRepo.new

      if opts[:pol_voyage_port_id].nil? || opts[:pod_voyage_port_id].nil?
        pol_port_type_id = repo.get_id(:port_types, port_type_code: AppConst::PORT_TYPE_POL) || create_port_type(port_type_code: AppConst::PORT_TYPE_POL)
        pod_port_type_id = repo.get_id(:port_types, port_type_code: AppConst::PORT_TYPE_POD) || create_port_type(port_type_code: AppConst::PORT_TYPE_POD)
        voyage_id = create_voyage

        opts[:pol_voyage_port_id] = create_voyage_port(voyage_id: voyage_id, port_type_id: pol_port_type_id)
        opts[:pod_voyage_port_id] ||= create_voyage_port(voyage_id: voyage_id, port_type_id: pod_port_type_id)
      end

      opts[:customer_party_role_id] ||= create_party_role(party_type: 'O', name: AppConst::ROLE_INSPECTION_BILLING)
      opts[:consignee_party_role_id] ||= create_party_role(party_type: 'O', name: AppConst::ROLE_CONSIGNEE)
      opts[:billing_client_party_role_id] ||= create_party_role(party_type: 'O', name: AppConst::ROLE_BILLING_CLIENT)
      opts[:exporter_party_role_id] ||= create_party_role(party_type: 'O', name: AppConst::ROLE_EXPORTER)
      opts[:final_receiver_party_role_id] ||= create_party_role(party_type: 'O', name: AppConst::ROLE_FINAL_RECEIVER)
      opts[:final_destination_id] ||= create_destination_city
      opts[:depot_id] ||= create_depot

      default = {
        order_number: Faker::Lorem.unique.word,
        edi_file_name: Faker::Lorem.word,
        customer_order_number: Faker::Lorem.word,
        customer_reference: Faker::Lorem.word,
        exporter_certificate_code: Faker::Lorem.word,
        shipped_at: '2010-01-01',
        shipped: false,
        transfer_load: false,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:loads].insert(default.merge(opts))
    end

    def create_load_voyage(opts = {}) # rubocop:disable Metrics/AbcSize
      id = get_available_factory_record(:load_voyages, opts)
      return id unless id.nil?

      opts[:load_id] ||= create_load
      opts[:voyage_id] ||= create_voyage
      opts[:shipping_line_party_role_id] ||= create_party_role(party_type: 'O', name: AppConst::ROLE_SHIPPING_LINE)
      opts[:shipper_party_role_id] ||= create_party_role(party_type: 'O', name: AppConst::ROLE_SHIPPER)

      default = {
        booking_reference: Faker::Lorem.unique.word,
        memo_pad: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:load_voyages].insert(default.merge(opts))
    end

    def create_load_vehicle(opts = {}) # rubocop:disable Metrics/AbcSize
      id = get_available_factory_record(:load_vehicles, opts)
      return id unless id.nil?

      opts[:load_id] ||= create_load
      opts[:vehicle_type_id] ||= create_vehicle_type
      opts[:haulier_party_role_id] ||= create_party_role(party_type: 'O', name: AppConst::ROLE_HAULIER)

      default = {
        vehicle_number: Faker::Lorem.unique.word,
        vehicle_weight_out: Faker::Number.decimal,
        dispatch_consignment_note_number: Faker::Lorem.word,
        driver_name: Faker::Lorem.word,
        driver_cell_number: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:load_vehicles].insert(default.merge(opts))
    end

    def create_vehicle_type(opts = {})
      id = get_available_factory_record(:vehicle_types, opts)
      return id unless id.nil?

      default = {
        vehicle_type_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        has_container: false,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:vehicle_types].insert(default.merge(opts))
    end
  end
end
