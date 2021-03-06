# frozen_string_literal: true

module MesscadaApp
  class ReplacePalletSequence < BaseService
    attr_reader :repo, :carton_id, :carton_quantity, :pallet_id, :pallet_sequence_id, :user_name

    def initialize(user_name, carton_id, pallet_id, pallet_sequence_id, carton_quantity)
      @carton_id = carton_id
      @carton_quantity = carton_quantity
      @pallet_id = pallet_id
      @pallet_sequence_id = pallet_sequence_id
      @repo = MesscadaApp::MesscadaRepo.new
      @user_name = user_name
    end

    def call
      res = NewPalletSequenceObject.new(user_name, carton_id, carton_quantity).call
      return res unless res.success

      # repo.replace_sequences(res.instance, pallet_sequence_id)
      repo.update_pallet_sequence(pallet_sequence_id, res.instance)

      repo.log_status('pallets', pallet_id, AppConst::PALLETIZED_SEQUENCE_REPLACED)
      ok_response
    end
  end
end
