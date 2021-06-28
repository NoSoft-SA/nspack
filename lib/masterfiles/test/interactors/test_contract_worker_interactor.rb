# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestContractWorkerInteractor < MiniTestWithHooks
    include ProductionApp::ResourceFactory
    include MasterfilesApp::LocationFactory
    include HRFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::HumanResourcesRepo)
    end

    def test_contract_worker
      MasterfilesApp::HumanResourcesRepo.any_instance.stubs(:find_contract_worker).returns(fake_contract_worker)
      entity = interactor.send(:contract_worker, 1)
      assert entity.is_a?(ContractWorker)
    end

    def test_create_contract_worker
      attrs = fake_contract_worker.to_h.reject { |k, _| k == :id }
      res = interactor.create_contract_worker(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(ContractWorker, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_contract_worker_fail
      attrs = fake_contract_worker(first_name: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_contract_worker(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:first_name]
    end

    def test_update_contract_worker
      id = create_contract_worker
      attrs = interactor.send(:repo).find_hash(:contract_workers, id).reject { |k, _| k == :id }
      value = attrs[:first_name]
      attrs[:first_name] = 'a_change'
      res = interactor.update_contract_worker(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(ContractWorker, res.instance)
      assert_equal 'a_change', res.instance.first_name
      refute_equal value, res.instance.first_name
    end

    def test_update_contract_worker_fail
      id = create_contract_worker
      attrs = interactor.send(:repo).find_hash(:contract_workers, id).reject { |k, _| %i[id first_name].include?(k) }
      res = interactor.update_contract_worker(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:first_name]
    end

    def test_delete_contract_worker
      id = create_contract_worker
      assert_count_changed(:contract_workers, -1) do
        res = interactor.delete_contract_worker(id)
        assert res.success, res.message
      end
    end

    private

    def contract_worker_attrs
      employment_type_id = create_employment_type
      contract_type_id = create_contract_type
      wage_level_id = create_wage_level
      personnel_identifier_id = create_personnel_identifier
      shift_type_id = create_shift_type
      contract_worker_packer_role_id = create_contract_worker_packer_role

      {
        id: 1,
        employment_type_id: employment_type_id,
        contract_type_id: contract_type_id,
        wage_level_id: wage_level_id,
        first_name: Faker::Lorem.unique.word,
        surname: 'ABC',
        title: 'ABC',
        email: 'ABC',
        contact_number: 'ABC',
        personnel_number: 'ABC',
        start_date: '2010-01-01',
        end_date: '2010-01-01',
        personnel_identifier_id: personnel_identifier_id,
        shift_type_id: shift_type_id,
        packer_role_id: contract_worker_packer_role_id,
        shift_type_code: 'ABC',
        employment_type_code: 'ABC',
        contract_type_code: 'ABC',
        contract_worker_name: 'ABC',
        packer_role: 'ABC',
        wage_level: 1.2,
        active: true
      }
    end

    def fake_contract_worker(overrides = {})
      ContractWorker.new(contract_worker_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= ContractWorkerInteractor.new(current_user, {}, {}, {})
    end
  end
end
