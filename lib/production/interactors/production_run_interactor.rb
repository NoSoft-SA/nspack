# frozen_string_literal: true

module ProductionApp
  class ProductionRunInteractor < BaseInteractor # rubocop:disable Metrics/ClassLength
    def validate_new_first(params)
      res = validate_new_first_production_run_params(params)
      return validation_failed_response(res) if res.failure?

      return validation_failed_response(OpenStruct.new(messages: { cultivar_id: ['must be filled, mixing not allowed'] })) if res[:cultivar_id].nil? && !res[:allow_cultivar_mixing]

      ok_response
    end

    def create_production_run(params) # rubocop:disable Metrics/AbcSize
      params.merge!(legacy_bintip_criteria: { commodity_code: true, rmt_variety_code: true, treatment_code: true, rmt_size: true, product_class_code: true }) if AppConst::CR_PROD.kromco_rmt_integration?
      res = validate_new_production_run_params(params)
      return validation_failed_response(res) if res.failure?

      return validation_failed_response(OpenStruct.new(messages: { orchard_id: ['must be filled, mixing not allowed'] })) if res[:orchard_id].nil? && !res[:allow_orchard_mixing]

      id = nil
      repo.transaction do
        id = repo.create_production_run(res)
        repo.create_production_run_stats(id)
        log_status(:production_runs, id, 'CREATED')
        log_transaction
      end
      instance = production_run_flat(id)
      success_response("Created production run #{instance.production_run_code}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { packhouse_id: ['This production run already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def add_sequence_to_pallet(user_name, pallet_number, carton_id, carton_quantity) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      return failed_response('Carton Qty cannot be set zero') if carton_quantity.to_i.zero?
      return failed_response("Scanned Carton:#{carton_id} not found. #{AppConst::CARTON_VERIFICATION_REQUIRED ? ' Needs to be verified' : nil}") unless carton_id

      pallet = find_pallet_by_pallet_number(pallet_number)
      carton = find_carton_with_run_info(carton_id)
      return failed_response("Scanned Carton:#{carton_id} doesn't exist") unless carton
      return failed_response('Scanned Carton Production Run is closed') if carton[:production_run_closed]
      return failed_response("Scanned Pallet:#{pallet_number} has been inspected") if pallet[:inspected]
      return failed_response("Scanned Pallet:#{pallet_number} has been shipped") if pallet[:shipped]
      return failed_response("Scanned Pallet:#{pallet_number} has been scrapped") if pallet[:scrapped]

      res = nil
      repo.transaction do
        res = MesscadaApp::AddSequenceToPallet.new(user_name, carton_id, pallet[:id], carton_quantity, AppConst::PALLETIZING_PALLET_MIX).call
        log_transaction
      end
      res
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message(__method__))
      failed_response(e.message)
    end

    def validate_carton_number_for_palletizing(scanned_number)
      res = MesscadaApp::ScanCartonLabelOrPallet.call(scanned_number)
      return res unless res.success

      carton_number = res.instance.carton_label_id
      res = UtilityFunctions.validate_integer_length(:carton_number, carton_number)
      return failed_response("Value #{carton_number} is too big to be a carton. Perhaps you scanned a pallet number?") if res.failure?

      carton_equals_pallet = messcada_repo.carton_label_carton_equals_pallet(carton_number)
      return failed_response("This Carton #{carton_number}, carton equals pallet and cannot be palletized") if carton_equals_pallet

      success_response('ok', carton_number)
    end

    def direct_edit_pallet_sequence(pallet_sequence_id, params) # rubocop:disable Metrics/AbcSize
      attrs = { standard_pack_code_id: params[:standard_pack_id], grade_id: params[:grade_id] }
      attrs[:basic_pack_code_id] = params[:basic_pack_id] unless params[:basic_pack_id].nil_or_empty?
      pallet_id = repo.get_value(:pallet_sequences, :pallet_id, id: pallet_sequence_id)
      repo.transaction do
        repo.update(:pallet_sequences, pallet_sequence_id, attrs)
        repo.update(:pallets, pallet_id, gross_weight: params[:gross_weight])
        repo.update_pallet_sequence_cartons(pallet_sequence_id, attrs) if AppConst::USE_CARTON_PALLETIZING
        log_status(:pallets, pallet_id, 'DIRECT_PALLET_UPDATE')
      end

      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      failed_response(e.message)
    end

    def get_carton_id_from_carton_label_id(carton_label_id)
      repo.get_id(:cartons, carton_label_id: carton_label_id)
    end

    def create_pallet_from_carton(carton_id) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
      return failed_response("Scanned Carton:#{carton_id} not found. #{AppConst::CARTON_VERIFICATION_REQUIRED ? ' Needs to be verified' : nil}") unless carton_id

      carton = find_carton_with_run_info(carton_id)
      return failed_response("Scanned Carton:#{carton_id} doesn't exist") unless carton
      return failed_response('Scanned Carton Production Run is closed') if carton[:production_run_closed]
      return failed_response("Pallet already created from this carton: #{carton[:carton_label_id]}") if carton_label_pallet_exists?(carton[:carton_label_id])

      cpp = find_carton_cpp(carton_id)

      res = nil
      repo.transaction do
        res = MesscadaApp::CreatePalletFromCarton.new(@user, carton_id, cpp[:cartons_per_pallet], nil, false).call
        log_transaction
      end
      res
    rescue Crossbeams::InfoError => e
      ErrorMailer.send_exception_email(e, subject: "INFO: #{self.class.name}", message: decorate_mail_message(__method__))
      failed_response(e.message)
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message(__method__))
      failed_response(e.message)
    end

    def repack_pallets(params) # rubocop:disable Metrics/AbcSize
      params.delete_if { |k, v| v.nil_or_empty? || k.to_s.include?('_scan_field') }
      pallets = { pallet_number1: params[:pallet_number1] }
      params.find_all { |k, _v| k.to_s.include?('pallet_number') && k != :pallet_number1 }.each do |p|
        pallets[p[0]] = p[1]
      end
      params.delete_if { |k, _v| k.to_s.include?('pallet_number') }

      repo.transaction do
        res = ProductionApp::RepackPalletsOrBins.call(@user.user_name, params, pallets)
        return res unless res.success

        log_status(:pallets, res.instance[:pallet_id], AppConst::REPACKED)
        log_multiple_statuses(:pallets, repo.select_values(:pallets, :id, pallet_number: pallets.values), AppConst::REPACK_SCRAP)
        res
      end
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      failed_response(e.message)
    end

    def edit_pallet_validations(pallet_number)
      check_pallet!(:not_have_individual_cartons, pallet_number)
      check_pallet!(:not_scrapped, pallet_number)
      check_pallet!(:not_inspected, pallet_number)
      check_pallet!(:not_shipped, pallet_number)

      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message(__method__))
      failed_response(e.message)
    end

    def replace_pallet_sequence(carton_id, pallet_sequence_id, carton_quantity) # rubocop:disable Metrics/AbcSize
      return failed_response('Carton Qty cannot be set zero') if carton_quantity&.to_i&.zero?
      return failed_response("Scanned Carton:#{carton_id} not found. #{AppConst::CARTON_VERIFICATION_REQUIRED ? ' Needs to be verified' : nil}") unless carton_id

      carton = find_carton_with_run_info(carton_id)
      return failed_response('Scanned Carton Production Run is closed') if carton[:production_run_closed]

      pallet_sequence = find_pallet_sequence(pallet_sequence_id)
      res = nil
      repo.transaction do
        res = MesscadaApp::ReplacePalletSequence.new(@user.user_name, carton[:id], pallet_sequence[:pallet_id], pallet_sequence_id, carton_quantity).call
        log_transaction
      end
      res
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message("#{__method__}. pallet_sequence_id:#{pallet_sequence_id}, carton_id:#{carton_id} "))
      failed_response(e.message)
    end

    def find_pallet_sequence(pallet_sequence_id)
      MesscadaApp::MesscadaRepo.new.find_pallet_sequence(pallet_sequence_id)
    end

    def update_pallet_sequence_carton_qty(pallet_sequence_id, carton_quantity, new_pallet_format = nil, new_cartons_per_pallet_id = nil) # rubocop:disable Metrics/AbcSize
      return failed_response('Carton Qty cannot be set zero') if carton_quantity.to_i.zero?

      pallet_sequence = find_pallet_sequence(pallet_sequence_id)

      res = nil
      repo.transaction do
        res = MesscadaApp::UpdatePalletSequence.new(pallet_sequence[:pallet_id], pallet_sequence_id, carton_quantity).call

        upd = {}
        upd[:pallet_format_id] = new_pallet_format if new_pallet_format
        upd[:cartons_per_pallet_id] = new_cartons_per_pallet_id if new_cartons_per_pallet_id
        MesscadaApp::MesscadaRepo.new.update_pallet_sequence(pallet_sequence_id, upd) unless upd.empty?

        log_transaction
      end
      res
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message(__method__))
      failed_response(e.message)
    end

    def print_pallet_label_from_sequence(pallet_sequence_id, params)
      pallet_id = repo.get(:pallet_sequences, pallet_sequence_id, :pallet_id)
      print_pallet_label(pallet_id, params)
    end

    def print_pallet_label(pallet_id, params)
      instance = get_pallet_label_data(pallet_id)
      host = params[:robot_ip] # can be nil
      LabelPrintingApp::PrintLabel.call(params[:pallet_label_name], instance, params, host)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message(__method__))
      failed_response(e.message)
    end

    def find_packout_runs(params)
      production_runs = repo.all_hash(:production_runs,  params).map { |i| i[:id] }
      return failed_response('No Runs Found') if production_runs.empty?

      success_response('ok', production_runs.join(','))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      failed_response(e.message)
    end

    def create_run_bin_tipping_control_data(id, params)
      res = validate_bin_tipping_control_data_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update(:production_runs, id, legacy_data: params)
      end

      success_response('legacy_data updated successfully')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      failed_response(e.message)
    end

    def create_run_bin_tipping_criteria(id, params)
      params.delete_if { |k, _v| k == :toggle }
      repo.transaction do
        repo.update(:production_runs, id, legacy_bintip_criteria: params)
      end

      success_response('legacy_bintip_criteria updated successfully')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      failed_response(e.message)
    end

    def get_pallet_label_data(pallet_id)
      repo.get_pallet_label_data(pallet_id)
    end

    def find_pallet_label_name_by_resource_allocation_id(product_resource_allocation_id)
      repo.find_pallet_label_name_by_resource_allocation_id(product_resource_allocation_id)
    end

    def find_pallet_labels
      repo.find_pallet_labels
    end

    def find_pallet_sequence_attrs_by_id(id)
      repo.find_pallet_sequence_attrs_by_id(id)
    end

    def find_carton_label_attrs_by_id(id)
      repo.find_carton_label_attrs_by_id(id)
    end

    def find_pallet_sequence_attrs(pallet_id, seq_number)
      repo.find_pallet_sequence_attrs(pallet_id, seq_number)
    end

    def find_pallet_by_pallet_number(pallet_number)
      repo.find_pallet_by_pallet_number(pallet_number)
    end

    def find_pallet_sequence_by_pallet_number_and_pallet_sequence_number(pallet_number, pallet_sequence_number)
      repo.find_pallet_sequence_by_pallet_number_and_pallet_sequence_number(pallet_number, pallet_sequence_number)
    end

    def find_carton_with_run_info(carton_id)
      repo.find_carton_with_run_info(carton_id)
    end

    def find_carton_cpp(carton_id)
      repo.find_carton_cpp(carton_id)
    end

    def update_production_run(id, params) # rubocop:disable Metrics/AbcSize
      run = production_run(id)
      res = validate_production_run_params(run.reconfiguring, params)
      return validation_failed_response(res) if res.failure?

      template_res = validate_run_matches_template(id, res)
      return template_res unless template_res.success

      repo.transaction do
        repo.update_production_run(id, res)
        log_transaction
      end
      instance = production_run_flat(id)
      success_response("Updated production run #{instance.production_run_code}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_production_run(id) # rubocop:disable Metrics/AbcSize
      raise Crossbeams::TaskNotPermittedError, 'Run cannot be deleted at this stage' if production_run(id).setup_complete || production_run(id).reconfiguring

      name = production_run_flat(id).production_run_code
      repo.transaction do
        repo.delete_product_resource_allocations(id)
        repo.delete_production_run_stats(id)
        repo.delete_production_run(id)
        log_status(:production_runs, id, 'DELETED')
        log_transaction
      end

      success_response("Deleted production run #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def clone_production_run(id)
      new_id = nil
      repo.transaction do
        new_id = repo.clone_production_run(id)
        repo.create_production_run_stats(new_id)
        log_status(:production_runs, new_id, 'CLONED', comment: "from run id #{id}")
        log_transaction
      end
      instance = production_run_flat(new_id)
      success_response("Cloned as new production run #{instance.production_run_code}",
                       instance)
    end

    def selected_template(id)
      success_response('ok', repo.find_hash(:product_setup_templates, id))
    end

    def update_template(id, params) # rubocop:disable Metrics/AbcSize
      res = validate_production_run_template_params(params)

      return validation_failed_response(res) if res.failure?

      current_template = production_run(id).product_setup_template_id
      repo.transaction do
        repo.update_production_run(id, res)
        log_status(:production_runs, id, 'EDITING') if current_template.nil?
        log_transaction
      end
      instance = production_run_flat(id)
      success_response("Updated production run #{instance.production_run_code}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def prepare_run_allocation_targets(id)
      assert_permission!(:allocate_setups, id)
      repo.prepare_run_allocation_targets(id)
    end

    def allocate_product_setup(product_resource_allocation_id, params)
      res = repo.allocate_product_setup(product_resource_allocation_id, params[:column_value])
      res.instance = { changes: { product_setup_id: res.instance[:product_setup_id] } }
      res
    end

    def allocate_packing_specification(product_resource_allocation_id, params)
      res = repo.allocate_packing_specification(product_resource_allocation_id, params[:column_value])
      res.instance = { changes: { packing_specification_item_code: res.instance[:packing_specification_item_code] } }
      res
    end

    def update_product_resource_allocation(id, params)
      params[:product_setup_id] = repo.find_packing_spec_item_setup_id(params[:packing_specification_item_id]) if AppConst::CR_PROD.use_packing_specifications?

      res = validate_product_resource_allocation(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_product_resource_allocation(id, res)
      end
      instance = product_resource_allocation_flat(id)
      success_response('Updated allocation',
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def label_for_allocation(product_resource_allocation_id, params)
      res = repo.label_for_allocation(product_resource_allocation_id, params[:column_value])
      res.instance = { changes: { label_template_name: res.instance[:label_template_name] } }
      res
    end

    def packing_method_for_allocation(product_resource_allocation_id, params)
      res = repo.packing_method_for_allocation(product_resource_allocation_id, params[:column_value])
      res.instance = { changes: { packing_method_id: res.instance[:packing_method_id] } }
      res
    end

    def inline_edit_alloc(product_resource_allocation_id, params)
      if params[:column_name] == 'product_setup_code'
        allocate_product_setup(product_resource_allocation_id, params)
      elsif params[:column_name] == 'label_template_name'
        label_for_allocation(product_resource_allocation_id, params)
      elsif params[:column_name] == 'packing_method_code'
        packing_method_for_allocation(product_resource_allocation_id, params)
      elsif params[:column_name] == 'target_customer'
        allocate_target_customer(product_resource_allocation_id, params)
      elsif params[:column_name] == 'packing_specification_item_code'
        allocate_packing_specification(product_resource_allocation_id, params)
      else
        failed_response(%(There is no handler for changed column "#{params[:column_name]}"))
      end
    end

    def allocate_target_customer(product_resource_allocation_id, params)
      res = repo.allocate_target_customer(product_resource_allocation_id, params[:column_value])
      res.instance = { changes: { target_customer: res.instance[:target_customer] } }
      res
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::ProductionRun.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def re_configure_run(id)
      assert_permission!(:re_configure, id)
      repo.transaction do
        repo.update_production_run(id, reconfiguring: true, setup_complete: false)
        log_status(:production_runs, id, 'RE-CONFiGURING')
        log_transaction
      end
      success_response('Run can be re-configured', production_run_flat(id).to_h.merge(colour_rule: 'inprogress'))
    end

    def prepare_to_complete_run(id)
      assert_permission!(:complete_run_stage, id)
      success_response('Labeling stage will finish and run will complete')
    end

    def prepare_to_complete_stage(id)
      assert_permission!(:complete_run_stage, id)
      message = case production_run(id).next_stage
                when :complete
                  'Labeling stage will finish and run will complete'
                when :labeling
                  'The tipping stage will finish and the labeling stage will begin'
                else
                  return failed_response('This run is not in a valid state')
                end

      success_response(message)
    end

    def close_run(id)
      repo.transaction do
        repo.update_production_run(id, closed: true, closed_at: Time.now)
        log_status(:production_runs, id, 'CLOSED')
        log_transaction
      end

      success_response('Run has been closed')
    end

    def complete_run(id)
      CompleteRun.call(id, @user.user_name)
    end

    def complete_stage(id)
      case production_run(id).next_stage
      when :complete
        CompleteRun.call(id, @user.user_name)
      when :labeling
        ExecuteRun.call(id, @user.user_name)
      else
        failed_response('Incorrect state')
      end
    end

    def lines_for_packhouse(params)
      res = validate_changed_value_as_int(params)
      return validation_failed_response(res) if res.failure?
      return success_response('ok', []) if res[:changed_value].nil?

      success_response('ok', ResourceRepo.new.packhouse_lines(res[:changed_value]))
    end

    def change_for_farm(params)
      res = validate_changed_value_as_int(params)
      return validation_failed_response(res) if res.failure?

      instance = { pucs: [], orchards: [], cultivar_groups: [], cultivars: [], seasons: [] }
      return success_response('ok', instance) if res[:changed_value].nil?

      instance[:pucs] = farm_repo.selected_farm_pucs(where: { farm_id: res[:changed_value] })

      success_response('ok', instance)
    end

    def change_for_puc(params) # rubocop:disable Metrics/AbcSize
      res = validate_changed_value_as_int(params)
      return validation_failed_response(res) if res.failure?

      instance = { orchards: [], cultivar_groups: [], cultivars: [], seasons: [] }
      return success_response('ok', instance) if res[:changed_value].nil?

      instance[:orchards] = farm_repo.for_select_orchards(where: { farm_id: params[:production_run_farm_id],
                                                                   puc_id: res[:changed_value] })
      instance[:orchards].unshift(['', ''])

      cultivar_ids = repo.select_values(:orchards, :cultivar_ids, puc_id: res[:changed_value]).flatten.uniq
      group_ids = repo.select_values(:cultivars, :cultivar_group_id, id: cultivar_ids.to_a).uniq
      instance[:cultivar_groups] = cultivar_repo.for_select_cultivar_groups(where: { id: group_ids })

      success_response('ok', instance)
    end

    def change_for_orchard(params) # rubocop:disable Metrics/AbcSize
      res = validate_changed_value_as_int(params)
      return validation_failed_response(res) if res.failure?

      instance = { cultivar_groups: [], cultivars: [], seasons: [] }
      if res[:changed_value].nil?
        instance[:cultivar_groups] = cultivar_repo.for_select_cultivar_groups
      else
        orchard = farm_repo.find_orchard(res[:changed_value])
        cultivar_group_ids = cultivar_repo.all_hash(:cultivars, id: orchard.cultivar_ids.to_a).map { |rec| rec[:cultivar_group_id] }
        instance[:cultivar_groups] = if cultivar_group_ids.empty?
                                       cultivar_repo.for_select_cultivar_groups
                                     else
                                       cultivar_repo.for_select_cultivar_groups(where: { id: cultivar_group_ids })
                                     end
        instance[:cultivars] = cultivar_repo.for_select_cultivars(where: { id: orchard.cultivar_ids.to_a })
        instance[:cultivars].unshift(['', '']) # if mixed_cult
      end

      success_response('ok', instance)
    end

    def change_for_cultivar_group(params) # rubocop:disable Metrics/AbcSize
      res = validate_changed_value_as_int(params)
      return validation_failed_response(res) if res.failure?

      instance = { cultivars: [], seasons: [] }
      if params[:production_run_orchard_id].nil_or_empty?
        instance[:cultivars] = cultivar_repo.for_select_cultivars(where: { cultivar_group_id: res[:changed_value] })
      else
        orchard = farm_repo.find_orchard(params[:production_run_orchard_id])
        instance[:cultivars] = cultivar_repo.for_select_cultivars(where: { id: orchard.cultivar_ids.to_a })
      end
      instance[:cultivars].unshift(['', '']) # if mixed_cult
      instance[:seasons] = MasterfilesApp::CalendarRepo.new.for_select_seasons_for_cultivar_group(res[:changed_value])

      success_response('ok', instance)
    end

    def copy_run_allocation(product_resource_allocation_id, allocation_ids)
      alloc = repo.find_hash(:product_resource_allocations, product_resource_allocation_id)
      extras = { label_template_id: alloc[:label_template_id], packing_specification_item_id: alloc[:packing_specification_item_id] }
      repo.copy_allocations_for_run(product_resource_allocation_id, allocation_ids, alloc[:product_setup_id], extras)
      success_response('Allocation copied', alloc[:production_run_id])
    end

    def preview_allocation_carton_label(product_resource_allocation_id)
      alloc = repo.find_hash(:product_resource_allocations, product_resource_allocation_id)
      return failed_response('Please choose a product setup') unless alloc[:product_setup_id]
      return failed_response('Please choose a label template') unless alloc[:label_template_id]

      instance = messcada_repo.allocated_product_setup_label_printing_instance(product_resource_allocation_id)
      label = repo.find_hash(:label_templates, alloc[:label_template_id])[:label_template_name]
      LabelPrintingApp::PreviewLabel.call(label, instance, { packed_date: run_start_date(instance[:production_run_id]) })
    end

    # create carton_print_repo?
    def print_carton_label(args, request_ip, params)
      res = validate_print_carton(params)
      return validation_failed_response(res) if res.failure?
      return mixed_validation_failed_response(res, messages: { no_of_prints: ["cannot be more than #{AppConst::BATCH_PRINT_MAX_LABELS}"] }) if res[:no_of_prints] > AppConst::BATCH_PRINT_MAX_LABELS

      MesscadaApp::BatchPrintCartonLabels.call(args, res[:label_template_id], request_ip, params)
      success_response('Label sent to printer', args)
    end

    def mark_setup_as_complete(id)
      repo.transaction do
        repo.update_production_run(id, setup_complete: true, reconfiguring: false)
        log_status('production_runs', id, 'SETUP_COMPLETED')
        log_transaction
      end
    end

    def mark_setup_as_incomplete(id)
      repo.transaction do
        repo.update_production_run(id, setup_complete: false)
        log_status('production_runs', id, 'SETUP_UN-COMPLETED')
        log_transaction
      end
    end

    def execute_run(id)
      ExecuteRun.call(id, @user.user_name)
    end

    def re_execute_run(id)
      ReExecuteRun.call(id, @user.user_name)
    end

    # Read the user profile to get line_no & then find active labeling run for that line
    def active_run_id_for_user(current_user)
      return nil unless current_user&.profile
      return nil if current_user.profile['packhouse_line_id'].nil_or_empty?

      repo.labeling_run_for_line(current_user.profile['packhouse_line_id'])
    end

    def create_pallet_mix_rules # rubocop:disable Metrics/AbcSize
      rules = repo.all_hash(:pallet_mix_rules, scope: AppConst::PALLET_MIX_RULES)
      unless AppConst::PALLET_MIX_RULES.sort == rules.map { |r| r[:scope] }.sort
        new = AppConst::PALLET_MIX_RULES.sort.find_all { |c| c != AppConst::PALLETIZING_BAYS_PALLET_MIX } - rules.map { |r| r[:scope] }.sort.find_all { |c| c != AppConst::PALLETIZING_BAYS_PALLET_MIX }

        new.each do |scope|
          repo.create_pallet_mix_rule(scope: scope)
        end

        if rules.map { |r| r[:scope] }.sort.find_all { |c| c != AppConst::PALLETIZING_BAYS_PALLET_MIX }.empty?
          ProductionApp::ResourceRepo.new.for_select_plant_resources_of_type(Crossbeams::Config::ResourceDefinitions::PACKHOUSE).each do |pakchse|
            repo.create_pallet_mix_rule(scope: AppConst::PALLETIZING_BAYS_PALLET_MIX, packhouse_plant_resource_id: pakchse[1])
          end
        end
      end
      success_response('All Pallet Mix Rules Created Successfully')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_pallet_mix_rule(id, params)
      res = validate_pallet_mix_rule_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_pallet_mix_rule(id, res)
        log_transaction
      end
      instance = pallet_mix_rule(id)
      success_response("Updated pallet mix rule #{instance.scope} successfully",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def find_pallet_mix_rules_by_scope(scope)
      repo.find_pallet_mix_rules_by_scope(scope)
    end

    def check_pallet!(check, pallet_number)
      res = MesscadaApp::TaskPermissionCheck::Pallets.call(check, pallet_number: pallet_number)
      raise Crossbeams::InfoError, res.message unless res.success
    end

    def refresh_pallet_data(id)
      repo.transaction do
        repo.refresh_pallet_data(id)
      end
      success_response('Pallet data refreshed successfully')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def production_run(id)
      repo.find_production_run(id)
    end

    def carton_label_pallet_exists?(carton_label_id)
      pallet_number = messcada_repo.carton_label_pallet_number(carton_label_id)
      return false if pallet_number.nil_or_empty?

      messcada_repo.pallet_exists?(pallet_number)
    end

    def resolve_bin_filler_resource_params(plant_resource_type_code, plant_resource_id: nil)
      attrs = { plant_resource_type_id: repo.get_id(:plant_resource_types, plant_resource_type_code: plant_resource_type_code),
                plant_resource_ids: resource_repo.robot_buttons(plant_resource_id) }
      success_response('ok', attrs)
    end

    def inline_edit_label_to_print(plant_resource_id, params)
      if params[:column_name] == 'label_to_print'
        repo.transaction do
          res = resource_repo.update_bin_filler_role(plant_resource_id, params[:column_value])
          res.instance = { changes: { label_to_print: res.instance[:label_to_print] } }
          res
        end
      else
        failed_response(%(There is no handler for changed column "#{params[:column_name]}"))
      end
    end

    private

    def repo
      @repo ||= ProductionRunRepo.new
    end

    def farm_repo
      @farm_repo ||= MasterfilesApp::FarmRepo.new
    end

    def cultivar_repo
      @cultivar_repo ||= MasterfilesApp::CultivarRepo.new
    end

    def product_setup_repo
      @product_setup_repo ||= ProductionApp::ProductSetupRepo.new
    end

    def messcada_repo
      @messcada_repo ||= MesscadaApp::MesscadaRepo.new
    end

    def resource_repo
      @resource_repo ||= ProductionApp::ResourceRepo.new
    end

    def pallet_mix_rule(id)
      repo.find_pallet_mix_rule_flat(id)
    end

    def validate_pallet_mix_rule_params(params)
      PalletMixRuleSchema.call(params)
    end

    def production_run_flat(id)
      repo.find_production_run_flat(id)
    end

    def product_resource_allocation(id)
      repo.find_product_resource_allocation(id)
    end

    def product_resource_allocation_flat(id)
      repo.find_product_resource_allocation_flat(id)
    end

    def run_start_date(production_run_id)
      messcada_repo.run_start_date(production_run_id)
    end

    def validate_bin_tipping_control_data_params(params)
      BinTippingControlDataSchema.call(params)
    end

    def validate_new_first_production_run_params(params)
      ProductionRunNewFirstSchema.call(params)
    end

    def validate_new_production_run_params(params)
      ProductionRunNewSchema.call(params)
    end

    def validate_production_run_params(reconfiguring, params)
      if reconfiguring
        ProductionRunReconfigureSchema.call(params)
      else
        ProductionRunSchema.call(params)
      end
    end

    def validate_production_run_template_params(params)
      ProductionRunTemplateSchema.call(params)
    end

    def validate_product_resource_allocation(params)
      ProductResourceAllocationSelectSchema.call(params)
    end

    def validate_print_carton(params)
      Dry::Schema.Params do
        optional(:printer).filled(:integer)
        required(:label_template_id).filled(:integer)
        required(:no_of_prints).filled(:integer, gt?: 0)
      end.call(params)
    end

    def validate_run_matches_template(id, instance) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      run = production_run(id)
      return ok_response if run.product_setup_template_id.nil?

      template = product_setup_repo.find_product_setup_template(run.product_setup_template_id)

      errors = {}
      unless AppConst::CR_PROD.can_mix_cultivar_groups? && instance[:allow_cultivar_group_mixing]
        errors[:cultivar_group_id] = ['does not match the template'] if template.cultivar_group_id != instance[:cultivar_group_id]
      end
      unless template.season_id.nil?
        errors[:season_id] = ['does not match the template'] if template.season_id != instance[:season_id]
      end
      unless instance[:allow_cultivar_mixing] || template.cultivar_id.nil?
        errors[:cultivar_id] = ['does not match the template'] if template.cultivar_id != instance[:cultivar_id]
      end
      return validation_failed_response(instance.to_h.merge(messages: errors)) unless errors.empty?

      ok_response
    end
  end
end
