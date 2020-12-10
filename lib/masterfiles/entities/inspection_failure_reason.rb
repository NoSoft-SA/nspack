# frozen_string_literal: true

module MasterfilesApp
  class InspectionFailureReason < Dry::Struct
    attribute :id, Types::Integer
    attribute :inspection_failure_type_id, Types::Integer
    attribute :failure_type_code, Types::String
    attribute :failure_reason, Types::String
    attribute :description, Types::String
    attribute :main_factor, Types::Bool
    attribute :secondary_factor, Types::Bool
    attribute? :status, Types::String
    attribute? :active, Types::Bool
  end
end
