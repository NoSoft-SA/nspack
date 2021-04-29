# frozen_string_literal: true

module MasterfilesApp
  FarmSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:owner_party_role_id).filled(:integer)
    required(:pdn_region_id).filled(:integer)
    optional(:farm_group_id).maybe(:integer)
    required(:farm_code).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
    optional(:puc_id).filled(:integer)
  end

  FarmPucOrgSchema = Dry::Schema.Params do
    required(:puc_id).filled(:integer)
    required(:farm_id).filled(:integer)
    required(:organization_id).filled(:integer)
  end
end
