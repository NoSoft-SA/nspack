# frozen_string_literal: true

module MesscadaApp
  class CreateCartonEqualsPalletPallet < BaseService
    attr_reader :repo, :carton_id, :carton, :pallet_id, :pallet_sequence_id, :palletizing_bay_resource_id

    def initialize(user, carton_id, palletizing_bay_resource_id = nil)
      @carton_id = carton_id
      @user_name = user&.user_name
      @palletizing_bay_resource_id = palletizing_bay_resource_id
      @repo = MesscadaApp::MesscadaRepo.new
    end

    def call # rubocop:disable Metrics/AbcSize
      @carton = repo.find_carton(carton_id)
      return failed_response("Carton : #{carton_id} not verified") unless carton
      return success_response('Carton does not equal pallet', response_instance) unless carton_equals_pallet?

      res = create_pallet
      return failed_response(unwrap_failed_response(res)) unless res.success

      success_response('ok', response_instance)
    end

    private

    def response_instance
      OpenStruct.new(pallet_id: pallet_id, pallet_sequence_id: pallet_sequence_id)
    end

    def create_pallet # rubocop:disable Metrics/AbcSize
      res = PalletContract.new.call(pallet_params)
      return validation_failed_response(res) if res.failure?

      @pallet_id = repo.create_pallet(@user_name, res.to_h)

      res = NewPalletSequence.call(@user_name, carton_id, pallet_id, 1)
      return res unless res.success

      @pallet_sequence_id = res.instance[:pallet_sequence_id]
      ok_response
    end

    def pallet_params # rubocop:disable Metrics/AbcSize
      {
        status: AppConst::PALLETIZED_NEW_PALLET,
        partially_palletized: false,
        location_id: repo.find_resource_location_id(carton[:packhouse_resource_id]),
        phc: carton[:phc],
        fruit_sticker_pm_product_id: carton[:fruit_sticker_pm_product_id],
        pallet_format_id: carton[:pallet_format_id],
        plt_packhouse_resource_id: carton[:packhouse_resource_id],
        plt_line_resource_id: carton[:production_line_id],
        palletizing_bay_resource_id: palletizing_bay_resource_id,
        pallet_number: carton[:pallet_number],
        has_individual_cartons: false
      }
    end

    def carton_equals_pallet?
      carton_label_id = repo.get(:cartons, carton_id, :carton_label_id)
      repo.get(:carton_labels, carton_label_id, :carton_equals_pallet)
    end
  end
end
