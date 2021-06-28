# frozen_string_literal: true

module MesscadaApp
  class CloneAutopackPalletCarton < BaseService
    attr_reader :repo, :prod_repo, :carton_id, :pallet_id, :palletizer_identifier, :palletizing_bay_resource_id,
                :carton, :diff, :carton_numbers, :no_of_clones

    def initialize(params)
      @carton_id = params[:carton_id]
      @pallet_id = params[:pallet_id]
      @palletizer_identifier = params[:palletizer_identifier]
      @palletizing_bay_resource_id = params[:palletizing_bay_resource_id]
      @no_of_clones = params[:no_of_clones]
      @repo = MesscadaApp::MesscadaRepo.new
      @prod_repo = ProductionApp::ProductionRunRepo.new
    end

    def call # rubocop:disable Metrics/AbcSize
      return failed_response("Pallet :#{pallet_id} does not exist") unless pallet_exists?

      return failed_response("Carton :#{carton_id} does not exist") unless carton_exists?

      @carton = find_carton
      @diff = no_of_clones.nil? ? carton_cpp(carton[:cartons_per_pallet_id]) - pallet_carton_quantity(pallet_id) : no_of_clones
      return failed_response("Pallet :#{pallet_id} already full") if diff < 1

      res = clone_autopack_pallet_carton
      raise Crossbeams::InfoError, unwrap_failed_response(res) unless res.success

      success_response('ok', pallet_id: pallet_id)
    end

    private

    def pallet_exists?
      repo.exists?(:pallets, id: pallet_id)
    end

    def carton_exists?
      repo.carton_exists?(carton_id)
    end

    def find_carton
      repo.where(:cartons, MesscadaApp::Carton, id: carton_id)
    end

    def carton_cpp(cartons_per_pallet_id)
      repo.find_cartons_per_pallet(cartons_per_pallet_id).to_i
    end

    def pallet_carton_quantity(pallet_id)
      repo.get(:pallets, pallet_id, :carton_quantity).to_i
    end

    def clone_autopack_pallet_carton
      res = create_carton_labels
      return res unless res.success

      res = create_cartons
      return res unless res.success

      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def create_carton_labels
      carton_label_rejected_fields = %i[id created_at updated_at]
      attrs = repo.find_hash(:carton_labels, carton[:carton_label_id]).reject { |k, _| carton_label_rejected_fields.include?(k) }

      @carton_numbers = repo.create_carton_labels(diff, attrs)

      ok_response
    end

    def create_cartons
      carton_numbers.each do |carton_number|
        new_carton_id = get_palletizing_carton(carton_number)
        repo.update_carton(new_carton_id, { pallet_sequence_id: carton[:pallet_sequence_id], is_virtual: true, palletizing_bay_resource_id: palletizing_bay_resource_id })
        prod_repo.increment_sequence(carton[:pallet_sequence_id])
      end

      ok_response
    end

    def get_palletizing_carton(carton_number)
      MesscadaApp::CartonVerification.call(@user, carton_number, palletizer_identifier, palletizing_bay_resource_id) unless verified_carton_number?(carton_number)
      carton_number_carton_id(carton_number)
    end

    def verified_carton_number?(carton_number)
      repo.carton_label_carton_exists?(carton_number)
    end

    def carton_number_carton_id(carton_number)
      repo.carton_label_carton_id(carton_number)
    end
  end
end
