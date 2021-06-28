# frozen_string_literal: true

module MesscadaApp
  CartonLabelingSchema = Dry::Schema.Params do
    required(:device).filled(Types::StrippedString)
    optional(:card_reader).maybe(Types::StrippedString)
    optional(:identifier).maybe(Types::StrippedString)
  end

  CartonVerificationSchema = Dry::Schema.Params do
    required(:carton_number).filled(:integer)
    required(:device).filled(Types::StrippedString)
  end

  CartonVerificationAndWeighingSchema = Dry::Schema.Params do
    required(:carton_number).filled(:integer)
    required(:device).filled(Types::StrippedString)
    required(:gross_weight).filled(:decimal)
    required(:measurement_unit).filled(Types::StrippedString)
  end

  FgPalletWeighingSchema = Dry::Schema.Params do
    # required(:pallet_number).filled(Types::StrippedString)
    required(:bin_number).filled(Types::StrippedString)
    required(:gross_weight).filled(:decimal)
    required(:measurement_unit).filled(Types::StrippedString)
  end

  CartonPalletizingScanIncentiveSchema = Dry::Schema.Params do
    required(:device).filled(Types::StrippedString)
    required(:reader_id).filled(Types::StrippedString)
    required(:identifier).filled(Types::StrippedString)
    required(:carton_number).filled(:integer)
  end

  CartonPalletizingIncentiveSchema = Dry::Schema.Params do
    required(:device).filled(Types::StrippedString)
    required(:reader_id).filled(Types::StrippedString)
    required(:identifier).filled(Types::StrippedString)
  end

  CartonPalletizingScanSchema = Dry::Schema.Params do
    required(:device).filled(Types::StrippedString)
    required(:reader_id).filled(Types::StrippedString)
    required(:identifier).maybe(Types::StrippedString)
    required(:carton_number).filled(:integer)
  end

  CartonPalletizingSchema = Dry::Schema.Params do
    required(:device).filled(Types::StrippedString)
    required(:reader_id).filled(Types::StrippedString)
    required(:identifier).maybe(Types::StrippedString)
  end
end
