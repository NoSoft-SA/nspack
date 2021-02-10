# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
class Nspack < Roda # rubocop:disable Metrics/ClassLength
  route 'reworks', 'production' do |r|
    # REWORKS RUNS
    # --------------------------------------------------------------------------

    interactor = ProductionApp::ReworksRunInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

    r.on 'change_deliveries_orchard' do
      r.is do
        r.get do
          show_partial_or_page(r) { Production::Reworks::ChangeDeliveriesOrchard::SelectOrchards.call(remote: fetch?(r)) }
        end

        r.post do
          res = interactor.validate_change_delivery_orchard_screen_params(params[:change_deliveries_orchard])
          if res.success
            store_locally(:change_deliveries_orchard_params, params[:change_deliveries_orchard])
            show_partial_or_page(r) { Production::Reworks::ChangeDeliveriesOrchard::FromOrchardDeliveries.call(nil, form_values: params[:change_deliveries_orchard]) }
          else
            re_show_form(r, res, url: '/production/reworks/change_deliveries_orchard') do
              Production::Reworks::ChangeDeliveriesOrchard::SelectOrchards.call(form_values: params[:change_deliveries_orchard],
                                                                                form_errors: res.errors,
                                                                                remote: fetch?(r))
            end
          end
        end
      end

      r.on 'selected_deliveries' do
        # Fix set up repos and re-use them. ("farm_repo" instead of "MasterfilesApp::FarmRepo.new")
        # FIX: USe helper "multiselect_grid_choices" to get ids from list and store and pass as an array, not string
        # FIX: Use one Hash for all of these... { from_orchard: val, from_cultivar: val ... }
        # TODO: show no of bins affected next to delivery id (336 - 25 bins)
        res = interactor.resolve_deliveries_from_multiselect(retrieve_from_local_store(:change_deliveries_orchard_params), multiselect_grid_choices(params))
        if res.success
          store_locally(:change_deliveries_orchard_params, res.instance)
          show_partial_or_page(r) { Production::Reworks::ChangeDeliveriesOrchard::Summary.call(form_values: res.instance, remote: fetch?(r)) }
        else
          re_show_form(r, res, url: '/production/reworks/change_deliveries_orchard') do
            res[:message] = unwrap_failed_response(res)
            Production::Reworks::ChangeDeliveriesOrchard::SelectOrchards.call(form_values: res.instance,
                                                                              form_errors: res.errors,
                                                                              remote: fetch?(r))
          end
        end
      end

      r.on 'apply_change_deliveries_orchard_changes' do
        reworks_run_type_id = ProductionApp::ReworksRepo.new.get_reworks_run_type_id(AppConst::RUN_TYPE_CHANGE_DELIVERIES_ORCHARDS)
        params = retrieve_from_local_store(:change_deliveries_orchard_params).merge({ reworks_run_type_id: reworks_run_type_id })
        res = interactor.change_deliveries_orchards(params)
        if res.success
          flash[:notice] = 'Delivery Orchards Changed Successfully'
          r.redirect('/production/reworks/change_deliveries_orchard')
        else
          re_show_form(r, res, url: '/production/reworks/change_deliveries_orchard') do
            res[:message] = unwrap_failed_response(res)
            Production::Reworks::ChangeDeliveriesOrchard::SelectOrchards.call(form_errors: res.errors,
                                                                              remote: fetch?(r))
          end
        end
      end

      r.on 'from_orchard_combo_changed' do
        if !params[:changed_value].to_s.empty?
          to_orchards = interactor.for_select_to_orchards(params[:changed_value])
          from_cultivars = RawMaterialsApp::RmtDeliveryRepo.new.orchard_cultivars(params[:changed_value])
        else
          to_orchards = []
          from_cultivars = []
        end

        json_actions([OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'change_deliveries_orchard_to_orchard',
                                     options_array: to_orchards),
                      OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'change_deliveries_orchard_from_cultivar',
                                     options_array: from_cultivars),
                      OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'change_deliveries_orchard_to_cultivar',
                                     options_array: [])])
      end

      r.on 'to_orchard_combo_changed' do
        to_cultivars = if !params[:changed_value].to_s.empty?
                         RawMaterialsApp::RmtDeliveryRepo.new.orchard_cultivars(params[:changed_value])
                       else
                         []
                       end

        json_replace_select_options('change_deliveries_orchard_to_cultivar', to_cultivars)
      end

      r.on 'allow_cultivar_mixing_changed' do
        actions = if params[:changed_value] == 't'
                    [OpenStruct.new(type: :hide_element,
                                    dom_id: 'change_deliveries_orchard_from_cultivar_field_wrapper'),
                     OpenStruct.new(type: :hide_element,
                                    dom_id: 'change_deliveries_orchard_ignore_runs_that_allow_mixing_field_wrapper')]
                  else
                    [OpenStruct.new(type: :show_element,
                                    dom_id: 'change_deliveries_orchard_from_cultivar_field_wrapper'),
                     OpenStruct.new(type: :show_element,
                                    dom_id: 'change_deliveries_orchard_ignore_runs_that_allow_mixing_field_wrapper')]
                  end
        json_actions(actions)
      end
    end

    r.on 'reworks_runs',  Integer do |id|
      # Check for notfound:
      r.on !interactor.exists?(:reworks_runs, id) do
        handle_not_found(r)
      end

      r.on 'list_children_reworks_runs' do
        check_auth!('reworks', 'edit')
        r.redirect "/list/reworks_run_details/with_params?key=view_children&parent_id=#{id}"
      end

      r.is do
        r.get do       # SHOW
          check_auth!('reworks', 'read')
          show_partial { Production::Reworks::ReworksRun::Show.call(id) }
        end
      end
    end

    r.on 'reworks_runs' do
      r.on 'search_by_pallet_number' do # SEARCH BY PALLET NUMBER
        r.get do
          show_partial_or_page(r) { Production::Reworks::ReworksRun::SearchByPalletNumber.call }
        end

        r.post do
          res = interactor.find_reworks_runs_with(params[:reworks_run][:pallet_number])
          if res.success
            r.redirect "/list/reworks_run_details/with_params?key=search_by_pallet_number&reworks_runs_ids=#{res.instance}"
          else
            re_show_form(r, res, url: '/production/reworks/reworks_runs/search_by_pallet_number') do
              Production::Reworks::ReworksRun::SearchByPalletNumber.call(form_values: params[:reworks_run], form_errors: res.errors)
            end
          end
        end
      end
    end

    r.on 'reworks_run_types', String do |run_type|
      if run_type.match?(/\A\d+\Z/)
        id = run_type.to_i
      else
        id = ProductionApp::ReworksRepo.new.get_reworks_run_type_id(run_type)
        raise Crossbeams::FrameworkError, 'Run type does not exist. Perhaps required seeds were not run. Please contact support.' if id.nil?
      end
      store_locally(:reworks_run_type_id, id)

      r.on 'reworks_runs' do
        r.on 'new' do
          r.get do
            store_locally(:list_url, back_button_url)
            check_auth!('reworks', 'new')
            if ProductionApp::ReworksRepo.new.find_reworks_run_type(id)[:run_type] == AppConst::RUN_TYPE_CHANGE_DELIVERIES_ORCHARDS
              show_partial_or_page(r) { Production::Reworks::ChangeDeliveriesOrchard::SelectOrchards.call(remote: fetch?(r)) }
            else
              show_partial_or_page(r) { Production::Reworks::ReworksRun::New.call(id, remote: fetch?(r)) }
            end
          end
          r.post do
            res = interactor.create_reworks_run(id, params[:reworks_run])
            run_type = ProductionApp::ReworksRepo.new.find_reworks_run_type(id)[:run_type]
            bulk_production_run_update = (run_type == AppConst::RUN_TYPE_BULK_PRODUCTION_RUN_UPDATE) || (run_type == AppConst::RUN_TYPE_BULK_BIN_RUN_UPDATE)
            if res.success
              if res.instance[:make_changes]
                store_locally(:reworks_run_params, res.instance)
                r.redirect "/production/reworks/reworks_run_types/#{id}/#{res.instance[:display_page]}" if bulk_production_run_update
                if fetch?(r)
                  redirect_via_json("/production/reworks/reworks_run_types/#{id}/pallets/#{res.instance[:pallets_selected].join(',')}/#{res.instance[:display_page]}")
                else
                  r.redirect "/production/reworks/reworks_run_types/#{id}/pallets/#{res.instance[:pallets_selected].join(',')}/#{res.instance[:display_page]}"
                end
              else
                flash[:notice] = res.message
                if fetch?(r)
                  redirect_via_json(retrieve_from_local_store(:list_url))
                else
                  r.redirect "/list/reworks_runs/with_params?key=standard&reworks_runs.reworks_run_type_id=#{id}"
                end
              end
            else
              pallets_selected = interactor.resolve_selected_pallet_numbers(res.instance[:pallets_selected])
              params[:reworks_run][:pallets_selected] = pallets_selected.nil_or_empty? ? '' : pallets_selected
              url = "/production/reworks/reworks_run_types/#{id}/reworks_runs/new"
              re_show_form(r, res, url: url) do
                Production::Reworks::ReworksRun::New.call(id,
                                                          form_values: params[:reworks_run],
                                                          form_errors: res.errors,
                                                          remote: fetch?(r))
              end
            end
          end
        end

        r.on 'recalc_all_bins_nett_weight' do
          r.get do
            show_partial_or_page(r) do
              Production::Reworks::ReworksRun::Confirm.call(url: '/production/reworks/reworks_run_types/recalc_bin_nett_weight/reworks_runs/recalc_all_bins_nett_weight',
                                                            notice: 'Press the button to re-calculate all bins nett_weight',
                                                            button_captions: ['Recalculate nett weight of all bins', 'Recalculating...'])
            end
          end

          r.post do
            res = interactor.recalc_bins_nett_weight
            if res.success
              flash[:notice] = res.message
              redirect_to_last_grid(r)
            end
          end
        end

        r.on 'display_reworks_multiselect_grid', String, String do |grid, grid_key|
          r.redirect "/list/#{grid}/multi?key=#{grid_key}&id=#{id}"
        end

        r.on 'production_run_id_changed' do
          allow_cultivar_mixing = params[:reworks_run_allow_cultivar_mixing] == 't'
          production_run_id = params[:changed_value]
          if allow_cultivar_mixing || production_run_id.nil_or_empty?
            orchard_code = nil
            grid_url = "/list/rmt_bins_reworks/multi?key=tip_bins_reworks&id=#{id}"
          else
            orchard_id = interactor.production_run_orchard(production_run_id)
            orchard_code = "for Orchard #{MasterfilesApp::FarmRepo.new.find_orchard(orchard_id)&.orchard_code}"
            grid_url = "/list/rmt_bins_reworks/multi?key=tip_bins_reworks_with_orchard_id&id=#{id}&orchard_id=#{orchard_id}"
          end
          json_actions([OpenStruct.new(type: :replace_url,
                                       dom_id: 'reworks_run_select_button',
                                       value: grid_url),
                        OpenStruct.new(type: :replace_inner_html,
                                       dom_id: 'reworks_run_select_button',
                                       value: "Select Bins #{orchard_code}")])
        end

        r.on 'allow_cultivar_mixing_changed' do
          allow_cultivar_mixing = params[:changed_value] == 't'
          production_run_id = params[:reworks_run_production_run_id]
          if allow_cultivar_mixing || production_run_id.nil_or_empty?
            orchard_code = nil
            grid_url = "/list/rmt_bins_reworks/multi?key=tip_bins_reworks&id=#{id}"
          else
            orchard_id = interactor.production_run_orchard(production_run_id)
            orchard_code = "for Orchard #{MasterfilesApp::FarmRepo.new.find_orchard(orchard_id)&.orchard_code}"
            grid_url = "/list/rmt_bins_reworks/multi?key=tip_bins_reworks_with_orchard_id&id=#{id}&orchard_id=#{orchard_id}"
          end
          json_actions([OpenStruct.new(type: :replace_input_value,
                                       dom_id: 'reworks_run_allow_cultivar_mixing',
                                       value: allow_cultivar_mixing ? 't' : 'f'),
                        OpenStruct.new(type: :replace_url,
                                       dom_id: 'reworks_run_select_button',
                                       value: grid_url),
                        OpenStruct.new(type: :replace_inner_html,
                                       dom_id: 'reworks_run_select_button',
                                       value: "Select Bins #{orchard_code}")])
        end

        r.on 'multiselect_reworks_run_pallets' do
          check_auth!('reworks', 'new')
          res = interactor.resolve_pallet_numbers_from_multiselect(id, multiselect_grid_choices(params))
          if res.success
            pallet_numbers = res.instance[:pallets_selected]
            json_actions([OpenStruct.new(type: :replace_input_value,
                                         dom_id: 'reworks_run_pallets_selected',
                                         value: pallet_numbers)])
          else
            re_show_form(r, res) do
              Production::Reworks::ReworksRun::New.call(id,
                                                        form_values: params[:reworks_run_pallet],
                                                        form_errors: res.errors)
            end
          end
        end

        r.on 'multiselect_reworks_run_rmt_bins' do
          check_auth!('reworks', 'new')
          res = interactor.resolve_rmt_bins_from_multiselect(id, multiselect_grid_choices(params))
          if res.success
            pallet_numbers = res.instance[:pallets_selected]
            json_actions([OpenStruct.new(type: :replace_input_value,
                                         dom_id: 'reworks_run_pallets_selected',
                                         value: pallet_numbers)])
          else
            re_show_form(r, res) do
              Production::Reworks::ReworksRun::New.call(id,
                                                        form_values: params[:reworks_run_pallet],
                                                        form_errors: res.errors)
            end
          end
        end

        r.on 'multiselect_reworks_run_bulk_production_run_update' do
          attrs = retrieve_from_local_store(:reworks_run_params)
          res = interactor.bulk_production_run_update(id, multiselect_grid_choices(params), attrs)
          if res.success
            flash[:notice] = res.message
            r.redirect "/list/reworks_runs/with_params?key=standard&reworks_runs.reworks_run_type_id=#{id}"
          end
        end
      end

      r.on 'pallets', String do |pallet_number|
        r.on 'edit_pallet'  do
          pallet_numbers = pallet_number.split(',')
          r.get do
            if pallet_numbers.length == 1
              store_locally(:batch_pallet_numbers, nil)
              show_partial_or_page(r) do
                Production::Reworks::ReworksRun::EditPallet.call(id,
                                                                 pallet_numbers.first,
                                                                 back_url: "/list/reworks_runs/with_params?key=standard&reworks_runs.reworks_run_type_id=#{id}")
              end
            else
              show_partial_or_page(r) { Production::Reworks::ReworksRun::SelectPalletSequence.call(id, pallet_numbers) }
            end
          end
        end

        r.on 'edit_rmt_bin_gross_weight' do
          bin_number = pallet_number.split(',').first
          r.get do
            show_partial_or_page(r)  do
              Production::Reworks::ReworksRun::EditRmtBinGrossWeight.call(id,
                                                                          bin_number,
                                                                          back_url: "/list/reworks_runs/with_params?key=standard&reworks_runs.reworks_run_type_id=#{id}")
            end
          end
          r.post do
            res = interactor.manually_weigh_rmt_bin(params[:reworks_run_rmt_bin])
            if res.success
              flash[:notice] = res.message
              r.redirect "/list/reworks_runs/with_params?key=standard&reworks_runs.reworks_run_type_id=#{id}"
            else
              re_show_form(r, res) do
                Production::Reworks::ReworksRun::EditRmtBinGrossWeight.call(id,
                                                                            bin_number,
                                                                            back_url: "/list/reworks_runs/with_params?key=standard&reworks_runs.reworks_run_type_id=#{id}",
                                                                            form_values: params[:reworks_run_rmt_bin],
                                                                            form_errors: res.errors)
              end
            end
          end
        end

        r.on 'edit_representative_pallet_sequence' do
          pallet_numbers = pallet_number.split(',')
          store_locally(:batch_pallet_numbers, pallet_numbers)

          res = interactor.edit_representative_pallet_sequence(params[:reworks_run_pallet])
          r.redirect "/production/reworks/pallet_sequences/#{res.instance[:pallet_sequence_id]}/edit_reworks_pallet_sequence" if res.success
        end
      end

      r.on 'edit_bulk_production_run' do
        r.get do
          attrs = retrieve_from_local_store(:reworks_run_params)
          store_locally(:reworks_run_params, attrs)
          show_partial_or_page(r) { Production::Reworks::ReworksRun::BulkProductionRunUpdate.call(id, attrs) }
        end
      end

      r.on 'reject_bulk_production_run_update' do
        res = interactor.reject_bulk_production_run_update(id)
        flash[:notice] = res.instance.to_s
        r.redirect "/list/reworks_runs/with_params?key=standard&reworks_runs.reworks_run_type_id=#{id}"
      end

      r.redirect "/list/reworks_runs/with_params?key=standard&reworks_runs.reworks_run_type_id=#{id}"
    end

    r.on 'pallets', String do |pallet_number|
      reworks_run_type_id = retrieve_from_local_store(:reworks_run_type_id)
      store_locally(:reworks_run_type_id, reworks_run_type_id)

      r.on 'pallet_shipping_details' do
        r.get do
          show_partial_or_page(r) { Production::Reworks::ReworksRun::ShowPalletShippingDetails.call(pallet_number) }
        end
      end

      r.on 'print_reworks_pallet_label' do # Print Pallet Label
        r.get do
          show_partial { Production::Reworks::ReworksRun::PrintReworksLabel.call(nil, pallet_number, false) }
        end
        r.post do
          res = interactor.print_reworks_pallet_label(pallet_number, params[:reworks_run_print])
          if res.success
            flash[:notice] = res.message
            redirect_via_json "/production/reworks/reworks_run_types/#{reworks_run_type_id}/pallets/#{res.instance[:pallet_number]}/edit_pallet"
          else
            re_show_form(r, res) do
              Production::Reworks::ReworksRun::PrintReworksLabel.call(nil,
                                                                      pallet_number,
                                                                      false,
                                                                      form_values: params[:reworks_run_print],
                                                                      form_errors: res.errors)
            end
          end
        end
      end

      r.on 'edit_carton_quantities' do
        r.get do
          show_partial_or_page(r) do
            Production::Reworks::ReworksRun::EditSequenceQuantities.call(pallet_number,
                                                                         back_url: "/production/reworks/reworks_run_types/#{reworks_run_type_id}/pallets/#{pallet_number}/edit_pallet")
          end
        end
      end

      r.on 'set_gross_weight' do
        r.get do
          show_partial { Production::Reworks::ReworksRun::SetPalletGrossWeight.call(pallet_number, reworks_run_type_id) }
        end
        r.post do
          res = interactor.update_pallet_gross_weight(params[:reworks_run_pallet])
          if res.success
            flash[:notice] = res.message
            redirect_via_json "/production/reworks/reworks_run_types/#{reworks_run_type_id}/pallets/#{res.instance[:pallet_number]}/edit_pallet"
          else
            re_show_form(r, res) do
              Production::Reworks::ReworksRun::SetPalletGrossWeight.call(pallet_number,
                                                                         reworks_run_type_id,
                                                                         form_values: params[:reworks_run_pallet],
                                                                         form_errors: res.errors)
            end
          end
        end
      end

      r.on 'edit_pallet_details' do
        r.get do
          show_partial { Production::Reworks::ReworksRun::EditPalletDetails.call(pallet_number, reworks_run_type_id) }
        end
        r.post do
          res = interactor.update_pallet_details(params[:reworks_run_pallet])
          if res.success
            flash[:notice] = res.message
            redirect_via_json "/production/reworks/reworks_run_types/#{reworks_run_type_id}/pallets/#{res.instance[:pallet_number]}/edit_pallet"
          else
            re_show_form(r, res) do
              Production::Reworks::ReworksRun::EditPalletDetails.call(pallet_number,
                                                                      reworks_run_type_id,
                                                                      form_values: params[:reworks_run_pallet],
                                                                      form_errors: res.errors)
            end
          end
        end
      end

      r.on 'fruit_sticker_changed' do
        second_fruit_stickers = if params[:changed_value].blank?
                                  []
                                else
                                  interactor.second_fruit_stickers(params[:changed_value])
                                end
        json_actions([OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'reworks_run_pallet_fruit_sticker_pm_product_2_id',
                                     options_array: second_fruit_stickers)])
      end
    end

    r.on 'pallet_sequences', Integer do |id|
      reworks_run_type_id = retrieve_from_local_store(:reworks_run_type_id)
      store_locally(:reworks_run_type_id, reworks_run_type_id)

      r.on 'edit_reworks_pallet_sequence' do # Edit pallet sequence
        r.get do
          show_partial_or_page(r) { Production::Reworks::ReworksRun::EditPalletSequence.call(id, back_url: back_button_url) }
        end
        r.patch do
          res = interactor.update_reworks_run_pallet_sequence(params[:reworks_run_sequence])
          if res.success
            store_locally(:reworks_run_sequence_changes, res.instance)
            show_partial_or_page(r) { Production::Reworks::ReworksRun::ShowPalletSequenceChanges.call(id, res.instance, back_url: back_button_url) }
          else
            re_show_form(r, res, url: "/production/reworks/pallet_sequences/#{id}/edit_reworks_pallet_sequence") do
              Production::Reworks::ReworksRun::EditPalletSequence.call(id,
                                                                       back_url: "/production/reworks/reworks_run_types/#{reworks_run_type_id}/pallets/#{res.instance[:pallet_number]}/edit_pallet",
                                                                       form_values: params[:reworks_run_sequence],
                                                                       form_errors: res.errors)
            end
          end
        end
      end

      r.on 'accept_pallet_sequence_changes' do
        params = retrieve_from_local_store(:reworks_run_sequence_changes)
        batch_pallet_numbers = retrieve_from_local_store(:batch_pallet_numbers)
        res = interactor.update_pallet_sequence_record(id, reworks_run_type_id, params, batch_pallet_numbers)
        if res.success
          flash[:notice] = res.message
          if res.instance[:batch_update]
            r.redirect "/list/reworks_runs/with_params?key=standard&reworks_runs.reworks_run_type_id=#{reworks_run_type_id}"
          else
            r.redirect "/production/reworks/reworks_run_types/#{reworks_run_type_id}/pallets/#{res.instance[:pallet_number]}/edit_pallet"
          end
        else
          r.redirect "/production/reworks/pallet_sequences/#{id}/reject_pallet_sequence_changes"
        end
      end

      r.on 'reject_pallet_sequence_changes' do
        res = interactor.reject_pallet_sequence_changes(id)
        batch_update = ProductionApp::ReworksRepo.new.find_reworks_run_type(reworks_run_type_id)[:run_type] == AppConst::RUN_TYPE_BATCH_PALLET_EDIT
        flash[:notice] = 'Changes to Pallet sequence has be discarded'
        if batch_update
          r.redirect "/list/reworks_runs/with_params?key=standard&reworks_runs.reworks_run_type_id=#{reworks_run_type_id}"
        else
          r.redirect "/production/reworks/reworks_run_types/#{reworks_run_type_id}/pallets/#{res.instance[:pallet_number]}/edit_pallet"
        end
      end

      r.on 'edit_reworks_production_run' do # Edit pallet sequence
        production_run_id = ProductionApp::ReworksRepo.new.find_production_run_id(id)
        r.get do
          show_partial_or_page(r) { Production::Reworks::ReworksRun::EditProductionRun.call(id, production_run_id, reworks_run_type_id) }
        end
        r.post do
          res = interactor.update_reworks_production_run(params[:reworks_run_sequence])
          if res.success
            flash[:notice] = res.message
            redirect_via_json "/production/reworks/reworks_run_types/#{reworks_run_type_id}/pallets/#{res.instance[:pallet_number]}/edit_pallet"
          else
            re_show_form(r, res) do
              Production::Reworks::ReworksRun::EditProductionRun.call(id,
                                                                      production_run_id,
                                                                      reworks_run_type_id,
                                                                      form_values: params[:reworks_run_sequence],
                                                                      form_errors: res.errors)
            end
          end
        end
      end

      r.on 'production_run_changed' do
        production_run_details = if params[:changed_value].blank?
                                   []
                                 else
                                   interactor.production_run_details_table(params[:changed_value])
                                 end
        json_actions([OpenStruct.new(type: :replace_inner_html,
                                     dom_id: 'reworks_run_pallet_production_run_details',
                                     value: production_run_details)])
      end

      r.on 'allow_cultivar_group_mixing_changed' do
        old_production_run_id = params[:reworks_run_sequence_old_production_run_id]
        allow_cultivar_group_mixing = if params[:changed_value] == 't' && AppConst::ALLOW_CULTIVAR_GROUP_MIXING
                                        true
                                      else
                                        false
                                      end
        production_runs = ProductionApp::ReworksRepo.new.for_select_production_runs(old_production_run_id, allow_cultivar_group_mixing)
        json_actions([OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'reworks_run_sequence_production_run_id',
                                     options_array: production_runs)])
      end

      r.on 'edit_reworks_farm_details' do # Edit pallet sequence
        r.get do
          show_partial_or_page(r) { Production::Reworks::ReworksRun::EditFarmDetails.call(id, reworks_run_type_id) }
        end
        r.post do
          res = interactor.update_reworks_farm_details(params[:reworks_run_sequence])
          if res.success
            flash[:notice] = res.message
            redirect_via_json "/production/reworks/reworks_run_types/#{reworks_run_type_id}/pallets/#{res.instance[:pallet_number]}/edit_pallet"
          else
            re_show_form(r, res) do
              Production::Reworks::ReworksRun::EditFarmDetails.call(id,
                                                                    reworks_run_type_id,
                                                                    form_values: params[:reworks_run_sequence],
                                                                    form_errors: res.errors)
            end
          end
        end
      end

      r.on 'farm_changed' do
        pucs = if params[:changed_value].blank?
                 []
               else
                 interactor.farm_pucs(params[:changed_value])
               end
        json_actions([OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'reworks_run_sequence_puc_id',
                                     options_array: pucs),
                      OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'reworks_run_sequence_orchard_id',
                                     options_array: []),
                      OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'reworks_run_sequence_cultivar_id',
                                     options_array: [])])
      end

      r.on 'puc_changed' do
        orchards = interactor.puc_orchards(params[:reworks_run_sequence_farm_id], params[:changed_value])
        json_actions([OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'reworks_run_sequence_orchard_id',
                                     options_array: orchards),
                      OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'reworks_run_sequence_cultivar_id',
                                     options_array: [])])
      end

      r.on 'orchard_changed' do
        cultivars = if params[:changed_value].blank? || params[:reworks_run_sequence_cultivar_group_id].blank?
                      []
                    else
                      interactor.orchard_cultivars(params[:reworks_run_sequence_cultivar_group_id], params[:changed_value])
                    end
        json_actions([OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'reworks_run_sequence_cultivar_id',
                                     options_array: cultivars)])
      end

      r.on 'basic_pack_code_changed' do
        commodity_id = params[:reworks_run_sequence_commodity_id]
        std_fruit_size_count_id = params[:reworks_run_sequence_std_fruit_size_count_id]
        if commodity_id.blank? || std_fruit_size_count_id.blank? || params[:changed_value].blank?
          actual_counts = []
          pm_boms = []
        else
          basic_pack_code_id = params[:changed_value]
          actual_counts = interactor.for_select_basic_pack_actual_counts(basic_pack_code_id, std_fruit_size_count_id)
          pm_boms = interactor.for_select_setup_pm_boms(commodity_id, std_fruit_size_count_id, basic_pack_code_id)
        end
        json_actions([OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'reworks_run_sequence_fruit_actual_counts_for_pack_id',
                                     options_array: actual_counts),
                      OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'reworks_run_sequence_pm_bom_id',
                                     options_array: pm_boms),
                      OpenStruct.new(type: :replace_input_value,
                                     dom_id: 'reworks_run_sequence_description',
                                     value: ''),
                      OpenStruct.new(type: :replace_input_value,
                                     dom_id: 'reworks_run_sequence_erp_bom_code',
                                     value: ''),
                      OpenStruct.new(type: :replace_inner_html,
                                     dom_id: 'reworks_run_sequence_pm_boms_products',
                                     value: [])])
      end

      r.on 'std_fruit_size_count_changed' do
        commodity_id = params[:reworks_run_sequence_commodity_id]
        basic_pack_code_id = params[:reworks_run_sequence_basic_pack_code_id]
        if commodity_id.blank? || basic_pack_code_id.blank? || params[:changed_value].blank?
          actual_counts = []
          pm_boms = []
        else
          std_fruit_size_count_id = params[:changed_value]
          actual_counts = interactor.for_select_basic_pack_actual_counts(basic_pack_code_id, std_fruit_size_count_id)
          pm_boms = interactor.for_select_setup_pm_boms(commodity_id, std_fruit_size_count_id, basic_pack_code_id)
        end
        json_actions([OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'reworks_run_sequence_fruit_actual_counts_for_pack_id',
                                     options_array: actual_counts),
                      OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'reworks_run_sequence_pm_bom_id',
                                     options_array: pm_boms),
                      OpenStruct.new(type: :replace_input_value,
                                     dom_id: 'reworks_run_sequence_description',
                                     value: ''),
                      OpenStruct.new(type: :replace_input_value,
                                     dom_id: 'reworks_run_sequence_erp_bom_code',
                                     value: ''),
                      OpenStruct.new(type: :replace_inner_html,
                                     dom_id: 'reworks_run_sequence_pm_boms_products',
                                     value: [])])
      end

      r.on 'actual_count_changed' do
        if params[:changed_value].blank?
          standard_pack_codes = []
          size_references = []
        else
          fruit_actual_counts_for_pack_id = params[:changed_value]
          actual_count = MasterfilesApp::FruitSizeRepo.new.find_fruit_actual_counts_for_pack(fruit_actual_counts_for_pack_id)
          standard_pack_codes = interactor.for_select_actual_count_standard_pack_codes(actual_count.standard_pack_code_ids.to_a)
          size_references = interactor.for_select_actual_count_size_references(actual_count.size_reference_ids.to_a)
        end
        json_actions([OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'reworks_run_sequence_standard_pack_code_id',
                                     options_array: standard_pack_codes),
                      OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'reworks_run_sequence_fruit_size_reference_id',
                                     options_array: size_references)])
      end

      r.on 'packed_tm_group_changed' do
        target_markets = MasterfilesApp::TargetMarketRepo.new.for_select_packed_group_tms(where: { target_market_group_id: params[:changed_value] })
        if params[:changed_value].blank? || params[:reworks_run_sequence_marketing_variety_id].blank?
          customer_varieties = []
        else
          packed_tm_group_id = params[:changed_value]
          marketing_variety_id = params[:reworks_run_sequence_marketing_variety_id]
          customer_varieties = interactor.for_select_customer_varieties(packed_tm_group_id, marketing_variety_id)
        end
        json_actions([OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'reworks_run_sequence_customer_variety_id',
                                     options_array: customer_varieties),
                      OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'reworks_run_sequence_target_market_id',
                                     options_array: target_markets)])
      end

      r.on 'marketing_variety_changed' do
        if params[:changed_value].blank? || params[:reworks_run_sequence_packed_tm_group_id].blank?
          customer_varieties = []
        else
          marketing_variety_id = params[:changed_value]
          packed_tm_group_id = params[:reworks_run_sequence_packed_tm_group_id]
          customer_varieties = interactor.for_select_customer_varieties(packed_tm_group_id, marketing_variety_id)
        end
        json_actions([OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'reworks_run_sequence_customer_variety_id',
                                     options_array: customer_varieties)])
      end

      r.on 'pallet_stack_type_changed' do
        pallet_base_id = params[:reworks_run_sequence_pallet_base_id]
        if pallet_base_id.blank? || params[:changed_value].blank?
          pallet_formats = []
        else
          pallet_stack_type_id = params[:changed_value]
          pallet_formats = interactor.for_select_pallet_formats(pallet_base_id, pallet_stack_type_id)
        end
        json_actions([OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'reworks_run_sequence_pallet_format_id',
                                     options_array: pallet_formats)])
      end

      r.on 'pallet_format_changed' do
        basic_pack_code_id = params[:reworks_run_sequence_basic_pack_code_id]
        if basic_pack_code_id.blank? || params[:changed_value].blank?
          cartons_per_pallets = []
        else
          pallet_format_id = params[:changed_value]
          cartons_per_pallets = interactor.for_select_cartons_per_pallets(pallet_format_id, basic_pack_code_id)
        end
        json_actions([OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'reworks_run_sequence_cartons_per_pallet_id',
                                     options_array: cartons_per_pallets)])
      end

      r.on 'pm_type_changed' do
        pm_subtypes = if params[:changed_value].blank?
                        []
                      else
                        interactor.for_select_pm_type_pm_subtypes(params[:changed_value])
                      end
        json_actions([OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'reworks_run_sequence_pm_subtype_id',
                                     options_array: pm_subtypes)])
      end

      r.on 'pm_bom_changed' do
        pm_mark_id = params[:reworks_run_sequence_pm_mark_id]
        if params[:changed_value].blank? || pm_mark_id.blank?
          pm_bom_products = []
          pm_bom = nil
        else
          pm_bom_id = params[:changed_value]
          pm_bom = MasterfilesApp::BomRepo.new.find_pm_bom(pm_bom_id)
          pm_bom_products = interactor.pm_bom_products_table(pm_bom_id, pm_mark_id)
        end
        json_actions([OpenStruct.new(type: :replace_input_value,
                                     dom_id: 'reworks_run_sequence_description',
                                     value: pm_bom&.description),
                      OpenStruct.new(type: :replace_input_value,
                                     dom_id: 'reworks_run_sequence_erp_bom_code',
                                     value: pm_bom&.erp_bom_code),
                      OpenStruct.new(type: :replace_inner_html,
                                     dom_id: 'reworks_run_sequence_pm_boms_products',
                                     value: pm_bom_products)])
      end

      r.on 'mark_changed' do
        pm_marks = MasterfilesApp::BomRepo.new.for_select_pm_marks(where: { mark_id: params[:changed_value] })
        json_actions([OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'reworks_run_sequence_pm_mark_id',
                                     options_array: pm_marks)])
      end

      r.on 'pm_mark_changed' do
        pm_bom_id = params[:reworks_run_sequence_pm_bom_id]
        if params[:changed_value].blank? || pm_bom_id.blank?
          pm_bom_products = []
        else
          pm_mark_id = params[:changed_value]
          pm_bom_products = interactor.pm_bom_products_table(pm_bom_id, pm_mark_id)
        end
        json_actions([OpenStruct.new(type: :replace_inner_html,
                                     dom_id: 'reworks_run_sequence_pm_boms_products',
                                     value: pm_bom_products)])
      end

      r.on 'allow_cultivar_mixing_changed' do
        actions = if params[:changed_value] == 't'
                    [OpenStruct.new(type: :show_element,
                                    dom_id: 'reworks_run_sequence_cultivar_id_field_wrapper')]
                  else
                    [OpenStruct.new(type: :hide_element,
                                    dom_id: 'reworks_run_sequence_cultivar_id_field_wrapper')]
                  end
        json_actions(actions)
      end

      r.on 'print_reworks_carton_label' do # Print Carton Label
        r.get do
          show_partial { Production::Reworks::ReworksRun::PrintReworksLabel.call(id, nil, true) }
        end
        r.post do
          res = interactor.print_reworks_carton_label(id, params[:reworks_run_print])
          if res.success
            update_grid_row(id, changes: {}, notice: res.message)
          else
            re_show_form(r, res) do
              Production::Reworks::ReworksRun::PrintReworksLabel.call(id,
                                                                      nil,
                                                                      true,
                                                                      form_values: params[:reworks_run_print],
                                                                      form_errors: res.errors)
            end
          end
        end
      end

      r.on 'clone_sequence' do
        r.get do
          pallet_numbers = interactor.pallet_sequence_pallet_number(id)
          show_partial_or_page(r) do
            Production::Reworks::ReworksRun::CloneSequence.call(id,
                                                                reworks_run_type_id,
                                                                back_url: "/production/reworks/reworks_run_types/#{reworks_run_type_id}/pallets/#{pallet_numbers.first}/edit_pallet")
          end
        end
        r.post do
          res = interactor.clone_pallet_sequence(params[:reworks_run_sequence])
          if res.success
            flash[:notice] = res.message
            redirect_via_json "/production/reworks/reworks_run_types/#{reworks_run_type_id}/pallets/#{res.instance[:pallet_number]}/edit_pallet"
          else
            re_show_form(r, res) do
              Production::Reworks::ReworksRun::CloneSequence.call(id,
                                                                  reworks_run_type_id,
                                                                  back_url: "/production/reworks/reworks_run_types/#{reworks_run_type_id}/pallets/#{res.instance[:pallet_number]}/edit_pallet",
                                                                  form_values: params[:reworks_run_sequence],
                                                                  form_errors: res.errors)
            end
          end
        end
      end

      r.on 'remove_sequence' do
        check_auth!('reworks', 'delete')
        res = interactor.remove_pallet_sequence(id, reworks_run_type_id)
        flash[:notice] = res.message
        redirect_via_json "/production/reworks/reworks_run_types/#{reworks_run_type_id}/pallets/#{res.instance[:pallet_number]}/edit_pallet"
      end

      r.on 'edit_carton_quantities' do
        res = interactor.edit_carton_quantities(id, reworks_run_type_id, params)
        if res.success
          flash[:notice] = res.message
          redirect_via_json "/production/reworks/pallets/#{res.instance[:pallet_number]}/edit_carton_quantities"
        else
          undo_grid_inline_edit(message: unwrap_failed_response(res), message_type: :warning)
        end
      end

      r.on 'select_representative_sequence' do
        res = ProductionApp::ReworksRepo.new.where_hash(:pallet_sequences, id: id)
        json_actions([OpenStruct.new(type: :replace_input_value,
                                     dom_id: 'reworks_run_pallet_id',
                                     value: res[:id]),
                      OpenStruct.new(type: :replace_input_value,
                                     dom_id: 'reworks_run_pallet_pallet_sequence_id',
                                     value: res[:id])],
                     '')
      end

      r.on 'manage_sequence_cartons' do
        show_partial_or_page(r) do
          res = ProductionApp::ReworksRepo.new.where_hash(:pallet_sequences, id: id)
          Production::Reworks::ReworksRun::ManageSequenceCartons.call(id,
                                                                      back_url: "/production/reworks/reworks_run_types/#{reworks_run_type_id}/pallets/#{res[:pallet_number]}/edit_pallet")
        end
      end
    end

    r.on 'cartons', Integer do |id|
      reworks_run_type_id = retrieve_from_local_store(:reworks_run_type_id)
      store_locally(:reworks_run_type_id, reworks_run_type_id)

      r.on 'clone_carton' do
        r.get do
          show_partial { Production::Reworks::ReworksRun::CloneCarton.call(id) }
        end
        r.post do
          res = interactor.clone_carton(params[:reworks_run_carton])
          if res.success
            flash[:notice] = res.message
            redirect_via_json "/production/reworks/pallet_sequences/#{res.instance[:pallet_sequence_id]}/manage_sequence_cartons"
          else
            re_show_form(r, res) do
              Production::Reworks::ReworksRun::CloneCarton.call(id,
                                                                form_values: params[:reworks_run_carton],
                                                                form_errors: res.errors)
            end
          end
        end
      end

      r.on 'scrap_carton' do
        check_auth!('reworks', 'delete')
        res = interactor.scrap_carton(id, reworks_run_type_id)
        flash[:notice] = res.message
        r.redirect "/production/reworks/pallet_sequences/#{res.instance[:pallet_sequence_id]}/manage_sequence_cartons"
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
