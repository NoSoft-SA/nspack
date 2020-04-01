# frozen_string_literal: true

module MesscadaApp
  class AddSequenceToPallet < BaseService
    attr_reader :repo, :carton_id, :carton_quantity, :pallet_id, :user_name

    def initialize(user_name, carton_id, pallet_id, carton_quantity)
      @carton_id = carton_id
      @carton_quantity = carton_quantity
      @pallet_id = pallet_id
      @repo = MesscadaApp::MesscadaRepo.new
      @user_name = user_name
    end

    def call
      res = NewPalletSequence.new(user_name, carton_id, pallet_id, carton_quantity).call
      return res unless res.success

      repo.log_status('pallets', pallet_id, AppConst::PALLETIZED_SEQUENCE_ADDED)
      ok_response
    end
  end
end
