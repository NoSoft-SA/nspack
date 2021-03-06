# frozen_string_literal: true

module MasterfilesApp
  class OrchardInteractor < BaseInteractor
    def create_orchard(params)
      res = validate_orchard_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_orchard(res)
        log_status(:orchards, id, 'CREATED')
        log_transaction
      end
      instance = orchard(id)
      success_response("Created orchard #{instance.orchard_code}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { orchard_code: ['This orchard already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_orchard(id, params)
      res = validate_orchard_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_orchard(id, res)
        log_transaction
      end
      instance = orchard(id)
      success_response("Updated orchard #{instance.orchard_code}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { orchard_code: ['This orchard already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_orchard(id)
      name = orchard(id).orchard_code
      repo.transaction do
        repo.delete_orchard(id)
        log_status(:orchards, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted orchard #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::Orchard.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def selected_farm_pucs(farm_id)
      repo.selected_farm_pucs(where: { farm_id: farm_id })
    end

    private

    def repo
      @repo ||= FarmRepo.new
    end

    def orchard(id)
      repo.find_orchard(id)
    end

    def validate_orchard_params(params)
      OrchardSchema.call(params)
    end
  end
end
