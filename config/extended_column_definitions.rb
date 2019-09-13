# frozen_string_literal: true

module Crossbeams
  module Config
    # Store rules for JSONB contents of various tables per client.
    #
    # REQUIRED RULES
    # - type: :string, :boolean, :integer, :numeric
    # OPTIONAL RULES
    # - required: true/false (if true, the UI will prompt the user to fill in the field)
    # - default: any value
    # - masterlist_key: a list_type value from the master_lists table - used to populate a select box with options.
    class ExtendedColumnDefinitions
      EXTENDED_COLUMNS = {
        labels: {
          AppConst::DEFAULT_KEY => {
            label_type: { type: :string, masterlist_key: 'label_type', required: true }
          }
          # 'srcc' => {
          #   agent: { type: :string, required: true },
          #   pack_week: { type: :integer, required: true },
          #   srcc_order_nr: { type: :string },
          #   receiver_client: { type: :string },
          #   commodity: { type: :string, masterlist_key: 'commodity', required: true },
          #   variety: { type: :string },
          #   pack_code: { type: :string },
          #   weight: { type: :string },
          #   brand: { type: :boolean },
          #   class: { type: :string, default: '1' },
          #   lot_number: { type: :string },
          #   comments: { type: :string }
          # }
        }
      }.freeze

      VALIDATIONS = {
        labels: {
          AppConst::DEFAULT_KEY => Dry::Validation.Params do
            required(:label_type).filled(:str?)
          end
          # 'srcc' => Dry::Validation.Params do
          #   required(:agent).filled(:str?)
          #   required(:pack_week).filled(:int?, gteq?: 1, lteq?: 52)
          #   required(:srcc_order_nr).maybe(:str?)
          #   required(:receiver_client).maybe(:str?)
          #   required(:commodity).filled(:str?)
          #   required(:variety).maybe(:str?)
          #   required(:pack_code).maybe(:str?)
          #   required(:weight).maybe(:str?)
          #   required(:brand).maybe(:bool?)
          #   required(:class).maybe(:str?)
          #   required(:lot_number).maybe(:str?)
          #   required(:comments).maybe(:str?)
          # end
        }
      }.freeze

      # Takes the configuration rules for an extended column
      # and unpacks it into +form.add_field+ calls which are applied to the
      # form parameter.
      #
      # @param table [symbol] the name of the table that has an extended_columns field.
      # @param form [Crossbeams::Form] the form/fold in which to place the fields.
      def self.extended_columns_for_view(table, form)
        config = config_for(table)
        return if config.nil?

        config.keys.each { |k| form.add_field("extcol_#{k}".to_sym) }
      end

      # Looks up the configuration rules for an extended column.
      #
      # @param table [symbol] the name of the table that has an extended_columns field.
      # @return config [Hash,nil] the applicable config for the table.
      def self.config_for(table)
        config = EXTENDED_COLUMNS.dig(table, AppConst::CLIENT_CODE)
        config = EXTENDED_COLUMNS.dig(table, AppConst::DEFAULT_KEY) if config.nil?
        config
      end

      # Looks up the validation rules for an extended column.
      #
      # @param table [symbol] the name of the table that has an extended_columns field.
      # @return val [Schema] the applicable validation rules for the table.
      def self.validation_for(table)
        val = VALIDATIONS[table][AppConst::CLIENT_CODE]
        val = VALIDATIONS[table][AppConst::DEFAULT_KEY] if val.nil?
        val
      end

      def verify_config
        if EXTENDED_COLUMNS.empty?
          puts 'Nothing to verify'
          return
        end
        errs = verify_client_keys

        EXTENDED_COLUMNS.each do |table, rules|
          rules.each do |client_code, rule|
            errs += verify_validation(table, client_code, rule)
          end
        end
        if errs.empty?
          puts 'ExtendedColumnDefinitions is OK'
        else
          puts "ExtendedColumnDefinitions ERROR: #{errs.join(', ')}"
        end
      end

      def verify_client_keys
        errs = []
        EXTENDED_COLUMNS.each { |_, v| v.keys.each { |key| errs << "Client code key must be a string: #{key.inspect}" unless key.is_a?(String) } }
        errs
      end

      def verify_validation(table, client_code, rule) # rubocop:disable Metrics/AbcSize
        errs = []
        val = VALIDATIONS[table][client_code]
        val = VALIDATIONS[table][AppConst::DEFAULT_KEY] if val.nil?
        if val.nil?
          errs << "#{table.inspect}/#{client_code} does not have a validation rule."
        else
          diff = rule.keys - val.rules.keys
          errs << "#{table.inspect}/#{client_code} validation does not cover all columns (#{diff.join(', ')})" unless diff.empty?
        end
        errs
      end
    end
  end
end
