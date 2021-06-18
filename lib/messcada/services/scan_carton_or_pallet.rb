# frozen_string_literal: true

module MesscadaApp
  class ScanCartonOrPallet < BaseService
    attr_reader :repo, :mode, :scanned_number

    def initialize(scanned_number, mode = nil)
      @mode = mode
      @scanned_number = scanned_number
      @repo = MesscadaApp::MesscadaRepo.new
    end

    TASKS = {
      pallet: :resolve_pallet,
      carton: :resolve_carton,
      legacy_carton: :resolve_legacy_carton
    }.freeze

    def call
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
                :carton
              when 12
                :legacy_carton
              else
                :pallet
              end
    end

    def response
      instance = ScanCartonOrPalletEntity.new(id: @id, pallet_was_scanned: @pallet_was_scanned, scanned_number: @scanned_number)
      return failed_response('Failed to scan number!') unless @id

      success_response("Successfully scanned #{@mode} number", instance)
    end

    def resolve_pallet
      @scanned_number = MesscadaApp::ScannedPalletNumber.new(scanned_pallet_number: scanned_number).pallet_number
      @id = repo.get_id(:pallets, pallet_number: scanned_number)
      @pallet_was_scanned = true
      @mode = :pallet
      response
    end

    def resolve_carton
      @scanned_number = MesscadaApp::ScannedCartonNumber.new(scanned_carton_number: scanned_number).carton_number
      @id = repo.get_id(:cartons, carton_label_id: scanned_number)
      @pallet_was_scanned = false
      @mode = :carton
      response
    end

    def resolve_legacy_carton
      @scanned_number = MesscadaApp::ScannedCartonNumber.new(scanned_carton_number: scanned_number).legacy_carton_number
      carton_label_id = repo.get_value(:legacy_barcodes, :carton_label_id, legacy_carton_number: scanned_number)
      @id = repo.get_id(:cartons, carton_label_id: carton_label_id)
      @pallet_was_scanned = false
      @mode = :legacy_carton
      response
    end
  end
end
