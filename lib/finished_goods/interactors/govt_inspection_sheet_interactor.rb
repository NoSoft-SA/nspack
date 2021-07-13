# frozen_string_literal: true

module FinishedGoodsApp
  class GovtInspectionSheetInteractor < BaseInteractor # rubocop:disable Metrics/ClassLength
    def create_govt_inspection_sheet(params) # rubocop:disable Metrics/AbcSize
      params[:created_by] ||= @user.user_name
      res = validate_govt_inspection_sheet_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_govt_inspection_sheet(res)
        log_status(:govt_inspection_sheets, id, 'CREATED')
        log_transaction
      end
      instance = find_govt_inspection_sheet(id)
      success_response("Created govt inspection sheet #{instance.booking_reference}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { booking_reference: ['This govt inspection sheet already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_govt_inspection_sheet(id, params)
      check!(:edit, id)

      res = validate_govt_inspection_sheet_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_govt_inspection_sheet(id, res)
        log_transaction
      end
      instance = find_govt_inspection_sheet(id)
      success_response("Updated govt inspection sheet #{instance.booking_reference}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_govt_inspection_sheet(id)
      check!(:delete, id)

      name = find_govt_inspection_sheet(id).consignment_note_number
      repo.transaction do
        repo.delete_govt_inspection_sheet(id)
        log_status(:govt_inspection_sheets, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted govt inspection sheet #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def add_pallet_govt_inspection_sheet(id, params)
      res = validate_add_pallet_govt_inspection_params(id, params)
      return res unless res.success

      govt_inspection_pallet_id = nil
      repo.transaction do
        govt_inspection_pallet_id = repo.create_govt_inspection_pallet(res.instance)
        log_transaction
      end
      success_response('Added pallet to sheet.', govt_inspection_pallet_id)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { failure_remarks: ['This govt inspection pallet already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def complete_govt_inspection_sheet(id)
      check!(:complete, id)

      repo.transaction do
        repo.update_govt_inspection_sheet(id, completed: true, completed_at: Time.now)
        log_status(:govt_inspection_sheets, id, 'COMPLETED')
        log_transaction
      end

      success_response('Completed sheet.')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def uncomplete_govt_inspection_sheet(id)
      check!(:uncomplete, id)

      repo.transaction do
        repo.update_govt_inspection_sheet(id, completed: false, completed_at: nil)
        log_status(:govt_inspection_sheets, id, 'UNCOMPLETED')
        log_transaction
      end

      success_response('Uncompleted sheet.')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def finish_govt_inspection_sheet(id)
      check!(:finish, id)

      repo.transaction do
        repo.finish_govt_inspection_sheet(id, @user)
        log_transaction
      end
      success_response('Finished Inspection')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def reopen_govt_inspection_sheet(id)
      check!(:reopen, id)

      repo.transaction do
        repo.reopen_govt_inspection_sheet(id, @user)
        log_transaction
      end

      success_response('Reopened sheet.')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def toggle_use_inspection_destination(id)
      use_inspection_destination = repo.get(:govt_inspection_sheets, id, :use_inspection_destination_for_load_out)

      repo.transaction do
        repo.update_govt_inspection_sheet(id, use_inspection_destination_for_load_out: !use_inspection_destination)
        log_transaction
      end

      success_response('Updated sheet.')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def cancel_govt_inspection_sheet(id)
      check!(:cancel, id)

      repo.transaction do
        repo.cancel_govt_inspection_sheet(id, @user)
        log_transaction
      end
      success_response('Cancelled Inspection')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def titan_inspection(id, mode)
      res = nil
      repo.transaction do
        res = TitanInspection.call(id, mode, @user)
        log_transaction
      end
      res
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def manually_create_pallet_tripsheet(planned_location_to_id) # rubocop:disable Metrics/AbcSize
      res = validate_manual_tripsheet_params(planned_location_to_id: planned_location_to_id, business_process_id: MesscadaApp::MesscadaRepo.new.find_business_process('MANUAL_TRIPSHEET')[:id],
                                             stock_type_id: MesscadaApp::MesscadaRepo.new.find_stock_type('PALLET')[:id])
      return validation_failed_response(res) if res.failure?

      vehicle_job_id = nil
      repo.transaction do
        vehicle_job_id = repo.create_vehicle_job(res)
        log_transaction
      end

      success_response('Tripsheet Has Been Manually Created', vehicle_job_id)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def create_pallet_vehicle_job_unit(id, pallet_number, carton_number = nil) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity,  Metrics/PerceivedComplexity
      pallet = ProductionApp::ProductionRunRepo.new.find_pallet_by_pallet_number(pallet_number)
      return failed_response('Pallet does not exist') unless pallet
      return failed_response('Pallet has been scrapped') if pallet[:scrapped]
      return failed_response('Pallet has been shipped') if pallet[:shipped]
      return failed_response("Pallet:#{pallet_number} belongs to another tripsheet") if repo.pallet_in_different_tripsheet?(pallet[:id], id)
      return failed_response("Cannot add:#{pallet_number}. Tripsheet has already been offloaded") if repo.get(:vehicle_jobs, id, :offloaded_at)
      return failed_response("Pallet is still on bay: #{repo.palletizing_bay_for_pallet(pallet_number)}") if pallet[:has_individual_cartons] && !pallet[:palletized]

      pallet_stock_type_id = MesscadaApp::MesscadaRepo.new.find_stock_type('PALLET')[:id]
      res = validate_vehicle_job_unit_params(stock_item_id: pallet[:id], stock_type_id: pallet_stock_type_id, vehicle_job_id: id)
      return validation_failed_response(res) if res.failure?

      msg = nil
      repo.transaction do
        if (vehicle_job_unit_id = repo.get_value(:vehicle_job_units, :id, stock_item_id: pallet[:id], vehicle_job_id: id))
          repo.delete_vehicle_job_unit(vehicle_job_unit_id)
          msg = 'Removed From Tripsheet'
        else
          return failed_response(nil, carton_required: true) if pallet[:has_individual_cartons] && AppConst::CLIENT_CODE == 'kr' && carton_number.nil?
          return failed_response("invalid carton: #{carton_number} for pallet: #{pallet_number}", carton_required: true) if carton_number && !repo.valid_carton_for_pallet?(pallet_number, carton_number)

          insp_res = FinishedGoodsApp::FailedAndPendingPalletInspections.call(pallet_number)
          return insp_res if !insp_res.success && insp_res.errors[:failed].nil_or_empty? && insp_res.errors[:pending].nil_or_empty?

          dest_res = AppConst::CR_FG.valid_tripsheet_pallet_destination(pallet_number, repo.tripsheet_destination(id), insp_res.errors, pallet[:load_id])
          return dest_res unless dest_res.success

          repo.create_vehicle_job_unit(res)
          log_status(:pallets, pallet[:id], 'ADDED TO TRIPSHEET')
          msg = 'Vehicle Job Created'
        end
        log_transaction
      end
      success_response(msg)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def can_continue_tripsheet(tripsheet_number)
      return failed_response("Cannot continue intake tripsheet:#{tripsheet_number}") unless repo.exists?(:vehicle_jobs, id: tripsheet_number, govt_inspection_sheet_id: nil)
      return failed_response("Tripsheet:#{tripsheet_number} already offloaded") unless repo.exists?(:vehicle_jobs, id: tripsheet_number, offloaded_at: nil)
      return failed_response("Tripsheet:#{tripsheet_number} has been completed") unless repo.exists?(:vehicle_jobs, id: tripsheet_number, loaded_at: nil)

      success_response 'Tripsheet valid'
    end

    def complete_pallet_tripsheet(vehicle_job_id, print, printer) # rubocop:disable Metrics/AbcSize
      return failed_response('Please select a printer') if print == 't' && printer.nil_or_empty?

      repo.transaction do
        repo.update(:vehicle_jobs, vehicle_job_id, loaded_at: Time.now)
        repo.load_vehicle_job_units(vehicle_job_id)
        log_multiple_statuses(:pallets, repo.get_tripsheet_pallet_ids(vehicle_job_id), 'LOADED ON VEHICLE')
      end

      success_response('Tripsheet Completed Successfully')
    rescue StandardError => e
      failed_response(e.message)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def cancel_manual_tripsheet(vehicle_job_id) # rubocop:disable Metrics/AbcSize
      return failed_response('Cannot cancel. Tripsheet has already been offloaded') if repo.get(:vehicle_jobs, vehicle_job_id, :offloaded_at)
      return failed_response('Cannot cancel. Tripsheet has been completed') if repo.get(:vehicle_jobs, vehicle_job_id, :loaded_at)

      repo.transaction do
        tripsheet_pallets = repo.get_tripsheet_pallet_ids(vehicle_job_id)
        repo.delete_vehicle_job(vehicle_job_id)
        log_multiple_statuses(:pallets, tripsheet_pallets, 'MANUAL SHEET CANCELLED')
      end

      success_response "Tripsheet:#{vehicle_job_id} cancelled successfully"
    rescue StandardError => e
      failed_response(e.message)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def open_manual_tripsheet(vehicle_job_id)
      repo.transaction do
        repo.update(:vehicle_jobs, vehicle_job_id, loaded_at: nil)
      end

      success_response "Tripsheet:#{vehicle_job_id} is now open"
    rescue StandardError => e
      failed_response(e.message)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def create_intake_tripsheet(govt_inspection_sheet_id, params) # rubocop:disable Metrics/AbcSize
      res = validate_vehicle_job_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        vehicle_job_id = repo.create_vehicle_job(res)
        govt_inspection_pallets = repo.all_hash(:govt_inspection_pallets,  govt_inspection_sheet_id: govt_inspection_sheet_id)
        pallet_stock_type_id = MesscadaApp::MesscadaRepo.new.find_stock_type('PALLET')[:id]
        govt_inspection_pallets.each do |govt_inspection_pallet|
          unit_res = validate_vehicle_job_unit_params(stock_item_id: govt_inspection_pallet[:pallet_id], stock_type_id: pallet_stock_type_id,
                                                      vehicle_job_id: vehicle_job_id)
          raise Crossbeams::InfoError, unwrap_failed_response(validation_failed_response(unit_res)) if unit_res.failure?

          repo.create_vehicle_job_unit(unit_res)
          log_status(:pallets, govt_inspection_pallet[:pallet_id], 'ADDED TO INTAKE TRIPSHEET')
        end
        repo.update(:govt_inspection_sheets, govt_inspection_sheet_id, tripsheet_created: true, tripsheet_created_at: Time.now)
        log_status(:govt_inspection_sheets, govt_inspection_sheet_id, 'FIRST INTAKE TRIP SHEET CREATED')
        log_transaction
      end
      success_response('Intake Tripsheet Created')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def load_vehicle(govt_inspection_sheet_id) # rubocop:disable Metrics/AbcSize
      repo.transaction do
        vehicle_job_id = repo.get_id(:vehicle_jobs, govt_inspection_sheet_id: govt_inspection_sheet_id)
        repo.update(:vehicle_jobs, vehicle_job_id, loaded_at: Time.now)
        repo.load_vehicle_job_units(vehicle_job_id)
        repo.update(:govt_inspection_sheets, govt_inspection_sheet_id, tripsheet_loaded: true, tripsheet_loaded_at: Time.now)
        log_multiple_statuses(:pallets, repo.get_tripsheet_pallet_ids(vehicle_job_id), 'LOADED ON VEHICLE')
        log_status(:govt_inspection_sheets, govt_inspection_sheet_id, 'LOADED ON VEHICLE')
      end

      success_response('Vehicle Loaded Successfully')
    rescue StandardError => e
      failed_response(e.message)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def offloading_started?(govt_inspection_sheet_id)
      offloaded_pallets = repo.offloaded_vehicle_pallets(govt_inspection_sheet_id)
      success_response('ok', offloaded_pallets: offloaded_pallets)
    end

    def cancel_tripsheet(govt_inspection_sheet_id) # rubocop:disable Metrics/AbcSize
      return failed_response('Tripsheet has already been offloaded') if repo.get(:govt_inspection_sheets, govt_inspection_sheet_id, :tripsheet_offloaded)

      repo.transaction do
        vehicle_job_id = repo.get_id(:vehicle_jobs, govt_inspection_sheet_id: govt_inspection_sheet_id)
        tripsheet_pallets = repo.get_tripsheet_pallet_ids(vehicle_job_id)
        repo.delete_vehicle_job(vehicle_job_id)
        repo.update(:govt_inspection_sheets, govt_inspection_sheet_id, tripsheet_created: false, tripsheet_created_at: nil, tripsheet_loaded: false, tripsheet_loaded_at: nil)
        log_multiple_statuses(:pallets, tripsheet_pallets, 'INTAKE TRIP SHEET CANCELED')
        log_status(:govt_inspection_sheets, govt_inspection_sheet_id, 'INTAKE TRIP SHEET CANCELED')
      end

      success_response 'Tripsheet deleted successfully'
    rescue StandardError => e
      failed_response(e.message)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def refresh_tripsheet(govt_inspection_sheet_id) # rubocop:disable Metrics/AbcSize
      vehicle_job_id = repo.get_id(:vehicle_jobs, govt_inspection_sheet_id: govt_inspection_sheet_id)
      govt_inspection_pallets = repo.all_hash(:govt_inspection_pallets,  govt_inspection_sheet_id: govt_inspection_sheet_id)
      tripsheet_pallets = repo.get_vehicle_job_units(vehicle_job_id)

      unless tripsheet_pallets.map { |p| p[:stock_item_id] }.sort == govt_inspection_pallets.map { |p| p[:pallet_id] }.sort
        remove_vehicle_job_units = tripsheet_pallets.map { |p| p[:stock_item_id] } - govt_inspection_pallets.map { |p| p[:pallet_id] }
        new_vehicle_job_units = govt_inspection_pallets.map { |p| p[:pallet_id] } - tripsheet_pallets.map { |p| p[:stock_item_id] }

        repo.transaction do
          repo.delete(:vehicle_job_units, tripsheet_pallets.find_all { |p| remove_vehicle_job_units.include?(p[:stock_item_id]) }.map { |o| o[:id] }) unless remove_vehicle_job_units.empty?
          pallet_stock_type_id = MesscadaApp::MesscadaRepo.new.find_stock_type('PALLET')[:id]
          new_vehicle_job_units.each do |new_vehicle_job_unit|
            unit_res = validate_vehicle_job_unit_params(stock_item_id: new_vehicle_job_unit, stock_type_id: pallet_stock_type_id,
                                                        vehicle_job_id: vehicle_job_id)
            raise Crossbeams::InfoError, unwrap_failed_response(validation_failed_response(unit_res)) if unit_res.failure?

            repo.create_vehicle_job_unit(unit_res)
            log_status(:pallets, new_vehicle_job_unit, 'ADDED TO INTAKE TRIPSHEET')
          end
          log_status(:govt_inspection_sheets, govt_inspection_sheet_id, 'TRIPSHEET REFRESHED')

          complete_offload_vehicle(vehicle_job_id) if repo.tripsheet_offload_complete?(vehicle_job_id)
        end
      end

      success_response('Vehicle Refreshed Successfully')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def validate_offload_vehicle(vehicle_job_id, location_id) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      res = UtilityFunctions.validate_integer_length(:vehicle_job_id, vehicle_job_id)
      return failed_response('Invalid barcode. Perhaps a pallet was scanned?') if res.failure?

      vehicle_job = repo.find_vehicle_job(vehicle_job_id)
      return failed_response('Tripsheet does not exist') unless vehicle_job

      return failed_response('Tripsheet has already been offloaded') if vehicle_job[:offloaded_at]
      return failed_response('Vehicle not loaded') unless vehicle_job[:loaded_at]

      location = locn_repo.find_location(location_id)
      return failed_response('Location does not exist') if location.nil?

      return failed_response('Location does not store pallets') unless location[:storage_type_code] == 'PALLETS'
      return failed_response("Incorrect location scanned. Scanned tripsheet is destined for:#{locn_repo.find_location(vehicle_job[:planned_location_to_id])[:location_long_code]}") unless location_id.to_i == vehicle_job[:planned_location_to_id]

      success_response('')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def offload_vehicle_pallet(pallet_number) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      pallet = ProductionApp::ProductionRunRepo.new.find_pallet_by_pallet_number(pallet_number)
      return failed_response('Pallet does not exist') unless pallet
      return failed_response('Pallet has been scrapped') if pallet[:scrapped]
      return failed_response('Pallet has been shipped') if pallet[:shipped]

      vehicle_job_unit = repo.find_vehicle_job_unit_by(:stock_item_id, pallet[:id])
      return failed_response('Pallet is not on tripsheet') unless vehicle_job_unit

      instance = { vehicle_job_offloaded: false, vehicle_job_id: vehicle_job_unit[:vehicle_job_id] }
      unless vehicle_job_unit[:offloaded_at]
        repo.transaction do
          tripsheet_pallets = repo.get_vehicle_job_units(vehicle_job_unit[:vehicle_job_id])
          repo.update(:vehicle_job_units, vehicle_job_unit[:id], offloaded_at: Time.now)
          if (tripsheet_pallets.all.find_all { |p| !p[:offloaded_at] }).empty?
            #------------------------------------------------------------------------------------------------------------------------------------
            location_to_id = complete_offload_vehicle(vehicle_job_unit[:vehicle_job_id])
            instance.store(:vehicle_job_offloaded, true)
            instance.store(:pallets_moved, tripsheet_pallets.all.size)
            instance.store(:location, repo.get(:locations, location_to_id, :location_long_code))
          end
        end
      end

      success_response('Pallet Offloaded Successfully', instance)
    rescue StandardError => e
      failed_response(e.message)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def complete_offload_vehicle(vehicle_job_id) # rubocop:disable Metrics/AbcSize
      govt_inspection_sheet_id = repo.get(:vehicle_jobs, vehicle_job_id, :govt_inspection_sheet_id)
      repo.update(:vehicle_jobs, vehicle_job_id, offloaded_at: Time.now)
      repo.update(:govt_inspection_sheets, govt_inspection_sheet_id, tripsheet_offloaded: true, tripsheet_offloaded_at: Time.now)
      location_to_id = repo.get(:vehicle_jobs, vehicle_job_id, :planned_location_to_id)
      tripsheet_pallets = repo.get_vehicle_job_units(vehicle_job_id)
      tripsheet_pallets.each do |p|
        res = FinishedGoodsApp::MoveStockService.new(AppConst::PALLET_STOCK_TYPE, p[:stock_item_id], location_to_id, 'MOVE_PALLET', nil).call
        raise res.message unless res.success
      end
      repo.update(:pallets, tripsheet_pallets.map { |p| p[:stock_item_id] }, in_stock: true, stock_created_at: Time.now) if AppConst::CREATE_STOCK_AT_FIRST_INTAKE
      log_status(:govt_inspection_sheets, govt_inspection_sheet_id, 'TRIPSHEET OFFLOADED')

      location_to_id
    end

    def check(task, id = nil)
      TaskPermissionCheck::GovtInspectionSheet.call(task, id)
    end

    def check!(task, id = nil)
      res = TaskPermissionCheck::GovtInspectionSheet.call(task, id)
      raise Crossbeams::InfoError, res.message unless res.success
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::GovtInspectionSheet.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def find_govt_inspection_sheet(id)
      repo.find_govt_inspection_sheet(id)
    end

    def validate_add_pallet_govt_inspection_params(id, params) # rubocop:disable Metrics/AbcSize
      scanned = MesscadaApp::ScanCartonLabelOrPallet.call(params[:scanned_number])
      return scanned unless scanned.success

      pallet_number = scanned.pallet_number

      check_pallet!(:not_shipped, pallet_number)
      check_pallet!(:not_failed_otmc, pallet_number)
      check_pallet!(:full_build_status, pallet_number)
      check_pallet!(:verification_passed, pallet_number)
      check_pallet!(:pallet_weight, pallet_number)

      if repo.get(:govt_inspection_sheets, id, :reinspection)
        check_pallet!(:inspected, pallet_number)
      else
        check_pallet!(:not_on_inspection_sheet, pallet_number)
      end

      params[:pallet_id] = scanned.pallet_id
      params[:carton_id] = scanned.carton_id
      params[:govt_inspection_sheet_id] = id
      res = CreateGovtInspectionPalletSchema.call(params)
      return unwrap_failed_response(validation_failed_response(res)) if res.failure?

      success_response('Passed Validation', res.to_h)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def govt_inspection_sheet_packhouse_code(id)
      repo.govt_inspection_sheet_packhouse_code(id)
    end

    private

    def repo
      @repo ||= GovtInspectionRepo.new
    end

    def locn_repo
      MasterfilesApp::LocationRepo.new
    end

    def validate_vehicle_job_params(params)
      VehicleJobSchema.call(params)
    end

    def validate_manual_tripsheet_params(params)
      TripsheetSchema.call(params)
    end

    def validate_vehicle_job_unit_params(params)
      VehicleJobUnitSchema.call(params)
    end

    def validate_govt_inspection_sheet_params(params)
      GovtInspectionSheetSchema.call(params)
    end

    def check_pallet!(check, pallet_numbers)
      res = MesscadaApp::TaskPermissionCheck::Pallets.call(check, pallet_number: pallet_numbers)
      raise Crossbeams::InfoError, res.message unless res.success
    end
  end
end
