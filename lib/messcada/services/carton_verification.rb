# frozen_string_literal: true

module MesscadaApp
  class CartonVerification < BaseService # rubocop:disable Metrics/ClassLength
    attr_reader :repo, :hr_repo, :carton_quantity, :resource_code,
                :user, :palletizer_identifier, :palletizing_bay_resource_id,
                :scanned_number, :scanned_params, :carton_equals_pallet

    def initialize(user, params, palletizer_identifier = nil, palletizing_bay_resource_id = nil)
      @scanned_number = params[:carton_number]
      @resource_code = params[:device]
      @user = user
      @palletizer_identifier = palletizer_identifier
      @palletizing_bay_resource_id = palletizing_bay_resource_id
      @repo = MesscadaApp::MesscadaRepo.new
      @hr_repo = MesscadaApp::HrRepo.new
      @carton_quantity = 1
    end

    def call # rubocop:disable Metrics/AbcSize
      return failed_response('scanned number not given') if scanned_number.nil_or_empty?

      @scanned_params = resolve_scanned_number_params
      @carton_equals_pallet = find_carton_label_carton_equals_pallet
      return success_response("#{scanned_params[:scanned_type]} : #{scanned_number} already verified") if already_verified? && pallet_ok?

      res = carton_verification
      raise Crossbeams::InfoError, unwrap_failed_response(res) unless res.success

      success_response("Successfully verified #{scanned_params[:scanned_type]}: #{scanned_number}")
    end

    private

    def find_carton_label_carton_equals_pallet
      repo.carton_label_carton_equals_pallet(scanned_params[:carton_label_id])
    end

    def resolve_scanned_number_params
      args = repo.parse_pallet_or_carton_number({ scanned_number: scanned_number.to_s })
      if args[:carton_number]
        args[:carton_label_id] = scanned_number
        args[:pallet_number] = find_carton_label_pallet_number(args[:carton_label_id])
        args[:scanned_type] = 'Carton Label'
        args[:carton_label_scanned] = true
      else
        args[:carton_label_id] = repo.carton_label_id_for_pallet_no(scanned_number)
        args[:pallet_number] = scanned_number.to_s
        args[:scanned_type] = 'Pallet'
        args[:carton_label_scanned] = false
      end

      args
    end

    def find_carton_label_pallet_number(carton_label_id)
      pallet_sequence_id = repo.carton_label_carton_palletizing_sequence(carton_label_id)
      pallet_sequence_id ||= repo.carton_label_scanned_from_carton_sequence(carton_label_id)

      repo.get(:pallet_sequences, pallet_sequence_id, :pallet_number)
    end

    def already_verified?
      carton_exists?
    end

    def pallet_ok?
      return true unless carton_equals_pallet

      pallet_exists?
    end

    def pallet_exists?
      repo.pallet_exists?(scanned_params[:pallet_number])
    end

    def carton_verification
      repo.transaction do
        create_carton unless carton_exists?
        carton_id = find_carton_label_carton

        CreateCartonEqualsPalletPallet.call(user, { carton_id: carton_id, carton_quantity: carton_quantity, carton_equals_pallet: carton_equals_pallet }, palletizing_bay_resource_id) unless pallet_ok?
      end

      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def create_carton
      attrs = set_carton_params
      res = if scanned_params[:carton_label_scanned]
              CreateCartonFromScannedCartonLabel.call(scanned_number, attrs)
            else
              CreateCartonFromScannedPallet.call(scanned_number, attrs)
            end
      return res unless res.success

      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def set_carton_params
      unless palletizer_identifier.nil?
        palletizer_identifier_id = find_personnel_identifier_id
        palletizer_contract_worker_id = find_palletizer_contract_worker_id(palletizer_identifier_id)
      end
      { palletizer_identifier_id: palletizer_identifier_id,
        palletizer_contract_worker_id: palletizer_contract_worker_id,
        palletizing_bay_resource_id: palletizing_bay_resource_id }
    end

    def find_personnel_identifier_id
      hr_repo.personnel_identifier_id_from_device_identifier(palletizer_identifier)
    end

    def find_palletizer_contract_worker_id(palletizer_identifier_id)
      hr_repo.contract_worker_id_from_personnel_id(palletizer_identifier_id)
    end

    def carton_exists?
      if scanned_params[:carton_label_scanned]
        repo.exists?(:cartons, carton_label_id: scanned_number)
      else
        repo.pallet_number_carton_exists?(scanned_number.to_s)
      end
    end

    def find_carton_label_carton
      repo.carton_label_carton_id(scanned_params[:carton_label_id])
    end
  end
end
