# frozen_string_literal: true

module MasterfilesApp
  SeasonSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:season_group_id).filled(:integer)
    required(:commodity_id).filled(:integer)
    optional(:season_code).maybe(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
    optional(:season_year).maybe(:integer)
    required(:start_date).maybe(:date)
    required(:end_date).maybe(:date)
  end
end
