# frozen_string_literal: true

module MasterfilesApp
  module TaskPermissionCheck
    class PmProduct < BaseService
      attr_reader :task, :entity
      def initialize(task, pm_product_id = nil)
        @task = task
        @repo = BomRepo.new
        @id = pm_product_id
        @entity = @id ? @repo.find_pm_product(@id) : nil
      end

      CHECKS = {
        create: :create_check,
        edit: :edit_check,
        delete: :delete_check
      }.freeze

      def call
        return failed_response 'Record not found' unless @entity || task == :create

        check = CHECKS[task]
        raise ArgumentError, "Task \"#{task}\" is unknown for #{self.class}" if check.nil?

        send(check)
      end

      private

      def create_check
        all_ok
      end

      def edit_check
        # return failed_response 'PmProduct has been completed' if completed?

        all_ok
      end

      def delete_check
        # return failed_response 'PmProduct has been completed' if completed?

        all_ok
      end
    end
  end
end
