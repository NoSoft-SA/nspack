# frozen_string_literal: true

module MasterfilesApp
  class PersonInteractor < BaseInteractor
    def create_person(params)
      res = validate_person_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_person(res)
        log_status(:people, id, 'CREATED')
        log_transaction
      end
      instance = person(id)
      success_response("Created person #{instance.party_name}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { first_name: ['This person already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_person(id, params)
      res = validate_person_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_person(id, res)
        log_transaction
      end
      instance = person(id)
      success_response("Updated person #{instance.party_name}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_person(id)
      name = person(id).party_name
      repo.transaction do
        repo.delete_person(id)
        log_status(:people, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted person #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete person. It is still referenced#{e.message.partition('referenced').last}")
    end
    private

    def repo
      @repo ||= PartyRepo.new
    end

    def person(id)
      repo.find_person(id)
    end

    def validate_person_params(params)
      PersonSchema.call(params)
    end
  end
end
