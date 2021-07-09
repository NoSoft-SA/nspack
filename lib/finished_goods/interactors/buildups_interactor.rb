# frozen_string_literal: true

module FinishedGoodsApp
  class BuildupsInteractor < BaseInteractor # rubocop:disable Metrics/ClassLength
    def process_to_rejoin(params) # rubocop:disable Metrics/AbcSize
      dest = params[:pallet_number]
      source = params.select { |k, v| !v.nil_or_empty? && !k.to_s.include?('_scan_field') && !k.to_s.include?('qty_to_move') && !k.to_s.include?('pallet_number') }.values
      repo.get_process_to_rejoin(dest, source, @user.user_name)
    end

    def process_to_cancel(params) # rubocop:disable Metrics/AbcSize
      pallets = params.select { |k, v| !v.nil_or_empty? && !k.to_s.include?('_scan_field') && !k.to_s.include?('qty_to_move') }.values
      if (uncompleted_process = repo.get_process_to_cancel(pallets, @user.user_name))
        return success_response('', { process: uncompleted_process, pallets: (uncompleted_process[:source_pallets] + [uncompleted_process[:destination_pallet_number]]) & pallets })
      end

      failed_response('no uncompleted processes found')
    end

    def buildup_pallet(params) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      params.delete_if { |k, v| v.nil_or_empty? || k.to_s.include?('_scan_field') }
      qty_to_move = params.delete(:qty_to_move).to_i

      non_existing = params.values - repo.get_pallets(params.values)
      return validation_failed_response(messages: error_messages(params, non_existing, "doesn't exist")) unless non_existing.empty?

      duplicates = params.values.find_all { |e| params.values.count(e) > 1 }.uniq
      return validation_failed_response(messages: error_messages(params, duplicates, 'is duplicate scan')) unless duplicates.empty?

      error_msgs = !(err = validate_shipped(params)).empty? ? error_messages(params, err, 'is shipped') : {}
      error_msgs.merge!(!(err = validate_scrapped(params)).empty? ? error_messages(params, err, 'is scrapped') : {})
      return validation_failed_response(messages: error_msgs) unless error_msgs.empty?

      error_msgs = !(err = validate_zero_qty(params)).empty? ? error_messages(params, err, 'has 0 ctn_qty') : {}
      return validation_failed_response(messages: error_msgs) unless error_msgs.empty?

      error_msgs = !(err = validate_pallets_not_busy(params)).empty? ? error_messages(params, err, 'is busy') : {}
      return validation_failed_response(messages: error_msgs) unless error_msgs.empty?

      to_pallet = params.delete(:pallet_number)
      return failed_response("There's not enough cartons to move") if repo.pallets_ctn_qty_sum(params.values) < qty_to_move

      id = nil
      repo.transaction do
        id = repo.create_pallet_buildup(destination_pallet_number: to_pallet, source_pallets: "{#{params.values.join(',')}}", qty_cartons_to_move: qty_to_move, created_by: @user.user_name, cartons_moved: {}.to_json)
        log_transaction
      end
      instance = pallet_buildup(id)
      success_response("Created pallet buildup #{instance.destination_pallet_number}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def move_carton(params, pallet_buildup_id) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      return validation_failed_response(messages: { carton_number: ['field cannot be empty'] }) if params[:carton_number].nil_or_empty?

      res = MesscadaApp::ScanCartonLabelOrPallet.call(params[:carton_number])
      return res unless res.success

      params[:carton_number] = res.instance.carton_label_id
      carton = ProductionApp::ProductionRunRepo.new.find_carton_by_carton_label_id(params[:carton_number])
      return failed_response("Carton:#{params[:carton_number]} does not exist") unless carton
      return failed_response("Carton:#{params[:carton_number]} does not belong to any of the source pallets") unless repo.buildup_carton?(params[:carton_number], pallet_buildup_id)

      # Remove Carton
      pallet_buildup = pallet_buildup(pallet_buildup_id)
      if (pallet = pallet_buildup.cartons_moved.find { |_k, v| v.include?(params[:carton_number]) })
        pallet_buildup.cartons_moved[pallet[0]].delete(params[:carton_number])
        pallet_buildup.cartons_moved.delete(pallet[0]) if pallet_buildup.cartons_moved[pallet[0]].to_a.empty?
      else
        # Add Carton
        pallet_number = repo.find_pallet_by_carton_label_id(params[:carton_number])
        pallet_buildup.cartons_moved.store(pallet_number, []) unless pallet_buildup.cartons_moved[pallet_number]
        pallet_buildup.cartons_moved[pallet_number].push(params[:carton_number])
      end
      repo.update(:pallet_buildups, pallet_buildup_id, cartons_moved: pallet_buildup.cartons_moved)

      success_response('ok', pallet_buildup)
    end

    def delete_pallet_buildup(id)
      repo.transaction do
        repo.delete_pallet_buildup(id)
        log_transaction
      end
      success_response("Deleted pallet buildup #{id}")
    rescue StandardError => e
      failed_response(e.message)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete pallet buildup. It is still referenced#{e.message.partition('referenced').last}")
    end

    def complete_pallet_buildup(id) # rubocop:disable Metrics/AbcSize
      repo.transaction do
        pallet_buildup = pallet_buildup(id)
        unless pallet_buildup.completed
          dest_pallet = repo.get_value(:pallets, :id, pallet_number: pallet_buildup.destination_pallet_number)
          pallet_buildup.cartons_moved.each do |_k, v|
            v.each do |cl_id|
              res = MesscadaApp::TransferCarton.call(ProductionApp::ProductionRunRepo.new.find_carton_by_carton_label_id(cl_id)[:id], dest_pallet)
              return res unless res.success
            end
          end
          repo.update(:pallet_buildups, id, completed: true, completed_at: Time.now)
        end

        if AppConst::CR_FG.lookup_extended_fg_code?
          pallet_ids = repo.select_values(:pallets, :id, pallet_number: [pallet_buildup.destination_pallet_number] + pallet_buildup.source_pallets)
          FinishedGoodsApp::Job::CalculateExtendedFgCodes.enqueue(pallet_ids)
        end

        success_response("Pallet buildup:#{id} has been completed successfully")
      end
    rescue StandardError => e
      failed_response(e.message)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def pallet_buildup(id)
      repo.find_pallet_buildup(id)
    end

    private

    def validate_pallet_buildup_params(params)
      PalletBuildupSchema.call(params)
    end

    def validate_shipped(params)
      repo.get_shipped(params.values)
    end

    def validate_scrapped(params)
      repo.get_scrapped(params.values)
    end

    def validate_zero_qty(params)
      repo.get_zero_qty_pallets(params.values)
    end

    def validate_pallets_not_busy(params)
      repo.get_build_up_pallets(params.values)
    end

    def error_messages(params, pallets, status)
      errors = {}
      pallets.each do |p|
        params.find_all { |_k, v| v == p }.each do |pp|
          errors.store(pp[0], ["#{pp[1]} #{status}"])
        end
      end
      errors
    end

    def repo
      @repo ||= BuildupsRepo.new
    end
  end
end
