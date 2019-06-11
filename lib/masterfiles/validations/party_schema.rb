# frozen_string_literal: true

module MasterfilesApp
  PartySchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:party_type, Types::StrippedString).filled(:str?, max_size?: 1)
    required(:active, :bool).filled(:bool?)
  end
end
