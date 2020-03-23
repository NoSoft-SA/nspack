# frozen_string_literal: true

module MesscadaApp
  class MesscadaInteractor < BaseInteractor # rubocop:disable ClassLength
    # Take a scanned pallet number and convert it to a system pallet number
    # Sometimes a pallet scanned from an external supplier will not be a
    # valid SSCC format.
    def pallet_number_from_scan(scanned_pallet_number)
      ScannedPalletNumber.new(scanned_pallet_number: scanned_pallet_number).pallet_number
    end

    def validate_pallet_to_be_verified(scanned_pallet_number)
      pallet_number = pallet_number_from_scan(scanned_pallet_number)
      pallet_sequences = find_pallet_sequences_by_pallet_number(pallet_number)
      return failed_response("Scanned Pallet:#{pallet_number} doesn't exist") if pallet_sequences.empty?
      return failed_response("Scanned Pallet:#{pallet_number} has already been inspected") if pallet_sequences.first[:inspected]

      success_response('pallet found', oldest_pallet_sequence_id: pallet_sequences.first[:id])
    end

    def get_deck_pallets(location, location_scan_field)
      location_id = MasterfilesApp::LocationRepo.new.resolve_location_id_from_scan(location, location_scan_field)
      return failed_response('Location does not exist') if location_id.nil_or_empty?

      location = MasterfilesApp::LocationRepo.new.find_location(location_id)
      return failed_response("Location:#{location[:location_long_code]} is not a deck") unless location[:location_type_code] == AppConst::LOCATION_TYPES_COLD_BAY_DECK

      success_response('ok', pallets: locations_repo.get_deck_pallets(location_id), deck_code: location[:location_long_code])
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      puts e.backtrace.join("\n")
      failed_response(e.message)
    end

    def find_pallet_sequences_by_pallet_number(scanned_pallet_number)
      pallet_number = pallet_number_from_scan(scanned_pallet_number)
      repo.find_pallet_sequences_by_pallet_number(pallet_number)
    end

    def update_rmt_bin_weights(params) # rubocop:disable Metrics/AbcSize
      res = validate_update_rmt_bin_weights_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      MesscadaApp::UpdateBinWeights.call(res)
    rescue Crossbeams::InfoError => e
      ErrorMailer.send_exception_email(e, subject: "INFO: #{self.class.name}", message: decorate_mail_message('update_bin_weights'))
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message)
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message('update_bin_weights'))
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message)
    end

    def tip_rmt_bin(params) # rubocop:disable Metrics/AbcSize
      res = validate_tip_rmt_bin_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      repo.transaction do
        res = MesscadaApp::TipBin.new(res).call

        if res.success
          log_status('rmt_bins', res.instance[:rmt_bin_id], 'TIPPED')
          log_transaction
        end
        res
      end
    rescue Crossbeams::InfoError => e
      ErrorMailer.send_exception_email(e, subject: "INFO: #{self.class.name}", message: decorate_mail_message('tip_rmt_bin'))
      failed_response(e.message)
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message('tip_rmt_bin'))
      puts e.message
      puts e.backtrace.join("\n")
      failed_response("System error: #{e.message.gsub(/['"`<>]/, '')}")
    end

    def carton_labeling(params) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
      res = CartonLabelingSchema.call(params)
      return validation_failed_response(res) unless res.messages.empty?

      check_res = validate_device_exists(res[:device])
      return check_res unless check_res.success

      if res.to_h.key?(:identifier)
        check_res = validate_incentivised_labeling(res[:identifier])
        return check_res unless check_res.success
      end

      cvl_res = nil
      repo.transaction do
        cvl_res = MesscadaApp::CartonLabeling.call(res)
        log_transaction
      end
      cvl_res
    rescue Crossbeams::InfoError => e
      ErrorMailer.send_exception_email(e, subject: "INFO: #{self.class.name}", message: decorate_mail_message('carton_labeling')) if AppConst::ROBOT_DISPLAY_LINES != 4
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message)
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message('carton_labeling'))
      puts e
      puts e.backtrace.join("\n")
      failed_response(e.message)
    end

    def carton_verification(params)  # rubocop:disable Metrics/AbcSize
      res = CartonAndPalletVerificationSchema.call(params)
      return validation_failed_response(res) unless res.messages.empty?

      check_res = validate_carton_label_exists(res[:carton_number])
      return check_res unless check_res.success

      res = convert_pallet_no_to_carton_no(res) if AppConst::CARTON_EQUALS_PALLET

      cvl_res = nil
      repo.transaction do
        cvl_res = MesscadaApp::CartonVerification.call(@user, res)
        log_transaction
      end
      cvl_res
    rescue Crossbeams::InfoError => e
      ErrorMailer.send_exception_email(e, subject: "INFO: #{self.class.name}", message: decorate_mail_message('carton_verification'))
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message)
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message('carton_verification'))
      puts e
      puts e.backtrace.join("\n")
      failed_response(e.message)
    end

    def carton_verification_and_weighing(params)  # rubocop:disable Metrics/AbcSize
      res = CartonVerificationAndWeighingSchema.call(params)
      return validation_failed_response(res) unless res.messages.empty?

      check_res = validate_device_and_label_exist(res[:device], res[:carton_number])
      return check_res unless check_res.success

      res = convert_pallet_no_to_carton_no(res) if AppConst::CARTON_EQUALS_PALLET

      cvl_res = nil
      repo.transaction do
        cvl_res = MesscadaApp::CartonVerification.call(@user, res)
        cvl_res = MesscadaApp::CartonWeighing.call(res)
        log_transaction
      end
      cvl_res
    rescue Crossbeams::InfoError => e
      ErrorMailer.send_exception_email(e, subject: "INFO: #{self.class.name}", message: decorate_mail_message('carton_verification_and_weighing'))
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message)
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message('carton_verification_and_weighing'))
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message)
    end

    def carton_verification_and_weighing_and_labeling(params, request_ip)  # rubocop:disable Metrics/AbcSize
      res = CartonVerificationAndWeighingSchema.call(params)
      return validation_failed_response(res) unless res.messages.empty?

      check_res = validate_device_and_label_exist(res[:device], res[:carton_number])
      return check_res unless check_res.success

      res = convert_pallet_no_to_carton_no(res) if AppConst::CARTON_EQUALS_PALLET

      cvl_res = nil
      repo.transaction do
        cvl_res = MesscadaApp::CartonVerification.call(@user, res)
        cvl_res = MesscadaApp::CartonWeighing.call(res)
        cvl_res = MesscadaApp::CartonLabelPrinting.call(res, request_ip)
        log_transaction
      end
      cvl_res
    rescue Crossbeams::InfoError => e
      ErrorMailer.send_exception_email(e, subject: "INFO: #{self.class.name}", message: decorate_mail_message('carton_verification_and_weighing_and_labeling'))
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message)
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message('carton_verification_and_weighing_and_labeling'))
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message)
    end

    def find_pallet_sequences_from_same_pallet(id)
      repo.find_pallet_sequences_from_same_pallet(id)
    end

    def find_pallet_sequence_attrs(id)
      repo.find_pallet_sequence_attrs(id)
    end

    def verify_pallet_sequence(pallet_sequence_id, params) # rubocop:disable Metrics/AbcSize
      return validation_failed_response(messages: { verification_failure_reason: ['is missing'] }) if params[:verification_result] == 'failed' && params[:verification_failure_reason].nil_or_empty?

      pallet_id = get_pallet_sequence_pallet_id(pallet_sequence_id)
      changeset = pallet_changes_on_verify(params)

      repo.transaction do
        update_pallet_sequence_verification_result(pallet_sequence_id, params)

        repo.update_pallet(pallet_id, changeset) unless changeset.empty?
        log_transaction
      end

      verification_completed = pallet_verified?(pallet_id)
      success_response('Pallet Sequence updated successfully', verification_completed: verification_completed)
    rescue Crossbeams::InfoError => e
      ErrorMailer.send_exception_email(e, subject: "INFO: #{self.class.name}", message: decorate_mail_message('verify_pallet_sequence'))
      failed_response(e.message)
    end

    def get_pallet_sequence_pallet_id(id)
      repo.get(:pallet_sequences, id, :pallet_id)
    end

    def get_pallet_by_carton_label_id(carton_label_id)
      repo.get_pallet_by_carton_label_id(carton_label_id)
    end

    def pallet_exists?(pallet_number)
      repo.pallet_exists?(pallet_number)
    end

    def fg_pallet_weighing(params)  # rubocop:disable Metrics/AbcSize
      params[:bin_number] = MesscadaApp::ScannedPalletNumber.new(scanned_pallet_number: params[:bin_number]).pallet_number
      res = FgPalletWeighingSchema.call(params)
      return validation_failed_response(res) unless res.messages.empty?

      pallet_number = res[:bin_number]

      return failed_response("Pallet Number :#{pallet_number} could not be found") unless pallet_exists?(pallet_number)

      fpw_res = nil
      repo.transaction do
        fpw_res = MesscadaApp::FgPalletWeighing.call(res)
        log_status('pallets', fpw_res.instance[:pallet_id], AppConst::PALLET_WEIGHED)
        log_transaction
      end
      fpw_res
    rescue Crossbeams::InfoError => e
      ErrorMailer.send_exception_email(e, subject: "INFO: #{self.class.name}", message: decorate_mail_message('fg_pallet_weighing'))
      failed_response(e.message)
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message('fg_pallet_weighing'))
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message)
    end

    def repack_pallet(pallet_id) # rubocop:disable Metrics/AbcSize
      pallet = reworks_repo.pallet(pallet_id)
      return validation_failed_response(messages: { pallet_number: ['Pallet does not exist'] }) unless pallet

      res = nil
      repo.transaction do
        res = FinishedGoodsApp::RepackPallet.call(pallet_id, @user.user_name)
        repo.log_status('pallets', pallet_id, AppConst::REWORKS_REPACK_PALLET_STATUS)
        repo.log_multiple_statuses('pallet_sequences', reworks_repo.pallet_sequence_ids(pallet_id), AppConst::REWORKS_REPACK_PALLET_STATUS)
        repo.log_status('pallets', res.instance[:new_pallet_id], AppConst::REWORKS_REPACK_PALLET_NEW_STATUS)
        repo.log_multiple_statuses('pallet_sequences', reworks_repo.pallet_sequence_ids(res.instance[:new_pallet_id]), AppConst::REWORKS_REPACK_PALLET_STATUS)
      end
      res
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      puts e.backtrace.join("\n")
      failed_response(e.message)
    end

    def pallet_sequence_ids(pallet_id)
      reworks_repo.pallet_sequence_ids(pallet_id)
    end

    private

    def pallet_changes_on_verify(params)
      changeset = {}
      changeset[:fruit_sticker_pm_product_id] = params[:fruit_sticker_pm_product_id] unless params[:fruit_sticker_pm_product_id].nil_or_empty?
      changeset[:fruit_sticker_pm_product_2_id] = params[:fruit_sticker_pm_product_2_id] unless params[:fruit_sticker_pm_product_2_id].nil_or_empty?

      changeset[:gross_weight] = params[:gross_weight] if AppConst::CAPTURE_PALLET_WEIGHT_AT_VERIFICATION

      if AppConst::PALLET_IS_IN_STOCK_WHEN_VERIFIED
        changeset[:in_stock] = true
        changeset[:stock_created_at] = Time.now
      end
      changeset
    end

    def update_pallet_sequence_verification_result(pallet_sequence_id, params)
      repo.update_pallet_sequence_verification_result(pallet_sequence_id, params)
    end

    def pallet_verified?(pallet_id)
      repo.pallet_verified?(pallet_id)
    end

    def repo
      @repo ||= MesscadaRepo.new
    end

    def production_run_repo
      @production_run_repo ||= ProductionApp::ProductionRunRepo.new
    end

    def reworks_repo
      @reworks_repo ||= ProductionApp::ReworksRepo.new
    end

    def locations_repo
      @reworks_repo ||= MasterfilesApp::LocationRepo.new
    end

    # TODO: split validation if using asset no or not (string asset vs int id)
    def validate_update_rmt_bin_weights_params(params)
      # For now: bin asset is integer, so strip Habata's SK prefix. LATER make this a string.
      # UpdateRmtBinWeightsSchema.call(params.transform_values { |v| v.match?(/SK/) ? v.sub('SK', '') : v })
      UpdateRmtBinWeightsSchema.call(params)
    end

    # TODO: split validation if using asset no or not (string asset vs int id)
    def validate_tip_rmt_bin_params(params)
      # For now: bin asset is integer, so strip Habata's SK prefix. LATER make this a string.
      # TipRmtBinSchema.call(params.transform_values { |v| v.match?(/SK/) ? v.sub('SK', '') : v })
      TipRmtBinSchema.call(params)
    end

    def resource_code_exists?(resource_code)
      repo.resource_code_exists?(resource_code)
    end

    def identifier_exists?(identifier)
      repo.identifier_exists?(identifier)
    end

    def carton_label_exists?(carton_label_id)
      repo.carton_label_exists?(carton_label_id)
    end

    def carton_label_exists_for_pallet?(pallet_no)
      !repo.carton_label_id_for_pallet_no(pallet_no).nil?
    end

    def validate_carton_label_exists(carton_id_or_pallet_no)
      if AppConst::CARTON_EQUALS_PALLET
        return failed_response("Bin label:#{carton_id_or_pallet_no} could not be found") unless carton_label_exists_for_pallet?(carton_id_or_pallet_no)
      else
        return failed_response("Carton label:#{carton_id_or_pallet_no} could not be found") unless carton_label_exists?(carton_id_or_pallet_no)
      end

      ok_response
    end

    def validate_device_exists(resource_code)
      return failed_response("Resource Code:#{resource_code} could not be found") unless resource_code_exists?(resource_code)

      ok_response
    end

    def validate_incentivised_labeling(identifier)
      return failed_response('Not logged in') unless identifier_exists?(identifier)

      ok_response
    end

    def validate_device_and_label_exist(device, carton_id_or_pallet_no)
      res1 = validate_device_exists(device)
      return res1 unless res1.success

      res2 = validate_carton_label_exists(carton_id_or_pallet_no)
      return res2 unless res2.success

      ok_response
    end

    def convert_pallet_no_to_carton_no(res)
      out = res.to_h
      out[:carton_number] = repo.carton_label_id_for_pallet_no(res[:carton_number])
      out
    end

    def get_pallet_label_data(pallet_id)
      production_run_repo.get_pallet_label_data(pallet_id)
    end
  end
end
