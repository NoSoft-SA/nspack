# frozen_string_literal: true

# rubocop:disable Metrics/AbcSize

module MasterfilesApp
  class PersonInteractor < BaseInteractor
    def create_person(params)
      res = validate_person_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      response = nil
      repo.transaction do
        response = repo.create_person(res)
      end
      if response[:id]
        @person_id = response[:id]
        success_response("Created person #{person.party_name}", person)
      else
        validation_failed_response(OpenStruct.new(messages: response[:error]))
      end
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { person: ['This person already exists'] }))
    end

    def update_person(id, params)
      @person_id = id
      res = validate_person_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      attrs = res.to_h
      role_ids = attrs.delete(:role_ids)
      roles_response = assign_person_roles(@person_id, role_ids)
      if roles_response.success
        repo.transaction do
          repo.update_person(id, attrs)
        end
        success_response("Updated person #{person.party_name}, #{roles_response.message}", person(false))
      else
        validation_failed_response(OpenStruct.new(messages: { roles: ['You did not choose a role'] }))
      end
    end

    def delete_person(id)
      @person_id = id
      name = person.party_name
      repo.transaction do
        repo.delete_person(id)
      end
      success_response("Deleted person #{name}")
    end

    def assign_person_roles(id, role_ids)
      return validation_failed_response(OpenStruct.new(messages: { roles: ['You did not choose a role'] })) if role_ids.empty?

      repo.transaction do
        repo.assign_roles(id, role_ids, 'P')
      end
      success_response('Roles assigned successfully')
    end

    private

    def repo
      @repo ||= PartyRepo.new
    end

    def person(cached = true)
      if cached
        @person ||= repo.find_person(@person_id)
      else
        @person = repo.find_person(@person_id)
      end
    end

    def validate_person_params(params)
      PersonSchema.call(params)
    end
  end
end
# rubocop:enable Metrics/AbcSize
