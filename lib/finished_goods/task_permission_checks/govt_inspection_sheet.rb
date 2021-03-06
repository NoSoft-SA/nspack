# frozen_string_literal: true

module FinishedGoodsApp
  module TaskPermissionCheck
    class GovtInspectionSheet < BaseService
      attr_reader :task, :entity, :repo, :id
      def initialize(task, govt_inspection_sheet_id = nil)
        @task = task
        @repo = GovtInspectionRepo.new
        @id = govt_inspection_sheet_id
      end

      CHECKS = {
        create: :create_check,
        edit: :edit_check,
        delete: :delete_check,
        capture: :capture_check,
        add_pallet: :add_pallet_check,
        complete: :complete_check,
        uncomplete: :uncomplete_check,
        finish: :finish_check,
        cancel: :cancel_check,
        reopen: :reopen_check,
        titan_inspection: :titan_inspection_check
      }.freeze

      def call
        return failed_response "Value #{id} is too big to be a Inspection Sheet. Perhaps you scanned a pallet number?" if id.to_i > AppConst::MAX_DB_INT

        @entity = @repo.find_govt_inspection_sheet(id)
        return failed_response 'Govt Inspection Sheet record not found.' unless @entity || task == :create

        check = CHECKS[task]
        raise ArgumentError, "Task \"#{task}\" is unknown for #{self.class}" if check.nil?

        send(check)
      end

      private

      def create_check
        all_ok
      end

      def edit_check
        return failed_response 'Govt Inspection Sheet has been finished.' if inspected?

        all_ok
      end

      def delete_check
        return failed_response 'Govt Inspection Sheet has been completed.' if completed?

        all_ok
      end

      def add_pallet_check
        return failed_response 'Govt Inspection Sheet has already been completed.' if completed?

        all_ok
      end

      def complete_check
        return failed_response 'Govt Inspection Sheet has already been completed.' if completed?
        return failed_response('Inspection sheet must have at least one pallet attached.') unless allocated?

        all_ok
      end

      def uncomplete_check
        return failed_response 'Govt Inspection Sheet has not been completed.' unless completed?

        all_ok
      end

      def reopen_check
        pallet_ids = @repo.select_values(:govt_inspection_pallets, :pallet_id, govt_inspection_sheet_id: id)
        shipped_pallets = @repo.exists?(:pallets, id: pallet_ids, shipped: true)
        return failed_response "Govt Inspection Sheet can't be reopened, already shipped." if shipped_pallets
        return failed_response 'Govt Inspection Sheet has not been inspected.' unless inspected?

        all_ok
      end

      def capture_check
        return failed_response 'Govt Inspection Sheet has already been inspected.' if inspected?

        all_ok
      end

      def finish_check
        pallet_ids = @repo.select_values(:govt_inspection_pallets, :pallet_id, govt_inspection_sheet_id: id, inspected: false)
        pallet_numbers = @repo.select_values(:pallets, :pallet_number, id: pallet_ids)
        return failed_response "Pallet: #{pallet_numbers.first(3).join(', ')}, results not captured." unless pallet_numbers.empty?

        all_ok
      end

      def cancel_check
        return failed_response 'Govt Inspection Sheet has not been inspected.' unless inspected?

        all_ok
      end

      def titan_inspection_check
        all_ok
      end

      def completed?
        @entity&.completed
      end

      def allocated?
        @entity&.allocated
      end

      def inspected?
        @entity&.inspected
      end

      def approved?
        @entity&.approved
      end
    end
  end
end
