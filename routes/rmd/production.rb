# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
class Nspack < Roda # rubocop:disable ClassLength
  route 'production', 'rmd' do |r|
    # --------------------------------------------------------------------------
    # PALLET ENQUIRY
    # --------------------------------------------------------------------------
    r.on 'pallet_inquiry' do
      interactor = MesscadaApp::MesscadaInteractor.new(current_user, {}, { route_url: request.path }, {})
      # --------------------------------------------------------------------------
      # PALLET
      # --------------------------------------------------------------------------
      r.on 'scan_pallet' do
        r.get do
          pallet = {}
          error = retrieve_from_local_store(:scan_pallet_submit_error)
          pallet = { error_message: error } unless error.nil?

          form = Crossbeams::RMDForm.new(pallet,
                                         form_name: :pallet,
                                         scan_with_camera: @rmd_scan_with_camera,
                                         caption: 'Scan Pallet',
                                         action: '/rmd/production/pallet_inquiry/scan_pallet',
                                         button_caption: 'Submit')

          form.add_field(:pallet_number, 'Pallet Number', data_type: :number, required: true)
          form.add_csrf_tag csrf_tag
          view(inline: form.render, layout: :layout_rmd)
        end

        r.post do
          pallet_sequences = interactor.find_pallet_sequences_by_pallet_number(params[:pallet][:pallet_number])
          if pallet_sequences.empty?
            store_locally(:scan_pallet_submit_error, "scanned_pallet:#{params[:pallet][:pallet_number]} doesn't exist")
            r.redirect('/rmd/production/pallet_inquiry/scan_pallet')
          else
            r.redirect("/rmd/production/pallet_inquiry/scan_pallet_sequence/#{pallet_sequences.first[:id]}")
          end
        end
      end

      # --------------------------------------------------------------------------
      # PALLET SEQUENCE
      # --------------------------------------------------------------------------
      r.on 'scan_pallet_sequence', Integer do |id|
        pallet_sequence = interactor.find_pallet_sequence_attrs(id)
        ps_ids = interactor.find_pallet_sequences_from_same_pallet(id) # => [1,2,3,4]

        form = Crossbeams::RMDForm.new({},
                                       form_name: :pallet,
                                       scan_with_camera: @rmd_scan_with_camera,
                                       caption: "View Pallet #{pallet_sequence[:pallet_number]}",
                                       step_and_total: [ps_ids.index(id) + 1, ps_ids.length],
                                       reset_button: false,
                                       no_submit: true,
                                       action: '/')
        fields_for_rmd_pallet_sequence_display(form, pallet_sequence)
        form.add_csrf_tag csrf_tag
        form.add_label(:verification_result, 'Verification Result', pallet_sequence[:verification_result])
        form.add_label(:verification_failure_reason, 'Verification Failure Reason', pallet_sequence[:verification_failure_reason])
        form.add_label(:fruit_sticker, 'Fruit Sticker', pallet_sequence[:fruit_sticker]) if AppConst::REQUIRE_FRUIT_STICKER_AT_PALLET_VERIFICATION == 'true'
        form.add_prev_next_nav('/rmd/production/pallet_inquiry/scan_pallet_sequence/$:id$', ps_ids, id)
        view(inline: form.render, layout: :layout_rmd)
      end
    end

    # --------------------------------------------------------------------------
    # PALLET Verification
    # --------------------------------------------------------------------------
    r.on 'pallet_verification' do
      interactor = MesscadaApp::MesscadaInteractor.new(current_user, {}, { route_url: request.path }, {})
      # --------------------------------------------------------------------------
      # PALLET/CARTON
      # --------------------------------------------------------------------------
      r.on 'scan_pallet_or_carton' do
        r.get do
          form_state = {}
          if AppConst::COMBINE_CARTON_AND_PALLET_VERIFICATION == 'true'
            error = retrieve_from_local_store(:scan_carton_submit_error)
            form_attrs = { caption: 'Scan Carton', form_name: :carton, field_name: :carton_number, field_caption: 'Carton Number' }
          else
            error = retrieve_from_local_store(:scan_pallet_submit_error)
            form_attrs = { caption: 'Scan Pallet', form_name: :pallet, field_name: :pallet_number, field_caption: 'Pallet Number' }
          end

          notice = retrieve_from_local_store(:flash_notice)
          form_state = { error_message: error } unless error.nil?
          form = Crossbeams::RMDForm.new(form_state,
                                         form_name: form_attrs[:form_name],
                                         scan_with_camera: @rmd_scan_with_camera,
                                         notes: notice,
                                         caption: form_attrs[:caption],
                                         action: '/rmd/production/pallet_verification/scan_pallet_or_carton',
                                         button_caption: 'Submit')

          form.add_field(form_attrs[:field_name], form_attrs[:field_caption], data_type: :number, required: true)
          form.add_csrf_tag csrf_tag
          view(inline: form.render, layout: :layout_rmd)
        end

        r.post do
          if AppConst::COMBINE_CARTON_AND_PALLET_VERIFICATION == 'true'
            store_locally(:scan_carton_submit_error, "Error: scanned_carton:#{params[:carton][:carton_number]}")
            r.redirect('/rmd/production/pallet_verification/scan_pallet_or_carton')
          else
            res = interactor.validate_pallet_to_be_verified(params[:pallet][:pallet_number])
            if res.success
              r.redirect("/rmd/production/pallet_verification/verify_pallet_sequence/#{res.instance[:oldest_pallet_sequence_id]}")
            else
              store_locally(:scan_pallet_submit_error, res.message)
              r.redirect('/rmd/production/pallet_verification/scan_pallet_or_carton')
            end
          end
        end
      end

      # --------------------------------------------------------------------------
      # VERIFY PALLET SEQUENCE
      # --------------------------------------------------------------------------
      r.on 'verify_pallet_sequence', Integer do |id|
        pallet_sequence = interactor.find_pallet_sequence_attrs(id)
        ps_ids = interactor.find_pallet_sequences_from_same_pallet(id) # => [1,2,3,4]

        form_state = { nett_weight: (!pallet_sequence[:sequence_nett_weight].nil_or_empty? ? pallet_sequence[:sequence_nett_weight].to_f : nil) }
        notice = retrieve_from_local_store(:flash_notice)
        error = retrieve_from_local_store(:verification_errors)
        form_state.merge!(error_message: error.message, errors: error.errors) unless error.nil?

        form = Crossbeams::RMDForm.new(form_state,
                                       form_name: :pallet,
                                       scan_with_camera: @rmd_scan_with_camera,
                                       caption: "View Pallet #{pallet_sequence[:pallet_number]}",
                                       step_and_total: [ps_ids.index(id) + 1, ps_ids.length],
                                       reset_button: false,
                                       notes: notice,
                                       action: "/rmd/production/pallet_verification/verify_pallet_sequence_submit/#{id}",
                                       button_id: 'SaveSeq',
                                       button_initially_hidden: true,
                                       button_caption: 'Save')
        form.behaviours do |behaviour|
          behaviour.dropdown_change :verification_result, notify: [{ url: '/rmd/production/pallet_verification/pallet_verification_result_combo_changed' }]
        end
        fields_for_rmd_pallet_sequence_display(form, pallet_sequence)
        form.add_label(:verified, 'Verified', pallet_sequence[:verified])
        form.add_select(:verification_result, 'Verification Result', items: %w[unknown passed failed], value: (pallet_sequence[:verification_result].nil_or_empty? ? 'unknown' : pallet_sequence[:verification_result]))
        form.add_select(:verification_failure_reason, 'Verification Failure Reason', items: MasterfilesApp::QualityRepo.new.for_select_pallet_verification_failure_reasons,
                                                                                     hide_on_load: (pallet_sequence[:verification_result] != 'failed'), value: pallet_sequence[:pallet_verification_failure_reason_id], prompt: true, required: false)
        form.add_select(:fruit_sticker_pm_product_id, 'Fruit Sticker', items: MasterfilesApp::BomsRepo.new.find_pm_products_by_pm_type('fruit_sticker'), value: pallet_sequence[:fruit_sticker_pm_product_id], prompt: true) if AppConst::REQUIRE_FRUIT_STICKER_AT_PALLET_VERIFICATION == 'true' && pallet_sequence[:pallet_sequence_number] == 1
        form.add_label(:gross_weight, 'Gross Weight', pallet_sequence[:gross_weight])
        if AppConst::CAPTURE_PALLET_NETT_WEIGHT_AT_VERIFICATION == 'true'
          form.add_field(:nett_weight, 'Nett Weight', required: true, prompt: true, data_type: :number)
        else
          form.add_label(:nett_weight, 'Nett Weight', (!pallet_sequence[:sequence_nett_weight].nil_or_empty? ? pallet_sequence[:sequence_nett_weight].to_f : nil))
        end
        form.add_prev_next_nav('/rmd/production/pallet_verification/verify_pallet_sequence/$:id$', ps_ids, id)
        form.add_csrf_tag csrf_tag
        view(inline: form.render, layout: :layout_rmd)
      end

      r.on 'pallet_verification_result_combo_changed' do
        actions = [OpenStruct.new(type: params[:changed_value] == 'failed' ? :show_element : :hide_element, dom_id: 'pallet_verification_failure_reason_row'),
                   OpenStruct.new(type: params[:changed_value] != 'unknown' ? :show_element : :hide_element, dom_id: 'SaveSeq')]
        json_actions(actions)
      end

      r.on 'verify_pallet_sequence_submit', Integer do |id|
        res = interactor.verify_pallet_sequence(id, params[:pallet])
        if res.success
          store_locally(:flash_notice, (res.instance[:verification_completed] ? 'Pallet Verified Successfully' : res.message))
        else
          store_locally(:verification_errors, res)
        end

        if res.instance[:verification_completed]
          r.redirect('/rmd/production/pallet_verification/scan_pallet_or_carton')
        else
          r.redirect("/rmd/production/pallet_verification/verify_pallet_sequence/#{id}")
        end
      end
    end
  end

  def fields_for_rmd_pallet_sequence_display(form, pallet_sequence) # rubocop:disable Metrics/AbcSize
    form.add_label(:pallet_number, 'Pallet Number', pallet_sequence[:pallet_number])
    form.add_label(:pallet_sequence_number, 'Pallet Sequence Number', pallet_sequence[:pallet_sequence_number])
    form.add_label(:build_status, 'Build Status', pallet_sequence[:build_status])
    form.add_label(:stack_type, 'Stack Height', pallet_sequence[:stack_type])
    form.add_label(:carton_quantity, 'Pallet Carton Quantity', pallet_sequence[:carton_quantity])
    form.add_label(:seq_carton_qty, 'Seq Carton Qty', pallet_sequence[:seq_carton_qty])
    form.add_label(:production_run_id, 'Production Run Id', pallet_sequence[:production_run_id])
    form.add_label(:farm, 'Farm Code', pallet_sequence[:farm])
    form.add_label(:orchard, 'Orchard Code', pallet_sequence[:orchard])
    form.add_label(:cultivar_group, 'Cultivar Group Code', pallet_sequence[:cultivar_group])
    form.add_label(:cultivar, 'Cultivar Code', pallet_sequence[:cultivar])
    form.add_label(:packhouse, 'Packhouse', pallet_sequence[:packhouse])
    form.add_label(:line, 'Production Line', pallet_sequence[:line])
    form.add_label(:commodity, 'Commodity', pallet_sequence[:commodity])
    form.add_label(:marketing_variety, 'Marketing Variety', pallet_sequence[:marketing_variety])
    form.add_label(:customer_variety, 'Customer Variety', pallet_sequence[:customer_variety])
    form.add_label(:basic_pack, 'Basic Pack', pallet_sequence[:basic_pack])
    form.add_label(:std_pack, 'Std Pack', pallet_sequence[:std_pack])
    form.add_label(:actual_count, 'Actual Count', pallet_sequence[:actual_count])
    form.add_label(:std_size, 'Std Size', pallet_sequence[:std_size])
    form.add_label(:size_ref, 'Size Reference', pallet_sequence[:size_ref])
    form.add_label(:marketing_org, 'Marketing Org', pallet_sequence[:marketing_org])
    form.add_label(:packed_tm_group, 'Packed Tm Group', pallet_sequence[:packed_tm_group])
    form.add_label(:mark, 'Mark', pallet_sequence[:mark])
    form.add_label(:inventory_code, 'Inventory Code', pallet_sequence[:inventory_code])
    form.add_label(:bom, 'Bom Code', pallet_sequence[:bom])
  end
end
# rubocop:enable Metrics/BlockLength
