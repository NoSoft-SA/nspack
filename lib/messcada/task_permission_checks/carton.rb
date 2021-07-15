# frozen_string_literal: true

module MesscadaApp
  module TaskPermissionCheck
    class Carton < BaseService
      attr_reader :tasks, :repo, :carton_ids
      def initialize(tasks, args)
        @tasks = Array(tasks)
        @args = args
        @repo = MesscadaRepo.new
        @check_carton_ids = Array(@args[:carton_id] || @args[:carton_ids]).flatten
      end

      CHECKS = {
        exists: :exists_check
      }.freeze

      def call
        res = exists_check
        return res unless res.success

        tasks.each do |task|
          check = CHECKS[task]
          raise ArgumentError, "Task \"#{task}\" is unknown for #{self.class}." if check.nil?

          res = send(check)
          return res unless res.success
        end
        all_ok
      end

      private

      def exists_check
        unless @check_carton_ids.empty?
          @carton_ids = repo.select_values(:cartons, :id, id: @check_carton_ids)
          errors = @check_carton_ids - carton_ids
          return failed_response "Carton id: #{errors.join(', ')} doesn't exist." unless errors.empty?
        end

        return failed_response 'No cartons where given to check.' if carton_ids.nil_or_empty?

        all_ok
      end
    end
  end
end
