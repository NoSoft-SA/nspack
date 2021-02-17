# frozen_string_literal: true

module MasterfilesApp
  class TargetMarket < Dry::Struct
    attribute :id, Types::Integer
    attribute :target_market_name, Types::String
    attribute :country_ids, Types::Array
    attribute :tm_group_ids, Types::Array
    attribute :description, Types::String
    attribute :is_inspection_tm, Types::Bool
  end
end
