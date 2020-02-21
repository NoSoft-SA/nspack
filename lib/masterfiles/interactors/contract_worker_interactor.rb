# frozen_string_literal: true

module MasterfilesApp
  class ContractWorkerInteractor < BaseInteractor
    def create_contract_worker(params) # rubocop:disable Metrics/AbcSize
      res = validate_contract_worker_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      id = nil
      repo.transaction do
        id = repo.create_contract_worker(res)
        log_status(:contract_workers, id, 'CREATED')
        log_transaction
      end
      instance = contract_worker(id)
      success_response("Created contract worker #{instance.full_names}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { full_names: ['This contract worker already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_contract_worker(id, params)
      res = validate_contract_worker_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      repo.transaction do
        repo.update_contract_worker(id, res)
        log_transaction
      end
      instance = contract_worker(id)
      success_response("Updated contract worker #{instance.full_names}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_contract_worker(id)
      name = contract_worker(id).full_names
      repo.transaction do
        repo.delete_contract_worker(id)
        log_status(:contract_workers, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted contract worker #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::ContractWorker.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def link_to_personnel_identifier(id, params)
      repo.transaction do
        repo.update_contract_worker(params[:contract_worker_id], personnel_identifier_id: id)
        repo.update(:personnel_identifiers, id, in_use: true)
        # log status?
      end

      success_response('Successfully linked identifier to worker', in_use: true, contract_worker: contract_worker(params[:contract_worker_id])[:contract_worker_name])
    end

    private

    def repo
      @repo ||= HumanResourcesRepo.new
    end

    def contract_worker(id)
      repo.find_contract_worker(id)
    end

    def validate_contract_worker_params(params)
      ContractWorkerSchema.call(params)
    end
  end
end
