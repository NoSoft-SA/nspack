# frozen_string_literal: true

module MesscadaApp
  module TaskPermissionCheck
    class Pallets < BaseService # rubocop:disable Metrics/ClassLength
      attr_reader :tasks, :pallet_ids, :repo, :load_id, :order_id
      def initialize(tasks, args)
        @tasks = Array(tasks)
        @args = args
        @repo = MesscadaRepo.new
        @load_id = @args[:load_id]
        @order_id = @args[:order_id]
      end

      CHECKS = {
        exists: :exists_check,
        not_scrapped: :not_scrapped_check,
        not_shipped: :not_shipped_check,
        shipped: :shipped_check,
        in_stock: :in_stock_check,
        has_nett_weight: :nett_weight_check,
        has_gross_weight: :gross_weight_check,
        not_on_load: :not_on_load_check,
        not_on_inspection_sheet: :not_on_inspection_sheet_check,
        inspected: :inspected_check,
        not_inspected: :not_inspected_check,
        not_failed_otmc: :not_failed_otmc_check,
        full_build_status: :full_build_status_check,
        verification_passed: :verification_passed_check,
        pallet_weight: :pallet_weight_check,
        rmt_grade: :rmt_grade_check,
        allocate: :allocate_check,
        not_have_individual_cartons: :not_have_individual_cartons_check,
        order_spec: :order_spec_check
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

      def exists_check # rubocop:disable Metrics/AbcSize
        if @args[:pallet_number]
          @pallet_ids = repo.select_values(:pallets, :id, pallet_number: @args[:pallet_number])
          pallets_exists = repo.select_values(:pallets, :pallet_number, id: pallet_ids)
          errors = Array(@args[:pallet_number]) - pallets_exists
          return failed_response "Pallet: #{errors.join(', ')} doesn't exist." unless errors.empty?
        end

        if @args[:pallet_id]
          @pallet_ids = repo.select_values(:pallets, :id, pallet_number: @args[:pallet_id])
          errors = Array(@args[:pallet_id]) - pallet_ids
          return failed_response "Pallet id: #{errors.join(', ')} doesn't exist." unless errors.empty?
        end

        return failed_response 'No pallets found.' if pallet_ids.nil_or_empty?

        all_ok
      end

      def not_scrapped_check
        errors = repo.select_values(:pallets, :pallet_number, id: pallet_ids, scrapped: true)
        return failed_response "Pallet: #{errors.join(', ')} has been scrapped." unless errors.empty?

        all_ok
      end

      def not_shipped_check
        errors = repo.select_values(:pallets, :pallet_number, id: pallet_ids, shipped: true)
        return failed_response "Pallet: #{errors.join(', ')} already shipped." unless errors.empty?

        all_ok
      end

      def shipped_check
        errors = repo.select_values(:pallets, :pallet_number, id: pallet_ids, shipped: false)
        return failed_response "Pallet: #{errors.join(', ')} not shipped." unless errors.empty?

        all_ok
      end

      def in_stock_check
        errors = repo.select_values(:pallets, :pallet_number, id: pallet_ids, in_stock: false)
        return failed_response "Pallet: #{errors.join(', ')} not in stock." unless errors.empty?

        all_ok
      end

      def nett_weight_check
        errors = repo.select_values(:pallets, :pallet_number, id: pallet_ids, nett_weight: nil)
        return failed_response "Pallet: #{errors.join(', ')} does not have nett weight." unless errors.empty?

        all_ok
      end

      def gross_weight_check
        errors = repo.select_values(:pallets, :pallet_number, id: pallet_ids, gross_weight: nil)
        return failed_response "Pallet: #{errors.join(', ')} does not have gross weight." unless errors.empty?

        all_ok
      end

      def not_on_load_check
        raise ArgumentError, 'Load_id nil!' if load_id.nil?

        errors = DB[:pallets].where(id: pallet_ids).exclude(load_id: load_id).exclude(load_id: nil).select_map(:pallet_number)
        return failed_response "Pallet: #{errors.join(', ')} already allocated to other loads." unless errors.empty?

        all_ok
      end

      def rmt_grade_check # rubocop:disable Metrics/AbcSize
        raise ArgumentError, 'Load_id nil!' if load_id.nil?

        valid_grade_ids = repo.select_values(:grades, :id, rmt_grade: repo.get(:loads, load_id, :rmt_load))
        errors = DB[:pallet_sequences].where(pallet_id: pallet_ids).exclude(grade_id: valid_grade_ids).select_map(:pallet_number).uniq
        return failed_response "Pallet: #{errors.join(', ')}, only pallets with RMT Grades are allowed on RMT Loads." unless errors.empty?

        all_ok
      end

      def not_failed_otmc_check
        return success_response('failed otmc check bypassed') if AppConst::BYPASS_QUALITY_TEST_LOAD_CHECK

        errors = DB[:pallet_sequences].where(pallet_id: pallet_ids).exclude(failed_otmc_results: nil).select_map(:pallet_number)
        return failed_response "Pallet: #{errors.join(', ')} failed a OTMC test." unless errors.empty?

        all_ok
      end

      def full_build_status_check
        # FIXME: temporary switch-off
        # errors = DB[:pallets].where(id: pallet_ids).where(build_status: 'PARTIAL').select_map(:pallet_number)
        # return failed_response "Pallet: #{errors.join(', ')} incomplete build status." unless errors.empty?

        all_ok
      end

      def not_on_inspection_sheet_check
        ds = DB[:govt_inspection_pallets]
        ds = ds.join(:govt_inspection_sheets, id: Sequel[:govt_inspection_pallets][:govt_inspection_sheet_id])
        ds = ds.join(:pallets, id: Sequel[:govt_inspection_pallets][:pallet_id])
        ds = ds.where(cancelled: false, pallet_id: pallet_ids)

        errors, sheet = ds.select_map(%i[pallet_number govt_inspection_sheet_id]).first
        return failed_response "Pallet: #{errors} is already on inspection sheet #{sheet}." unless errors.nil_or_empty?

        all_ok
      end

      def inspected_check
        errors = @repo.select_values(:pallets, :pallet_number, id: pallet_ids, inspected: false).uniq
        return failed_response "Pallet: #{errors.join(', ')}, not previously inspected." unless errors.empty?

        all_ok
      end

      def not_inspected_check
        errors = @repo.select_values(:pallets, :pallet_number, id: pallet_ids, inspected: true).uniq
        return failed_response "Pallet: #{errors.join(', ')}, has already been inspected." unless errors.empty?

        all_ok
      end

      def verification_passed_check
        failed_pallets = @repo.select_values(:pallet_sequences, :pallet_number, pallet_id: pallet_ids, verification_passed: false).uniq
        return failed_response "Pallet: #{failed_pallets.join(', ')}, verification not passed." unless failed_pallets.empty?

        all_ok
      end

      def pallet_weight_check
        return all_ok unless AppConst::PALLET_WEIGHT_REQUIRED_FOR_INSPECTION

        errors = @repo.select_values(:pallets, :pallet_number, id: pallet_ids, gross_weight: nil).uniq
        return failed_response "Pallet: #{errors.join(', ')}, gross weight not filled." unless errors.empty?

        all_ok
      end

      def not_have_individual_cartons_check
        errors = repo.select_values(:pallets, :pallet_number, id: pallet_ids, has_individual_cartons: true)
        return failed_response "Pallet: #{errors.join(', ')} has individual cartons." unless errors.empty?

        all_ok
      end

      def order_spec_check # rubocop:disable Metrics/AbcSize
        return all_ok if order_id.nil?

        packed_tm_group_id, marketing_org_party_role_id = repo.get(:orders, order_id, %i[packed_tm_group_id marketing_org_party_role_id])
        ds = DB[:pallet_sequences].where(pallet_id: pallet_ids)
        errors = ds.exclude(packed_tm_group_id: packed_tm_group_id).select_map(:pallet_number)
        return failed_response "Pallet: #{errors.join(', ')} does not have the same Packed TM Group as order#{order_id}." unless errors.empty?

        errors = ds.exclude(marketing_org_party_role_id: marketing_org_party_role_id).select_map(:pallet_number)
        return failed_response "Pallet: #{errors.join(', ')} does not have the same Marketing Org as order#{order_id}." unless errors.empty?

        all_ok
      end

      def allocate_check
        tasks = %i[not_on_load not_shipped in_stock not_failed_otmc full_build_status rmt_grade order_spec]
        tasks.each do |task|
          check = CHECKS[task]
          raise ArgumentError, "Task \"#{task}\" is unknown for #{self.class}." if check.nil?

          res = send(check)
          return res unless res.success
        end

        all_ok
      end
    end
  end
end
