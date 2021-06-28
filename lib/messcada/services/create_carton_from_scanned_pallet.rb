# frozen_string_literal: true

module MesscadaApp
  class CreateCartonFromScannedPallet < BaseService
    attr_reader :repo, :pallet_number
    attr_accessor :params

    def initialize(pallet_number, params)
      @pallet_number = pallet_number
      @params = params
      @repo = MesscadaApp::MesscadaRepo.new
    end

    def call
      res = create_pallet_number_carton
      return failed_response(unwrap_failed_response(res)) unless res.success

      res
    end

    private

    def create_pallet_number_carton # rubocop:disable Metrics/AbcSize
      params[:carton_label_id] = repo.get_id(:carton_labels, pallet_number: pallet_number)
      return failed_response("Pallet number: #{pallet_number} could not be found on carton labels") if params[:carton_label_id].nil?

      res = CartonSchema.call(params)
      return validation_failed_response(res) if res.failure?

      carton_id = repo.create(:cartons, res)
      success_response('ok', carton_id: carton_id)
    end
  end
end
