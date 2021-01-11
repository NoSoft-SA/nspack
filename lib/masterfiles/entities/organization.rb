# frozen_string_literal: true

module MasterfilesApp
  class Organization < Dry::Struct
    attribute :id, Types::Integer
    attribute :party_id, Types::Integer
    attribute :party_name, Types::String
    attribute :parent_id, Types::Integer
    attribute :short_description, Types::String
    attribute :medium_description, Types::String
    attribute :long_description, Types::String
    attribute :vat_number, Types::String
    attribute :company_reg_no, Types::String
    attribute :active, Types::Bool
    attribute :role_ids, Types::Array
    attribute :role_names, Types::Array
    attribute :specialised_role_names, Types::Array
    attribute :variant_codes, Types::Array
    attribute :parent_organization, Types::String
  end
end
