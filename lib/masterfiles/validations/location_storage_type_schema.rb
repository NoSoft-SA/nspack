# frozen_string_literal: true

module MasterfilesApp
  LocationStorageTypeSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:storage_type_code, Types::StrippedString).filled(:str?)
    required(:location_short_code_prefix, Types::StrippedString).maybe(:str?)
  end
end
