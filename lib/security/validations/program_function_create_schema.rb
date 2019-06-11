# frozen_string_literal: true

module SecurityApp
  ProgramFunctionCreateSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    required(:program_function_name, Types::StrippedString).filled(:str?)
    required(:url, Types::StrippedString).filled(:str?)
    required(:program_function_sequence, :integer).filled(:int?)
    required(:program_id, :integer).filled(:int?)
    required(:group_name, Types::StrippedString).maybe(:str?)
    required(:restricted_user_access, :bool).filled(:bool?)
    required(:active, :bool).filled(:bool?)
    optional(:show_in_iframe, :bool).filled(:bool?)
  end
end
