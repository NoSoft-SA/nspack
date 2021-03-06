# frozen_string_literal: true

module ProductionApp
  class ShiftInteractor < BaseInteractor
    def create_shift(params) # rubocop:disable Metrics/AbcSize
      extcols = select_extended_columns_params(params)
      res = validate_shift_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_shift(add_extended_columns_to_changeset(res, repo, extcols))
        log_status(:shifts, id, 'CREATED')
        log_transaction
      end
      instance = shift(id)
      success_response("Created shift #{instance.shift_type_code}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { base: ['This shift already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_shift(id, params) # rubocop:disable Metrics/AbcSize
      parms, extcols = unwrap_extended_columns_params(params)
      ext_res = validate_extended_columns(:shifts, params)
      res = validate_update_shift_params(parms)
      return mixed_validation_failed_response(res, ext_res) unless res.success? && ext_res.messages.empty?

      repo.check_if_shift_overlap!(res)
      repo.transaction do
        repo.update_shift(id,
                          add_extended_columns_to_changeset(res, repo, extcols))
        log_transaction
      end
      instance = shift(id)
      success_response("Updated shift #{instance.shift_type_code}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_shift(id)
      name = shift(id).id
      repo.transaction do
        repo.delete_shift(id)
        log_status(:shifts, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted shift #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::Shift.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def find_group_incentives_with(contract_worker_id)
      return validation_failed_response(messages: { contract_worker_id: ['Contract worker cannot be empty'] }) if contract_worker_id.nil_or_empty?

      incentive_group_ids = repo.find_group_incentives_with(contract_worker_id)
      return validation_failed_response(messages: { contract_worker_id: ['Contract worker does not belong to any incentive group'] }) if incentive_group_ids.nil_or_empty?

      success_response('ok', incentive_group_ids)
    end

    private

    def repo
      @repo ||= ProductionApp::HumanResourcesRepo.new
    end

    def shift(id)
      repo.find_shift(id)
    end

    def validate_shift_params(params)
      ShiftSchema.call(params)
    end

    def validate_update_shift_params(params)
      UpdateShiftSchema.call(params)
    end
  end
end
