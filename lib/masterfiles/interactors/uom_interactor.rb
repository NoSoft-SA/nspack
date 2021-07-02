# frozen_string_literal: true

module MasterfilesApp
  class UomInteractor < BaseInteractor
    def create_uom(params) # rubocop:disable Metrics/AbcSize
      attrs = params.to_h.merge(uom_type_id: repo.default_uom_type_id)
      res = validate_uom_params(attrs)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_uom(res)
        log_status(:uoms, id, 'CREATED')
        log_transaction
      end
      instance = uom(id)
      success_response("Created UOM #{instance.uom_code}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { uom_code: ['This UOM already exists'] }))
    end

    def update_uom(id, params)
      attrs = params.to_h.merge(uom_type_id: repo.default_uom_type_id)
      res = validate_uom_params(attrs)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_uom(id, res)
        log_transaction
      end
      instance = uom(id)
      success_response("Updated UOM #{instance.uom_code}", instance)
    end

    def delete_uom(id)
      name = uom(id).uom_code
      repo.transaction do
        repo.delete_uom(id)
        log_status(:uoms, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted UOM #{name}")
    end

    private

    def repo
      @repo ||= GeneralRepo.new
    end

    def uom(id)
      repo.find_uom(id)
    end

    def validate_uom_params(params)
      UomSchema.call(params)
    end
  end
end
