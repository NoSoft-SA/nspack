# frozen_string_literal: true

module FinishedGoodsApp
  class CreateLoadService < BaseService
    def initialize(params)
      @params = params
    end

    def call  # rubocop:disable Metrics/AbcSize
      # FIND OR CREATE VOYAGE
      voyage_attrs = @params.slice(:voyage_type_id,
                                   :vessel_id,
                                   :voyage_number,
                                   :year)
      voyage_id = VoyageRepo.new.find_or_create_voyage(voyage_attrs)

      # CREATE LOAD
      load_attrs = @params.slice(:customer_party_role_id,
                                 :exporter_party_role_id,
                                 :billing_client_party_role_id,
                                 :consignee_party_role_id,
                                 :final_receiver_party_role_id,
                                 :order_number,
                                 :customer_order_number,
                                 :customer_reference,
                                 :depot_id,
                                 :exporter_certificate_code,
                                 :final_destination_id,
                                 :transfer_load)
      load_attrs[:pol_voyage_port_id] = VoyagePortRepo.new.find_or_create_voyage_port(voyage_id: voyage_id, port_id: @params[:pol_port_id])
      load_attrs[:pod_voyage_port_id] = VoyagePortRepo.new.find_or_create_voyage_port(voyage_id: voyage_id, port_id: @params[:pod_port_id])
      load_id = repo.create_load(load_attrs)
      repo.log_status('loads', load_id, 'CREATED')

      # CREATE LOAD_VOYAGE
      load_voyage_attrs = @params.slice(:shipping_line_party_role_id,
                                        :shipper_party_role_id,
                                        :booking_reference,
                                        :memo_pad)
      load_voyage_attrs[:load_id] = load_id
      load_voyage_attrs[:voyage_id] = voyage_id
      load_voyages_id = LoadVoyageRepo.new.create_load_voyage(load_voyage_attrs)
      repo.log_status('load_voyages', load_voyages_id, 'CREATED')

      success_response('ok', load_id)
    end

    private

    def repo
      @repo ||= LoadRepo.new
    end
  end
end
