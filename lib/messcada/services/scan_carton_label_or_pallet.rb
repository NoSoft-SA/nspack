# frozen_string_literal: true

module MesscadaApp
  class ScanCartonLabelOrPallet < BaseService
    attr_reader :repo, :params, :mode, :scanned_number, :formatted_number

    def initialize(params)
      @repo = MesscadaApp::MesscadaRepo.new
      @pallet_was_scanned = false
      @scanned_number = ''
      @params = params
      @params = { scanned_number: params.to_s } unless @params.respond_to?(:to_h)
    end

    SCAN = {
      pallet: :resolve_pallet,
      carton_label: :resolve_carton_label,
      legacy_carton_number: :resolve_legacy_carton_number
    }.freeze

    def call
      parse_params
      return failed_response('Nothing Scanned') if scanned_number.empty?

      scan_mode = SCAN[mode]
      raise ArgumentError, "Scan mode \"#{mode}\" is unknown for #{self.class}." if scan_mode.nil?

      send(scan_mode)
      return failed_response('Failed to scan number') unless @id

      success_response("Successfully scanned #{@mode} number", build_entity)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    private

    def parse_params
      valid_keys = { pallet_number: :pallet,
                     carton_number: :carton_label,
                     carton_label_id: :carton_label,
                     legacy_carton_number: :legacy_carton_number,
                     scanned_number: nil }

      valid_keys.each do |key, scan_mode|
        next unless scanned_number.empty?

        @scanned_number = params.delete(key).to_s
        @mode = scan_mode
      end

      @mode ||= determine_mode

      invalid_keys = params.keys
      raise ArgumentError, "Invalid argument: #{invalid_keys}" if @mode.nil?
    end

    def determine_mode
      case scanned_number.length
      when 1...8
        :carton_label
      when 12
        :legacy_carton_number
      else
        :pallet
      end
    end

    def build_entity
      ScanCartonLabelOrPalletEntity.new(
        id: @id,
        pallet_was_scanned: @pallet_was_scanned,
        scanned_number: @scanned_number,
        formatted_number: @formatted_number,
        scanned_type: @mode.to_s
      )
    end

    def resolve_pallet
      @formatted_number = MesscadaApp::ScannedPalletNumber.new(scanned_pallet_number: scanned_number).pallet_number
      @pallet_was_scanned = true
      @id = repo.get_id(:pallets, pallet_number: formatted_number)
    end

    def resolve_carton_label
      @formatted_number = MesscadaApp::ScannedCartonNumber.new(scanned_carton_number: scanned_number).carton_number
      @id = repo.get_id(:carton_labels, id: formatted_number)
    end

    def resolve_legacy_carton_number
      @formatted_number = MesscadaApp::ScannedCartonNumber.new(scanned_carton_number: scanned_number).legacy_carton_number
      @id = repo.get_value(:legacy_barcodes, :carton_label_id, legacy_carton_number: formatted_number)
    end
  end
end
