# frozen_string_literal: true

module MesscadaApp
  class CartonVerification < BaseService
    attr_reader :repo, :user, :scanned_number, :palletizer_identifier, :palletizing_bay_resource_id,
                :scanned, :pallet_number, :carton_label_id

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
      return success_response("#{scanned[:scanned_type]} : #{scanned_number} already verified") if carton_exists? && pallet_exists?

      res = carton_verification
      return res unless res.success

      success_response("Successfully verified #{scanned[:scanned_type]}: #{scanned_number}")
    end

    private

    def resolve_scanned_number_params # rubocop:disable Metrics/AbcSize
      res = ScanCartonLabelOrPallet.call(scanned_number)
      return res unless res.success

      scanned = res.instance
      @scanned = scanned.to_h

      if scanned.pallet?
        @pallet_number = scanned.formatted_number
        @carton_label_id = repo.carton_label_id_for_pallet_no(pallet_number)
      else
        @carton_label_id = scanned.id
        pallet_sequence_id = repo.carton_label_carton_palletizing_sequence(carton_label_id)
        pallet_sequence_id ||= repo.carton_label_scanned_from_carton_sequence(carton_label_id)
        @pallet_number = repo.get(:pallet_sequences, pallet_sequence_id, :pallet_number)
      end
      ok_response
    end

    def carton_verification # rubocop:disable Metrics/AbcSize
      repo.transaction do
        unless carton_exists?
          res = create_carton
          raise Crossbeams::InfoError, res.message unless res.success
        end
        unless pallet_exists?
          res = create_pallet
          raise Crossbeams::InfoError, res.message unless res.success
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
      carton_id = repo.get_id(:cartons, carton_label_id: carton_label_id)
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

    def carton_exists?
      if scanned[:pallet_was_scanned]
        ds = DB[:pallet_sequences].where(pallet_number: pallet_number)
        repo.exists?(:cartons, pallet_sequence_id: ds.select_map(:id)) || !ds.select_map(:scanned_from_carton_id).empty?
      else
        repo.exists?(:cartons, carton_label_id: carton_label_id)
      end
    end

    def pallet_exists?
      repo.pallet_exists?(pallet_number) || !repo.get(:carton_labels, carton_label_id, :carton_equals_pallet)
    end
  end
end
