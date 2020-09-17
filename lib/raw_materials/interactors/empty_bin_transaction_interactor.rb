# frozen_string_literal: true

module RawMaterialsApp
  class EmptyBinTransactionInteractor < BaseInteractor # rubocop:disable Metrics/ClassLength
    def create_empty_bin_transaction # rubocop:disable Metrics/AbcSize
      res = validate_stepper
      return res unless res.success

      parent_id = nil
      info = OpenStruct.new(res.instance.merge(parent_transaction_id: parent_id,
                                               rmt_delivery_id: res.instance[:fruit_reception_delivery_id],
                                               ref_no: res.instance[:reference_number],
                                               user_name: @user.user_name))
      repo.transaction do
        info.bin_sets.each do |set|
          info.parent_transaction_id = parent_id
          res = perform_bin_operation(set, info)
          raise Crossbeams::InfoError, res.message unless res.success

          parent_id = res.instance[:parent_transaction_id] if res.instance.is_a?(Hash)
          parent_id ||= empty_bin_transaction_item(res.instance)&.empty_bin_transaction_id
        end
      end
      log_status(:empty_bin_transactions, parent_id, 'CREATED')
      log_transaction
      instance = empty_bin_transaction(parent_id)
      success_response('Empty Bin Transaction Successful', instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { truck_registration_number: ['This empty bin transaction already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::EmptyBinTransaction.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def truck_registration_number(delivery_id)
      repo.truck_registration_number_for_delivery(delivery_id)
    end

    def stepper
      @stepper ||= EmptyBinControlStep.new(@user, @context.request_ip, repo)
    end

    def rmt_container_material_types(owner_party_role_id)
      repo.options_for_rmt_container_material_types(owner_party_role_id)
    end

    def validate_receive_params(params)
      res = ReceiveEmptyBinSchema.call(params)
      res.success? ? ok_response : adjusted_failed_response(res)
    end

    def validate_issue_params(params)
      res = IssueEmptyBinSchema.call(params)
      res.success? ? ok_response : adjusted_failed_response(res)
    end

    def validate_adhoc_params(params)
      res = AdhocEmptyBinSchema.call(params)
      res.success? ? ok_response : adjusted_failed_response(res)
    end

    def validate_adhoc_create_params(params)
      res = AdhocCreateEmptyBinSchema.call(params)
      res.success? ? ok_response : adjusted_failed_response(res)
    end

    def validate_adhoc_destroy_params(params)
      res = AdhocDestroyEmptyBinSchema.call(params)
      res.success? ? ok_response : adjusted_failed_response(res)
    end

    def adjusted_failed_response(res)
      res = validation_failed_response(res)
      errors = []
      errors << 'System Asset Transaction Types are missing.' if res.errors[:asset_transaction_type_id]
      errors << 'System Business Processes are missing.' if res.errors[:business_process_id]
      res.errors[:base] = errors if errors.any?
      res
    end

    def validate_stepper # rubocop:disable Metrics/AbcSize
      hash = stepper.read
      unless hash[:bin_sets].nil_or_empty? || hash[:create]
        res = repo.validate_empty_bin_location_quantities(hash[:empty_bin_from_location_id], hash[:bin_sets])
        return res unless res.success
      end

      qty = hash[:quantity_bins].to_i
      return success_response('ok', hash) if qty == (total_qty = stepper.bin_sets.map { |set| set[:quantity_bins].to_i }.sum)

      x = qty - total_qty
      message = "Quantity Bins do not equate to total bins added. Please #{x.positive? ? 'add' : 'remove'} #{x.abs} bins."
      validation_failed_response(OpenStruct.new(messages: { base: [message] }, instance: hash))
    end

    def get_applicable_transaction_item_ids(location_id)
      repo.get_applicable_transaction_item_ids(location_id)
    end

    private

    def repo
      @repo ||= EmptyBinsRepo.new
    end

    def empty_bin_transaction(id)
      repo.find_empty_bin_transaction(id)
    end

    def empty_bin_transaction_item(item_id)
      repo.find_empty_bin_transaction_item(item_id)
    end

    def perform_bin_operation(set, info) # rubocop:disable Metrics/AbcSize
      owner_id = repo.get_owner_id(set)
      if info.destroy
        DestroyEmptyBins.call(owner_id, info.empty_bin_from_location_id, set[:quantity_bins].to_i, info.to_h)
      elsif info.create
        CreateEmptyBins.call(info.quantity_bins, info.empty_bin_to_location_id, info.ref_no, [set], info.to_h)
      else
        MoveEmptyBins.call(owner_id, set[:quantity_bins].to_i, info.empty_bin_to_location_id, info.empty_bin_from_location_id, info.to_h)
      end
    end
  end
end
