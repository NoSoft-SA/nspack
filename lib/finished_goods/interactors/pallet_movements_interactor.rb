# frozen_string_literal: true

module FinishedGoodsApp
  class PalletMovementsInteractor < BaseInteractor
    def move_pallet(pallet_number, location, location_scan_field) # rubocop:disable Metrics/AbcSize
      pallet = ProductionApp::ProductionRunRepo.new.find_pallet_by_pallet_number(pallet_number)
      return validation_failed_response(messages: { pallet_number: ['Pallet does not exist'] }) unless pallet

      location_id = locn_repo.resolve_location_id_from_scan(location, location_scan_field)
      return validation_failed_response(messages: { location: ['Location does not exist'] }) if location_id.nil_or_empty?

      repo.transaction do
        FinishedGoodsApp::MoveStockService.new(AppConst::PALLET_STOCK_TYPE, pallet[:id], location_id, 'MOVE_PALLET', nil).call
      end
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message("move_pallet #{pallet_number}, Loc: #{location}"))
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message)
    end

    def move_deck_pallets(deck, deck_scan_field, location_to, location_to_scan_field) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      deck_id = locn_repo.resolve_location_id_from_scan(deck, deck_scan_field)
      return validation_failed_response(messages: { deck: ['deck location does not exist'] }) if deck_id.nil_or_empty?

      from_location_type = locn_repo.get_locations_type_code(deck_id)
      return failed_response("From location must be a #{AppConst::LOCATION_TYPES_COLD_BAY_DECK}. You scanned a: #{from_location_type}") unless from_location_type == AppConst::LOCATION_TYPES_COLD_BAY_DECK

      location_to_id = locn_repo.resolve_location_id_from_scan(location_to, location_to_scan_field)
      return validation_failed_response(messages: { location_to: ['location_to does not exist'] }) if location_to_id.nil_or_empty?

      return failed_response('Deck and To Location cannot be the same') unless deck_id != location_to_id

      return failed_response('Destination deck does not have enough empty positions') if locn_repo.get_locations_type_code(location_to_id) == AppConst::LOCATION_TYPES_COLD_BAY_DECK && num_plts_in_dec(deck_id) > num_empty_positions_in_dec(location_to_id)

      plts_to_move = locn_repo.get_deck_pallets(deck_id).find_all { |d| !d[:pallet_number].nil_or_empty? }.sort_by { |p| p[:pos] }
      return failed_response('From Deck is empty') if plts_to_move.empty?

      repo.transaction do
        plts_to_move.each do |p|
          res = FinishedGoodsApp::MoveStockService.new(AppConst::PALLET_STOCK_TYPE, p[:pallet_id], location_to_id, 'MOVE_PALLET', nil).call
          raise res.message unless res.success
        end
      end

      success_response('Pallets moved successfully')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      # ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message("move_deck_pallets #{deck_id}, Loc: #{location_to_id}"))
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message)
    end

    def set_local_pallet # rubocop:disable Metrics/AbcSize
      args = { in_stock: false, packed_tm_group: 'LO' }
      pallet_sequence = repo.all_hash(:vw_pallet_sequence_flat, args)
      pallet_ids = pallet_sequence.map { |seq| seq[:pallet_id] }
      pallet_numbers = pallet_sequence.map { |seq| seq[:pallet_number] }

      repo.transaction do
        repo.update(:pallets, pallet_ids, in_stock: true, stock_created_at: Time.now)
        log_multiple_statuses(:pallets, pallet_ids, 'ACCEPTED_AS_LOCAL_STOCK')
        log_transaction
      end

      success_response("Updated pallets #{pallet_numbers.join(', ')}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    private

    def get_location_id_by_barcode(location_barcode)
      repo.get_location_id_by_barcode(location_barcode)
    end

    def num_plts_in_dec(deck_id)
      locn_repo.get_deck_pallets(deck_id).find_all { |d| !d[:pallet_number].nil_or_empty? }.length
    end

    def num_empty_positions_in_dec(deck_id)
      locn_repo.get_deck_pallets(deck_id).find_all { |d| d[:pallet_number].nil_or_empty? }.length
    end

    def repo
      @repo ||= FinishedGoodsApp::LoadRepo.new
    end

    def locn_repo
      MasterfilesApp::LocationRepo.new
    end
  end
end
