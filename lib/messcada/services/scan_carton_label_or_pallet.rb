# frozen_string_literal: true

module MesscadaApp
  class ScanCartonLabelOrPallet < BaseService
    attr_reader :repo, :mode, :scanned_number, :formatted_number

    def initialize(scanned_number, mode = nil)
      @mode = mode
      @scanned_number = scanned_number.to_s
      @pallet_was_scanned = false
      @repo = MesscadaApp::MesscadaRepo.new
    end

    TASKS = {
      pallet: :resolve_pallet,
      carton_label: :resolve_carton_label,
      legacy_carton_label: :resolve_legacy_carton_label
    }.freeze

    def call # rubocop:disable Metrics/AbcSize
      return failed_response('Scanned number empty') if scanned_number.nil_or_empty?

      determine_mode if mode.nil?

      resolve_mode = TASKS[mode]
      raise ArgumentError, "Scan mode \"#{mode}\" is unknown for #{self.class}." if resolve_mode.nil?

      send(resolve_mode)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    private

    def determine_mode
      @mode = case scanned_number.length
              when 1...8
                :carton_label
              when 12
                :legacy_carton_label
              else
                :pallet
              end
    end

    def response
      instance = ScanCartonLabelOrPalletEntity.new(
        id: @id,
        pallet_was_scanned: @pallet_was_scanned,
        scanned_number: @scanned_number,
        formatted_number: @formatted_number,
        scanned_type: @mode.to_s
      )
      return failed_response('Failed to scan number') unless @id

      success_response("Successfully scanned #{@mode} number", instance)
    end

    def resolve_pallet
      @formatted_number = MesscadaApp::ScannedPalletNumber.new(scanned_pallet_number: scanned_number).pallet_number
      @id = repo.get_id(:pallets, pallet_number: formatted_number)
      @pallet_was_scanned = true
      response
    end

    def resolve_carton_label
      @formatted_number = MesscadaApp::ScannedCartonNumber.new(scanned_carton_number: scanned_number).carton_number
      @id = repo.get_id(:carton_labels, id: formatted_number)
      response
    end

    def resolve_legacy_carton_label
      @formatted_number = MesscadaApp::ScannedCartonNumber.new(scanned_carton_number: scanned_number).legacy_carton_number
      @id = repo.get_value(:legacy_barcodes, :carton_label_id, legacy_carton_number: formatted_number)
      response
    end
  end
end
