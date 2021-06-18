# frozen_string_literal: true

module MesscadaApp
  class ScanCartonOrPalletEntity < Dry::Struct
    attribute :id, Types::Integer
    attribute :pallet_was_scanned, Types::Bool
    attribute :formatted_number, Types::String
    attribute :scanned_number, Types::String

    def pallet?
      pallet_was_scanned
    end

    def carton?
      !pallet_was_scanned
    end

    def carton_id
      pallet_was_scanned ? nil : id
    end

    def pallet_id
      pallet_was_scanned ? id : nil
    end
  end
end
