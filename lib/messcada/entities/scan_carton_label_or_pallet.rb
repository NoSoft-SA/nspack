# frozen_string_literal: true

module MesscadaApp
  class ScanCartonLabelOrPalletEntity < Dry::Struct
    attribute :id, Types::Integer
    attribute :pallet_was_scanned, Types::Bool
    attribute :formatted_number, Types::String
    attribute :scanned_number, Types::String
    attribute :scanned_type, Types::String

    def pallet?
      pallet_was_scanned
    end

    def carton_label?
      !pallet_was_scanned
    end

    def carton_label_id
      pallet_was_scanned ? nil : id
    end

    def carton_id
      pallet_was_scanned ? nil : repo.get_id(:cartons, carton_label_id: id)
    end

    def pallet_sequence_id
      pallet_was_scanned ? nil : repo.get(:cartons, carton_id, :pallet_sequence_id)
    end

    def pallet_id
      pallet_was_scanned ? id : repo.get(:pallet_sequences, pallet_sequence_id, :pallet_id)
    end

    def pallet_number
      pallet_was_scanned ? formatted_number : repo.get(:pallets, pallet_id, :pallet_number)
    end

    def repo
      @repo ||= BaseRepo.new
    end
  end
end
