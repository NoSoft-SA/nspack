# frozen_string_literal: true

module MesscadaApp
  class CartonVerification < BaseService
    attr_reader :repo, :user, :scanned_number, :palletizer_identifier, :palletizing_bay_resource_id,
                :scanned, :carton_label_id, :carton_id, :pallet_sequence_id, :pallet_id, :pallet_number

    def initialize(user, scanned_number, palletizer_identifier = nil, palletizing_bay_resource_id = nil)
      @scanned_number = scanned_number
      @user = user
      @palletizer_identifier = palletizer_identifier
      @palletizing_bay_resource_id = palletizing_bay_resource_id
      @repo = MesscadaApp::MesscadaRepo.new
    end

    def call
      res = resolve_scanned_number_params
      return res unless res.success

      res = carton_verification
      return res unless res.success

      success_response("Successfully verified #{scanned[:scanned_type]}: #{scanned_number}", response_instance)
    end

    private

    def resolve_scanned_number_params
      res = ScanCartonLabelOrPallet.call(scanned_number)
      return res unless res.success

      scanned = res.instance
      @scanned = scanned.to_h
      if scanned.pallet?
        @pallet_number = scanned.pallet_number
        @pallet_id = scanned.pallet_id
        @carton_label_id = repo.get_id(:carton_labels, pallet_number: pallet_number)
      else
        @carton_label_id = scanned.carton_label_id
      end
      ok_response
    end

    def carton_verification # rubocop:disable Metrics/AbcSize
      repo.transaction do
        unless carton_exists?
          res = create_carton
          raise Crossbeams::InfoError, res.message unless res.success

          @carton_id = res.instance.carton_id
        end
        if pallet_required?
          res = create_pallet
          raise Crossbeams::InfoError, res.message unless res.success

          @pallet_id = res.instance.pallet_id
          @pallet_sequence_id = res.instance.pallet_sequence_id
          @pallet_number = repo.get(:pallets, pallet_id, :pallet_number)
        end
      end

      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def create_carton
      return CreateCartonFromScannedPallet.call(pallet_number, set_carton_params) if scanned[:pallet_was_scanned]

      CreateCartonFromScannedCartonLabel.call(carton_label_id, set_carton_params)
    end

    def create_pallet
      CreateCartonEqualsPalletPallet.call(user, carton_id, palletizing_bay_resource_id)
    end

    def set_carton_params
      params = { palletizing_bay_resource_id: palletizing_bay_resource_id }
      unless palletizer_identifier.nil?
        hr_repo = MesscadaApp::HrRepo.new
        params[:palletizer_identifier_id] = hr_repo.personnel_identifier_id_from_device_identifier(palletizer_identifier)
        params[:palletizer_contract_worker_id] = hr_repo.contract_worker_id_from_personnel_id(palletizer_identifier_id)
      end
      params
    end

    def pallet_required?
      carton_label_id ||= repo.get(:cartons, carton_id, :carton_label_id)
      carton_equals_pallet = repo.get(:carton_labels, carton_label_id, :carton_equals_pallet)
      return false unless carton_equals_pallet

      !pallet_exists?
    end

    def carton_exists?
      @carton_id ||= repo.get_id(:cartons, carton_label_id: carton_label_id)
      !carton_id.nil? && !carton_label_id.nil?
    end

    def pallet_exists? # rubocop:disable Metrics/AbcSize
      @pallet_sequence_id = repo.carton_label_carton_palletizing_sequence(carton_label_id)
      @pallet_sequence_id ||= repo.carton_label_scanned_from_carton_sequence(carton_label_id)
      @pallet_id ||= repo.get(:pallet_sequences, pallet_sequence_id, :pallet_id)
      @pallet_number ||= repo.get(:pallet_sequences, pallet_sequence_id, :pallet_number)

      !pallet_id.nil? && !pallet_sequence_id.nil?
    end

    def response_instance
      OpenStruct.new(carton_label_id: carton_label_id,
                     carton_id: carton_id,
                     pallet_sequence_id: pallet_sequence_id,
                     pallet_id: pallet_id,
                     pallet_number: pallet_number)
    end
  end
end
