# frozen_string_literal: true

module MasterfilesApp
  VesselSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:vessel_type_id, :integer).filled(:int?)
    required(:vessel_code, Types::StrippedString).filled(:str?)
    required(:description, Types::StrippedString).maybe(:str?)
  end
end
