# frozen_string_literal: true

module MesscadaApp
  class ScanCartonLabelOrPalletEntity < Dry::Struct
    attribute :id, Types::Integer
    attribute :pallet_was_scanned, Types::Bool
    attribute :formatted_number, Types::String
    attribute :scanned_number, Types::String

    def pallet?
      pallet_was_scanned
    end

    def carton_label?
      !pallet_was_scanned
    end

    def carton_label_id
      pallet_was_scanned ? nil : id
    end

    def pallet_id
      pallet_was_scanned ? id : nil
    end
  end
end
