# frozen_string_literal: true

module MesscadaApp
  class CreateCartonFromScannedCartonLabel < BaseService
    attr_reader :repo, :carton_label_id
    attr_accessor :params

    def initialize(carton_label_id, params)
      @carton_label_id = carton_label_id
      @params = params
      @repo = MesscadaApp::MesscadaRepo.new
    end

    def call
      res = create_carton_label_carton
      return failed_response(unwrap_failed_response(res)) unless res.success

      res
    end

    private

    def create_carton_label_carton # rubocop:disable Metrics/AbcSize
      return failed_response("Carton label: #{carton_label_id} could not be found") unless carton_label_exists?
      return failed_response("Carton label: #{carton_label_id} already verified") if carton_label_carton_exists?

      params[:carton_label_id] = carton_label_id
      res = CartonSchema.call(params)
      return validation_failed_response(res) if res.failure?

      carton_id = repo.create(:cartons, res)
      success_response('ok', carton_id: carton_id)
    end

    def carton_label_exists?
      repo.exists?(:carton_labels, id: carton_label_id)
    end

    def carton_label_carton_exists?
      repo.exists?(:cartons, carton_label_id: carton_label_id)
    end
  end
end
