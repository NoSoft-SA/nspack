# frozen_string_literal: true

class Nspack < Roda
  route 'finished_goods', 'rmd' do |r|
    # --------------------------------------------------------------------------
    # OFFLOAD VEHICLE
    # --------------------------------------------------------------------------
    r.on 'offload_vehicle' do
      interactor = FinishedGoodsApp::GovtInspectionSheetInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.get do
        notice = retrieve_from_local_store(:flash_notice)
        form_state = { location: MasterfilesApp::LocationRepo.new.find_location_by_location_long_code(AppConst::DEFAULT_FIRST_INTAKE_LOCATION).location_short_code }
        error = retrieve_from_local_store(:error)
        form_state.merge!(error_message: error[:message]) unless error.nil?
        form = Crossbeams::RMDForm.new(form_state,
                                       form_name: :vehicle,
                                       notes: notice,
                                       scan_with_camera: @rmd_scan_with_camera,
                                       caption: 'Scan Tripsheet And Location',
                                       action: '/rmd/finished_goods/offload_vehicle',
                                       button_caption: 'Submit')

        form.add_field(:vehicle_job, 'Tripsheet Number', scan: 'key248_all', scan_type: :vehicle_job, submit_form: false, required: true, lookup: false)
        # form.add_field(:location, 'Location', scan: 'key248_all', scan_type: :location, submit_form: false, required: true, lookup: true)
        form.add_select(:location,
                        'Location',
                        items: MasterfilesApp::LocationRepo.new.for_select_location_for_assignment(AppConst::WAREHOUSE_RECEIVING_AREA),
                        required: true,
                        prompt: true)
        form.add_csrf_tag csrf_tag
        view(inline: form.render, layout: :layout_rmd)
      end

      r.post do
        res = interactor.validate_offload_vehicle(params[:vehicle][:vehicle_job], params[:vehicle][:location])

        if res.success
          store_locally(:flash_notice, res.message)
          r.redirect("/rmd/finished_goods/scan_offload_vehicle_pallet/#{params[:vehicle][:vehicle_job]}")
        else
          store_locally(:error, res)
          r.redirect('/rmd/finished_goods/offload_vehicle')
        end
      end
    end

    r.on 'scan_offload_vehicle_pallet', Integer do |id|
      r.get do
        notice = retrieve_from_local_store(:flash_notice)
        form_state = {}
        error = retrieve_from_local_store(:error)
        form_state.merge!(error_message: error[:message]) unless error.nil?
        form = Crossbeams::RMDForm.new(form_state,
                                       form_name: :pallet,
                                       notes: notice,
                                       scan_with_camera: @rmd_scan_with_camera,
                                       caption: 'Offload Pallet',
                                       action: "/rmd/finished_goods/scan_offload_vehicle_pallet/#{id}",
                                       button_caption: 'Submit')

        tripsheet_pallets = FinishedGoodsApp::GovtInspectionRepo.new.get_vehicle_job_units(id)

        form.add_label(:location, 'Location', FinishedGoodsApp::GovtInspectionRepo.new.get_vehicle_job_location(tripsheet_pallets.first[:vehicle_job_id]))
        form.add_field(:pallet_number, 'Pallet Number', scan: 'key248_all', scan_type: :pallet_number, submit_form: true, data_type: :number, required: true)

        unless (loaded_p = tripsheet_pallets.find_all { |p| !p[:offloaded_at] }).empty?
          form.add_section_header('Pallets Still On Load')
          loaded_p.each do |l|
            form.add_label(:loaded_pallet, '', l[:pallet_number])
          end
        end

        unless (offloaded_p = tripsheet_pallets.find_all { |p| p[:offloaded_at] }).empty?
          form.add_section_header('Pallets Already Offloaded')
          offloaded_p.each do |o|
            form.add_label(:offloaded_pallet, '', o[:pallet_number])
          end
        end

        form.add_csrf_tag csrf_tag
        view(inline: form.render, layout: :layout_rmd)
      end

      r.post do
        repo = MesscadaApp::MesscadaRepo.new
        if FinishedGoodsApp::GovtInspectionRepo.new.find_vehicle_job(id).business_process_id == repo.find_business_process('FIRST_INTAKE')[:id]
          seqs = repo.find_pallet_sequences_by_pallet_number(params[:pallet][:pallet_number]).all
          form = Crossbeams::RMDForm.new({ pallet_number: params[:pallet][:pallet_number] },
                                         form_name: :pallet,
                                         notes: nil,
                                         scan_with_camera: @rmd_scan_with_camera,
                                         caption: 'Validate Pallet',
                                         reset_button: false,
                                         action: "/rmd/finished_goods/reject_vehicle_pallet/#{id}",
                                         button_caption: 'Reject Pallet')

          form.add_label(:pallet_number, 'Pallet Number', params[:pallet][:pallet_number], params[:pallet][:pallet_number])
          form.add_label(:pallet_sequences, 'Pallet Number Sequences', seqs.length)
          form.add_label(:pallet_sequences, 'Pallet Ctn Qty', seqs.empty? ? '-' : seqs[0][:pallet_carton_quantity])
          form.add_label(:packhouse, 'Packhouse', seqs.map { |s| s[:packhouse] }.uniq.join(','))
          form.add_label(:commodity, 'Commodity', seqs.map { |s| s[:commodity] }.uniq.join(','))
          form.add_label(:variety, 'Variety', seqs.map { |s| s[:marketing_variety] }.uniq.join(','))
          form.add_label(:packed_tm_group, 'Packed Tm Group', seqs.map { |s| s[:packed_tm_group] }.uniq.join(','))
          form.add_label(:grade, 'Grade', seqs.map { |s| s[:grade] }.uniq.join(','))
          form.add_label(:size_ref, 'Size Ref', seqs.map { |s| s[:size_ref] }.uniq.join(','))
          form.add_label(:std_pack, 'Std Pack', seqs.map { |s| s[:std_pack] }.uniq.join(','))
          form.add_label(:actual_count, 'Actual Count', seqs.map { |s| s[:actual_count] }.uniq.join(','))
          form.add_label(:stack_type, 'Stack Type', seqs.map { |s| s[:stack_type] }.uniq.join(','))
          form.add_button('Accept Pallet', "/rmd/finished_goods/scan_offload_vehicle_pallet_submit/#{id}")
          form.add_csrf_tag csrf_tag
          view(inline: form.render, layout: :layout_rmd)
        else
          offload_valid_vehicle_pallet(r, id)
        end
      end
    end

    r.on 'scan_offload_vehicle_pallet_submit', Integer do |id|
      offload_valid_vehicle_pallet(r, id)
    end

    r.on 'reject_vehicle_pallet', Integer do |id|
      interactor = FinishedGoodsApp::GovtInspectionSheetInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      store_locally(:error, interactor.failed_response("Pallet: #{params[:pallet][:pallet_number]} has been rejected"))
      r.redirect("/rmd/finished_goods/scan_offload_vehicle_pallet/#{id}")
    end

    # --------------------------------------------------------------------------
    # DISPATCH
    # --------------------------------------------------------------------------
    r.on 'dispatch' do
      repo = BaseRepo.new
      interactor = FinishedGoodsApp::LoadInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # ALLOCATE PALLETS TO LOAD
      # --------------------------------------------------------------------------
      r.on 'allocate' do
        # --------------------------------------------------------------------------
        r.on 'load', Integer do |load_id|
          check = interactor.check(:allocate, load_id)
          unless check.success
            interactor.stepper(:allocate).clear
            store_locally(:flash_notice, rmd_error_message(check.message))
            r.redirect('/rmd/finished_goods/dispatch/allocate/load')
          end

          r.on 'complete_allocation' do
            allocated = interactor.stepper(:allocate).allocated
            initial_allocated = interactor.stepper(:allocate).initial_allocated

            res = interactor.allocate_multiselect(load_id, allocated, initial_allocated)
            if res.success
              interactor.stepper(:allocate).clear
              store_locally(:flash_notice, rmd_success_message(res.message))
              r.redirect('/rmd/finished_goods/dispatch/allocate/load')
            else
              store_locally(:flash_notice, rmd_error_message(res.message))
              r.redirect("/rmd/finished_goods/dispatch/allocate/load/#{load_id}")
            end
          end

          r.get do
            form_state = interactor.stepper(:allocate).form_state
            r.redirect('/rmd/finished_goods/dispatch/allocate/load') if form_state.empty?

            progress = interactor.stepper(:allocate).allocation_progress
            links = [{ caption: 'Cancel', url: '/rmd/finished_goods/dispatch/allocate/load/clear', prompt: 'Cancel Load?' }]
            links << { caption: 'Complete allocation', url: "/rmd/finished_goods/dispatch/allocate/load/#{load_id}/complete_allocation", prompt: 'Complete allocation?' } unless progress.nil?

            form = Crossbeams::RMDForm.new(form_state,
                                           form_name: :allocate,
                                           scan_with_camera: @rmd_scan_with_camera,
                                           progress: progress,
                                           links: links,
                                           notes: retrieve_from_local_store(:flash_notice),
                                           caption: 'Allocate Pallets',
                                           action: "/rmd/finished_goods/dispatch/allocate/load/#{load_id}",
                                           button_caption: 'Submit')

            form.add_label(:load_id, 'Load', load_id)
            form.add_label(:voyage_code, 'Voyage Code', form_state[:voyage_code])
            form.add_label(:container_code, 'Container Code', form_state[:container_code]) unless form_state[:container_code].nil?

            form.add_field(:pallet_number,
                           'Pallet',
                           scan: 'key248_all',
                           scan_type: :pallet_number,
                           submit_form: true,
                           data_type: 'number',
                           required: true)

            form.add_csrf_tag csrf_tag
            view(inline: form.render, layout: :layout_rmd)
          end

          r.post do
            scanned_number = MesscadaApp::ScannedPalletNumber.new(scanned_pallet_number: params[:allocate][:pallet_number]).pallet_number
            res = interactor.check(:allocate_to_load, load_id, scanned_number)
            if res.success
              res = interactor.stepper_allocate_pallet(:allocate, load_id, scanned_number)
              if res.success
                store_locally(:flash_notice, rmd_success_message(res.message))
                r.redirect("/rmd/finished_goods/dispatch/allocate/load/#{load_id}")
              end
            end
            store_locally(:flash_notice, rmd_error_message(res.message))
            r.redirect("/rmd/finished_goods/dispatch/allocate/load/#{load_id}")
          end
        end

        r.on 'load' do
          r.on 'clear' do
            interactor.stepper(:allocate).clear
            r.redirect('/rmd/finished_goods/dispatch/allocate/load')
          end

          r.get do
            form_state = {}
            current_load = interactor.stepper(:allocate)
            r.redirect("/rmd/finished_goods/dispatch/allocate/load/#{current_load.id}") unless current_load&.id.nil?

            form_state = current_load.form_state if current_load&.error?
            form = Crossbeams::RMDForm.new(form_state,
                                           form_name: :allocate,
                                           scan_with_camera: @rmd_scan_with_camera,
                                           notes: retrieve_from_local_store(:flash_notice),
                                           caption: 'Dispatch: Allocate Pallets',
                                           action: '/rmd/finished_goods/dispatch/allocate/load',
                                           button_caption: 'Submit')

            form.add_field(:load_id,
                           'Load',
                           data_type: 'number',
                           scan: 'key248_all',
                           scan_type: :load,
                           submit_form: true,
                           required: true)
            form.add_csrf_tag csrf_tag
            view(inline: form.render, layout: :layout_rmd)
          end

          r.post do
            current_load = interactor.stepper(:allocate)
            load_id = params[:allocate][:load_id]
            res = interactor.check(:allocate, load_id)
            if res.success
              current_load.setup_load(load_id)
              r.redirect("/rmd/finished_goods/dispatch/allocate/load/#{load_id}")
            else
              current_load.write(form_state: { error_message: res.message, errors: res.errors })
              r.redirect('/rmd/finished_goods/dispatch/allocate/load')
            end
          end
        end
      end

      # TRUCK ARRIVAL
      # --------------------------------------------------------------------------
      r.on 'truck_arrival' do
        # --------------------------------------------------------------------------
        r.on 'load', Integer do |load_id|
          check = interactor.check(:truck_arrival, load_id)
          unless check.success
            store_locally(:flash_notice, rmd_error_message(check.message))
            r.redirect('/rmd/finished_goods/dispatch/truck_arrival/load')
          end

          r.on 'vehicle_type_changed' do
            value = MasterfilesApp::VehicleTypeRepo.new.find_vehicle_type(params[:changed_value])&.has_container
            UiRules::ChangeRenderer.render_json(:rmd_load,
                                                self,
                                                :change_container_use,
                                                use_container: value,
                                                load_id: load_id)
          end

          r.on 'container_changed' do
            UiRules::ChangeRenderer.render_json(:rmd_load,
                                                self,
                                                :change_container_use,
                                                use_container: params[:changed_value] == 't',
                                                load_id: load_id)
          end

          r.get do
            # set defaults
            form_state = {}
            form_state[:actual_payload] = FinishedGoodsApp::LoadContainerRepo.new.calculate_actual_payload(load_id) if AppConst::CR_FG.verified_gross_mass_required_for_loads?
            # checks if load_container exists
            container_id = repo.get_id(:load_containers, load_id: load_id)
            unless container_id.nil?
              form_state = form_state.merge(FinishedGoodsApp::LoadContainerRepo.new.find_load_container_flat(container_id).to_h)
              form_state[:container] = 't'
            end

            # checks if load_vehicle exists
            vehicle_id = repo.get_id(:load_vehicles, load_id: load_id)
            form_state = form_state.merge(FinishedGoodsApp::LoadVehicleRepo.new.find_load_vehicle_flat(vehicle_id).to_h) unless vehicle_id.nil?

            # overrides if redirect from error
            res = retrieve_from_local_store(:res)
            unless res.nil?
              form_state = res.instance
              form_state[:error_message] = res.message
              form_state[:errors] = res.errors
            end

            has_container = form_state[:container] == 'true'
            form = Crossbeams::RMDForm.new(form_state,
                                           form_name: :truck_arrival,
                                           scan_with_camera: @rmd_scan_with_camera,
                                           notes: retrieve_from_local_store(:flash_notice),
                                           caption: 'Truck Arrival',
                                           action: "/rmd/finished_goods/dispatch/truck_arrival/load/#{load_id}",
                                           button_caption: 'Submit')
            form.behaviours do |behaviour|
              behaviour.dropdown_change :vehicle_type_id,
                                        notify: [{ url: "/rmd/finished_goods/dispatch/truck_arrival/load/#{load_id}/vehicle_type_changed" }]
              behaviour.input_change :container,
                                     notify: [{ url: "/rmd/finished_goods/dispatch/truck_arrival/load/#{load_id}/container_changed" }]
            end

            form.add_label(:load_id, 'Load', load_id, load_id)
            form.add_label(:load_vehicle_id, 'vehicle_id', vehicle_id, vehicle_id, hide_on_load: true)
            form.add_label(:load_container_id, 'container_id', container_id, container_id, hide_on_load: true)
            form.add_field(:vehicle_number,
                           'Vehicle Number',
                           data_type: 'string',
                           force_uppercase: true,
                           required: true)
            form.add_select(:vehicle_type_id,
                            'Vehicle Type',
                            items: MasterfilesApp::VehicleTypeRepo.new.for_select_vehicle_types,
                            prompt: true)
            form.add_select(:haulier_party_role_id,
                            'Haulier',
                            items: MasterfilesApp::PartyRepo.new.for_select_party_roles(AppConst::ROLE_HAULIER),
                            prompt: true)
            form.add_field(:vehicle_weight_out,
                           'Vehicle Weight Out',
                           data_type: 'number',
                           allow_decimals: true,
                           required: false)
            form.add_field(:driver_name, 'Driver')
            form.add_field(:driver_cell_number,
                           'Driver Cell no',
                           data_type: 'number')
            form.add_field(:dispatch_consignment_note_number,
                           'Consignment Note Number',
                           data_type: 'string',
                           required: false,
                           hide_on_load: true)
            form.add_toggle(:container,
                            'Container')

            form.add_section_header(rmd_info_message('Container Info'),
                                    id: 'container_info_section',
                                    hide_on_load: !has_container)
            form.add_field(:container_code,
                           'Container Code',
                           data_type: 'string',
                           required: false,
                           force_uppercase: true,
                           hide_on_load: !has_container)
            form.add_field(:container_vents,
                           'Container Vents',
                           data_type: 'string',
                           required: false,
                           hide_on_load: !has_container)
            form.add_field(:container_seal_code,
                           'Container Seal Code',
                           data_type: 'string',
                           required: false,
                           hide_on_load: !has_container)
            form.add_field(:container_temperature_rhine,
                           'Temperature Rhine',
                           data_type: 'string',
                           scan: 'key248_all',
                           required: false,
                           hide_on_load: !has_container)
            form.add_field(:container_temperature_rhine2,
                           'Temperature Rhine2',
                           data_type: 'string',
                           scan: 'key248_all',
                           required: false,
                           hide_on_load: !has_container)
            form.add_field(:max_gross_weight,
                           'Max Gross Weight',
                           data_type: 'number',
                           allow_decimals: true,
                           required: false,
                           hide_on_load: !has_container)
            if AppConst::CR_FG.verified_gross_mass_required_for_loads?
              form.add_field(:tare_weight,
                             'Tare Weight',
                             data_type: 'number',
                             allow_decimals: true,
                             required: false,
                             hide_on_load: !has_container)
              form.add_field(:max_payload,
                             'Max Payload',
                             data_type: 'number',
                             allow_decimals: true,
                             required: false,
                             hide_on_load: !has_container)
              form.add_label(:actual_payload,
                             'Calculated Payload',
                             form_state[:actual_payload],
                             form_state[:actual_payload],
                             hide_on_load: !has_container)
            end
            form.add_select(:cargo_temperature_id,
                            'Cargo Temperature',
                            items: MasterfilesApp::CargoTemperatureRepo.new.for_select_cargo_temperatures,
                            required: false,
                            hide_on_load: !has_container)
            form.add_select(:stack_type_id,
                            'Stack Type',
                            items: FinishedGoodsApp::LoadContainerRepo.new.for_select_container_stack_types,
                            required: false,
                            hide_on_load: !has_container)
            form.add_csrf_tag csrf_tag
            view(inline: form.render, layout: :layout_rmd)
          end

          r.post do
            res = interactor.check(:truck_arrival, load_id)
            if res.success
              res = interactor.truck_arrival(load_id, params[:truck_arrival])
              if res.success
                store_locally(:flash_notice, rmd_success_message(res.message))
                r.redirect('/rmd/finished_goods/dispatch/truck_arrival/load')
              end
            end
            res.instance = params[:truck_arrival]
            store_locally(:res, res)
            r.redirect("/rmd/finished_goods/dispatch/truck_arrival/load/#{load_id}")
          end
        end

        r.on 'load' do
          r.get do
            form_state = {}
            res = retrieve_from_local_store(:res)
            unless res.nil?
              form_state = res.instance
              form_state[:error_message] = res.message
              form_state[:errors] = res.errors
            end

            form = Crossbeams::RMDForm.new(form_state,
                                           form_name: :load,
                                           scan_with_camera: @rmd_scan_with_camera,
                                           notes: retrieve_from_local_store(:flash_notice),
                                           caption: 'Dispatch: Truck Arrival',
                                           action: '/rmd/finished_goods/dispatch/truck_arrival/load',
                                           button_caption: 'Submit')

            form.add_field(:load_id,
                           'Load',
                           data_type: 'number',
                           scan: 'key248_all',
                           scan_type: :load,
                           submit_form: true,
                           required: true)
            form.add_csrf_tag csrf_tag
            view(inline: form.render, layout: :layout_rmd)
          end

          r.post do
            load_id = params[:load][:load_id]
            res = interactor.check(:truck_arrival, load_id)
            if res.success
              r.redirect("/rmd/finished_goods/dispatch/truck_arrival/load/#{load_id}")
            else
              store_locally(:res, res)
              r.redirect('/rmd/finished_goods/dispatch/truck_arrival/load')
            end
          end
        end
      end

      # LOAD TRUCK
      # --------------------------------------------------------------------------
      r.on 'load_truck' do
        # --------------------------------------------------------------------------
        r.on 'load', Integer do |load_id|
          r.get do
            check = interactor.check(:load_truck, load_id)
            unless check.success
              interactor.stepper(:load_truck).clear
              store_locally(:flash_notice, rmd_error_message(check.message))
              r.redirect('/rmd/finished_goods/dispatch/load_truck/load')
            end

            form_state = interactor.stepper(:load_truck).form_state
            r.redirect('/rmd/finished_goods/dispatch/load_truck/load') if form_state.empty?

            form = Crossbeams::RMDForm.new(form_state,
                                           form_name: :load_truck,
                                           progress: interactor.stepper(:load_truck).progress,
                                           scan_with_camera: @rmd_scan_with_camera,
                                           links: [{ caption: 'Cancel', url: '/rmd/finished_goods/dispatch/load_truck/load/clear', prompt: 'Cancel Load?' }],
                                           notes: retrieve_from_local_store(:flash_notice),
                                           caption: 'Load Truck',
                                           action: "/rmd/finished_goods/dispatch/load_truck/load/#{load_id}",
                                           button_caption: 'Submit')
            form.add_label(:load_id, 'Load', load_id)
            form.add_label(:voyage_code, 'Voyage Code', form_state[:voyage_code])
            form.add_label(:vehicle_number, 'Vehicle Number', form_state[:vehicle_number])
            form.add_label(:container_code, 'Container Code', form_state[:container_code]) unless form_state[:container_code].nil?
            form.add_label(:requires_temp_tail, 'Requires Temp Tail', form_state[:requires_temp_tail].to_s)
            form.add_label(:allocation_count, 'Allocation Count', form_state[:allocation_count]) unless form_state[:allocation_count]&.zero?

            form.add_field(:pallet_number,
                           'Pallet',
                           scan: 'key248_all',
                           scan_type: :pallet_number,
                           submit_form: true,
                           data_type: 'number',
                           required: true)

            form.add_csrf_tag csrf_tag
            view(inline: form.render, layout: :layout_rmd)
          end

          r.post do
            scanned_number = MesscadaApp::ScannedPalletNumber.new(scanned_pallet_number: params[:load_truck][:pallet_number]).pallet_number

            res = interactor.stepper_load_pallet(:load_truck, load_id, scanned_number)
            if res.instance[:load_loaded]
              form_state = interactor.stepper(:load_truck).form_state || {}
              interactor.stepper(:load_truck).clear
              store_locally(:flash_notice, rmd_success_message(res.message))
              if form_state[:requires_temp_tail]
                store_locally(:temp_tail, OpenStruct.new(instance: { temp_tail_pallet_number: scanned_number, load_id: load_id }))
                r.redirect('/rmd/finished_goods/dispatch/temp_tail')
              else
                res = interactor.ship_load(load_id)
                if res.success
                  store_locally(:flash_notice, rmd_success_message(res.message))
                  r.redirect('/rmd/home')
                else
                  res = OpenStruct.new(instance: res.to_h.merge!(load_id: load_id))
                  store_locally(:ship_load, res)
                  r.redirect('/rmd/finished_goods/dispatch/ship_load')
                end
              end
            end
            message = res.success ? rmd_success_message(res.message) : rmd_error_message(res.message)
            store_locally(:flash_notice, message)
            r.redirect("/rmd/finished_goods/dispatch/load_truck/load/#{load_id}")
          end
        end

        r.on 'load' do
          r.on 'clear' do
            interactor.stepper(:load_truck).clear
            r.redirect('/rmd/finished_goods/dispatch/load_truck/load')
          end

          r.get do
            form_state = {}
            current_load = interactor.stepper(:load_truck)
            r.redirect("/rmd/finished_goods/dispatch/load_truck/load/#{current_load.id}") unless current_load.id.nil_or_empty?

            form_state = current_load.form_state if current_load.error?
            form = Crossbeams::RMDForm.new(form_state,
                                           form_name: :load,
                                           scan_with_camera: @rmd_scan_with_camera,
                                           notes: retrieve_from_local_store(:flash_notice),
                                           caption: 'Dispatch: Load Truck',
                                           action: '/rmd/finished_goods/dispatch/load_truck/load',
                                           button_caption: 'Submit')

            form.add_field(:load_id,
                           'Load',
                           data_type: 'number',
                           scan: 'key248_all',
                           scan_type: :load,
                           submit_form: true,
                           required: true)
            form.add_csrf_tag csrf_tag
            view(inline: form.render, layout: :layout_rmd)
          end

          r.post do
            current_load = interactor.stepper(:load_truck)
            load_id = params[:load][:load_id]
            res = interactor.check(:load_truck, load_id)
            if res.success
              current_load.setup_load(load_id)
              r.redirect("/rmd/finished_goods/dispatch/load_truck/load/#{load_id}")
            else
              current_load.write(form_state: { error_message: res.message, errors: res.errors })
              r.redirect('/rmd/finished_goods/dispatch/load_truck/load')
            end
          end
        end
      end

      # SET TEMP TAIL
      # --------------------------------------------------------------------------
      r.on 'temp_tail' do
        r.get do
          form_state = {}
          res = retrieve_from_local_store(:temp_tail)
          unless res.nil?
            form_state = res.instance
            form_state[:error_message] = res.message
            form_state[:errors] = res.errors
          end
          form = Crossbeams::RMDForm.new(form_state,
                                         form_name: :set_temp_tail,
                                         scan_with_camera: @rmd_scan_with_camera,
                                         notes: retrieve_from_local_store(:flash_notice),
                                         caption: 'Dispatch: Set Temp Tail',
                                         action: '/rmd/finished_goods/dispatch/temp_tail',
                                         button_caption: 'Submit')
          form.add_field(:load_id,
                         'Load',
                         scan: 'key248_all',
                         scan_type: :load,
                         data_type: 'number',
                         required: true)
          form.add_field(:temp_tail_pallet_number,
                         'Pallet',
                         scan: 'key248_all',
                         scan_type: :pallet_number,
                         data_type: 'number',
                         required: true)
          form.add_field(:temp_tail,
                         'Temp',
                         scan: 'key248_all',
                         submit_form: true,
                         data_type: 'string',
                         required: true)
          form.add_csrf_tag csrf_tag
          view(inline: form.render, layout: :layout_rmd)
        end

        r.post do
          load_id = params[:set_temp_tail][:load_id].to_i
          res = interactor.update_temp_tail(load_id, params[:set_temp_tail])
          if res.success
            if res.instance.loaded
              res = interactor.ship_load(load_id)
              if res.success
                store_locally(:flash_notice, rmd_success_message(res.message))
                r.redirect('/rmd/home')
              else
                res = OpenStruct.new(instance: res.to_h.merge!(load_id: load_id))
                store_locally(:ship_load, res)
                r.redirect('/rmd/finished_goods/dispatch/ship_load')
              end
            else
              r.redirect "/rmd/finished_goods/dispatch/load_truck/load/#{load_id}"
            end
          else
            store_locally(:temp_tail, res)
            r.redirect '/rmd/finished_goods/dispatch/temp_tail'
          end
        end
      end

      # SHIP LOAD
      # --------------------------------------------------------------------------
      r.on 'ship_load' do
        r.get do
          form_state = {}
          res = retrieve_from_local_store(:ship_load)
          unless res.nil?
            form_state = res.instance
            form_state[:error_message] = res.message
            form_state[:errors] = res.errors
          end
          form = Crossbeams::RMDForm.new(form_state,
                                         form_name: :ship_load,
                                         scan_with_camera: @rmd_scan_with_camera,
                                         notes: retrieve_from_local_store(:flash_notice),
                                         caption: 'Dispatch: Ship Load',
                                         action: '/rmd/finished_goods/dispatch/ship_load',
                                         button_caption: 'Ship')

          form.add_field(:load_id,
                         'Load',
                         scan: 'key248_all',
                         data_type: 'number',
                         required: true)
          form.add_csrf_tag csrf_tag
          view(inline: form.render, layout: :layout_rmd)
        end

        r.post do
          load_id = params[:ship_load][:load_id].to_i
          res = interactor.ship_load(load_id)
          if res.success
            store_locally(:flash_notice, rmd_success_message(res.message))
            r.redirect('/rmd/home')
          else
            store_locally(:ship_load, res)
            r.redirect('/rmd/finished_goods/dispatch/ship_load')
          end
        end
      end

      # # ALLOCATE PALLETS TO INSPECTION
      # --------------------------------------------------------------------------
      r.on 'inspection' do
        interactor = FinishedGoodsApp::GovtInspectionSheetInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
        # --------------------------------------------------------------------------

        # --------------------------------------------------------------------------
        r.on 'govt_inspection_sheets', Integer do |govt_inspection_sheet_id|
          r.on 'complete' do
            res = interactor.complete_govt_inspection_sheet(govt_inspection_sheet_id)
            if res.success
              store_locally(:flash_notice, rmd_success_message(res.message))
              r.redirect('/rmd/home')
            else
              store_locally(:flash_notice, rmd_error_message(res.message))
              r.redirect("/rmd/finished_goods/dispatch/inspection/govt_inspection_sheets/#{govt_inspection_sheet_id}")
            end
          end

          r.get do
            check = interactor.check(:edit, govt_inspection_sheet_id)
            unless check.success
              store_locally(:error, { error_message: check.message })
              r.redirect('/rmd/finished_goods/dispatch/inspection/govt_inspection_sheets')
            end

            pallet_ids = BaseRepo.new.select_values(:govt_inspection_pallets, :pallet_id, govt_inspection_sheet_id: govt_inspection_sheet_id)
            pallet_numbers = BaseRepo.new.select_values(:pallets, :pallet_number, id: pallet_ids)
            progress = "Scanned Pallets<br>#{pallet_numbers.join('<br>')}"

            form_state = interactor.find_govt_inspection_sheet(govt_inspection_sheet_id)
            form = Crossbeams::RMDForm.new(form_state,
                                           form_name: :add_pallet_to_govt_inspection_sheet,
                                           progress: progress,
                                           scan_with_camera: @rmd_scan_with_camera,
                                           links: [{ caption: 'Complete',
                                                     url: "/rmd/finished_goods/dispatch/inspection/govt_inspection_sheets/#{govt_inspection_sheet_id}/complete",
                                                     prompt: 'Complete: Are you sure, you have finished adding pallets?' }],
                                           notes: retrieve_from_local_store(:flash_notice),
                                           caption: 'Dispatch: Consignment Note',
                                           action: "/rmd/finished_goods/dispatch/inspection/govt_inspection_sheets/#{govt_inspection_sheet_id}",
                                           button_caption: 'Submit')
            form.add_label(:govt_inspection_sheet_id, 'Govt Inspection Sheet Id', govt_inspection_sheet_id, govt_inspection_sheet_id, hide_on_load: true)
            form.add_label(:consignment_note_number, 'Consignment Note Number', form_state[:consignment_note_number])
            form.add_label(:inspection_point, 'Inspection Point', form_state[:inspection_point])
            form.add_label(:destination_region, 'Destination Region', form_state[:destination_region])

            form.add_field(:pallet_number,
                           'Pallet Number',
                           data_type: 'number',
                           scan: 'key248_all',
                           scan_type: :pallet_number,
                           submit_form: true,
                           required: true)
            form.add_csrf_tag csrf_tag
            view(inline: form.render, layout: :layout_rmd)
          end

          r.post do
            res = interactor.add_pallet_govt_inspection_sheet(govt_inspection_sheet_id, params[:add_pallet_to_govt_inspection_sheet])
            if res.success
              store_locally(:flash_notice, rmd_success_message(res.message))
            else
              store_locally(:flash_notice, rmd_error_message(res.message))
            end
            r.redirect("/rmd/finished_goods/dispatch/inspection/govt_inspection_sheets/#{govt_inspection_sheet_id}")
          end
        end

        r.on 'govt_inspection_sheets' do
          r.get do
            form_state = retrieve_from_local_store(:error) || {}
            form = Crossbeams::RMDForm.new(form_state,
                                           form_name: :govt_inspection_sheet,
                                           scan_with_camera: @rmd_scan_with_camera,
                                           notes: retrieve_from_local_store(:flash_notice),
                                           caption: 'Add Finding Sheet Pallets ',
                                           action: '/rmd/finished_goods/dispatch/inspection/govt_inspection_sheets',
                                           button_caption: 'Submit')

            form.add_field(:govt_inspection_sheet_id,
                           'Govt Inspection Sheet',
                           data_type: 'number',
                           scan: 'key248_all',
                           submit_form: true,
                           required: true)
            form.add_csrf_tag csrf_tag
            view(inline: form.render, layout: :layout_rmd)
          end

          r.post do
            govt_inspection_sheet_id = params[:govt_inspection_sheet][:govt_inspection_sheet_id]
            res = interactor.check(:add_pallet, govt_inspection_sheet_id)
            if res.success
              r.redirect("/rmd/finished_goods/dispatch/inspection/govt_inspection_sheets/#{govt_inspection_sheet_id}")
            else
              store_locally(:error, { error_message: res.message, errors: res.errors })
              r.redirect('/rmd/finished_goods/dispatch/inspection/govt_inspection_sheets')
            end
          end
        end
      end
    end

    # --------------------------------------------------------------------------
    # PALLET MOVEMENT
    # --------------------------------------------------------------------------
    r.on 'pallet_movements' do
      interactor = FinishedGoodsApp::PalletMovementsInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # --------------------------------------------------------------------------
      # MOVE PALLET
      # --------------------------------------------------------------------------
      r.on 'move_pallet' do
        r.get do
          pallet = {}
          notice = retrieve_from_local_store(:flash_notice)
          from_state = retrieve_from_local_store(:from_state)
          pallet.merge!(from_state) unless from_state.nil?
          error = retrieve_from_local_store(:error)
          if error.is_a?(String)
            pallet.merge!(error_message: error)
          elsif !error.nil?
            pallet.merge!(error_message: error.message)
            pallet.merge!(errors: error.errors) unless error.errors.nil_or_empty?
          end

          form = Crossbeams::RMDForm.new(pallet,
                                         form_name: :pallet,
                                         notes: notice,
                                         scan_with_camera: @rmd_scan_with_camera,
                                         caption: 'Scan Pallet And Location',
                                         action: '/rmd/finished_goods/pallet_movements/move_pallet',
                                         button_caption: 'Submit')

          form.add_field(:location, 'Location', scan: 'key248_all', scan_type: :location, submit_form: false, required: true, lookup: true)
          form.add_label(:remaining_num_position, 'Remaining No Position', pallet[:remaining_num_position]) unless pallet[:remaining_num_position].nil_or_empty?
          form.add_label(:next_position, 'Next Position', pallet[:next_position]) unless pallet[:next_position].nil_or_empty?
          form.add_field(:pallet_number, 'Pallet Number', scan: 'key248_all', scan_type: :pallet_number, submit_form: true, data_type: :number, required: true)
          form.add_csrf_tag csrf_tag
          view(inline: form.render, layout: :layout_rmd)
        end

        r.post do
          locn_repo = MasterfilesApp::LocationRepo.new
          pallet_number = MesscadaApp::ScannedPalletNumber.new(scanned_pallet_number: params[:pallet][:pallet_number]).pallet_number
          res = interactor.move_pallet(pallet_number, params[:pallet][:location], params[:pallet][:location_scan_field])

          scanned_locn_id = locn_repo.resolve_location_id_from_scan(params[:pallet][:location], params[:pallet][:location_scan_field])
          if (scanned_locn = locn_repo.find_location(scanned_locn_id)) && AppConst::CALCULATE_PALLET_DECK_POSITIONS && scanned_locn.location_type_code == AppConst::LOCATION_TYPES_COLD_BAY_DECK && (positions = locn_repo.find_filled_deck_positions(scanned_locn_id)).length < locn_repo.find_max_position_for_deck_location(scanned_locn_id) && !positions.empty?
            params[:pallet][:pallet_number] = nil
            params[:pallet][:remaining_num_position] = positions.min - 1
            params[:pallet][:next_position] = (positions.min - 1).positive? ? "#{scanned_locn.location_long_code}_P#{positions.min - 1}" : nil
            store_locally(:from_state, params[:pallet])
          end

          if res.success
            store_locally(:flash_notice, res.message)
          else
            store_locally(:error, res)
          end
          r.redirect('/rmd/finished_goods/pallet_movements/move_pallet')
        rescue Crossbeams::InfoError => e
          store_locally(:error, rmd_error_message(e.message))
          r.redirect('/rmd/finished_goods/pallet_movements/move_pallet')
        end
      end
    end

    # --------------------------------------------------------------------------
    # REPACK PALLET
    # --------------------------------------------------------------------------
    r.on 'repack_pallet' do
      interactor = MesscadaApp::MesscadaInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.on 'scan_pallet' do
        r.get do
          pallet = {}
          notice = retrieve_from_local_store(:flash_notice)
          error = retrieve_from_local_store(:error)
          pallet.merge!(error_message: error) unless error.nil?

          form = Crossbeams::RMDForm.new(pallet,
                                         notes: notice,
                                         form_name: :pallet,
                                         scan_with_camera: @rmd_scan_with_camera,
                                         caption: 'Scan Pallet',
                                         action: '/rmd/finished_goods/repack_pallet/scan_pallet',
                                         button_caption: 'Submit')

          form.add_field(:pallet_number, 'Pallet Number', scan: 'key248_all', scan_type: :pallet_number, submit_form: true, data_type: :number, required: true)
          form.add_csrf_tag csrf_tag
          view(inline: form.render, layout: :layout_rmd)
        end

        r.post do
          pallet_sequences = interactor.find_pallet_sequences_by_pallet_number(params[:pallet][:pallet_number])
          if pallet_sequences.empty?
            store_locally(:error, "Scanned Pallet:#{params[:pallet][:pallet_number]} doesn't exist")
            r.redirect('/rmd/finished_goods/repack_pallet/scan_pallet')
          else
            r.redirect("/rmd/finished_goods/repack_pallet/scan_pallet_sequence/#{pallet_sequences.first[:id]}")
          end
        end
      end

      r.on 'scan_pallet_sequence', Integer do |id|
        r.get do
          pallet_sequence = interactor.find_pallet_sequence_attrs(id)
          if pallet_sequence.nil_or_empty?
            store_locally(:error, "Pallet sequence:#{id} doesn't exist")
            r.redirect('/rmd/finished_goods/repack_pallet/scan_pallet')
          end

          if pallet_sequence[:allocated]
            store_locally(:error, "Pallet :#{pallet_sequence[:pallet_number]} has been allocated")
            r.redirect('/rmd/finished_goods/repack_pallet/scan_pallet')
          end

          ps_ids = interactor.find_pallet_sequences_from_same_pallet(id)

          error = retrieve_from_local_store(:error)
          pallet_sequence.merge!(error_message: error.message) unless error.nil?

          form = Crossbeams::RMDForm.new(pallet_sequence,
                                         form_name: :pallet,
                                         scan_with_camera: @rmd_scan_with_camera,
                                         caption: "View Pallet #{pallet_sequence[:pallet_number]}",
                                         step_and_total: [ps_ids.index(id) + 1, ps_ids.length],
                                         reset_button: false,
                                         action: "/rmd/finished_goods/repack_pallet/scan_pallet_sequence/#{id}",
                                         button_caption: 'Repack')
          fields_for_rmd_pallet_sequence_display(form, pallet_sequence)
          form.add_csrf_tag csrf_tag
          form.add_label(:verification_result, 'Verification Result', pallet_sequence[:verification_result])
          form.add_label(:verification_failure_reason, 'Verification Failure Reason', pallet_sequence[:verification_failure_reason])
          form.add_label(:fruit_sticker, 'Fruit Sticker', pallet_sequence[:fruit_sticker]) if AppConst::REQUIRE_FRUIT_STICKER_AT_PALLET_VERIFICATION
          form.add_prev_next_nav('/rmd/finished_goods/repack_pallet/scan_pallet_sequence/$:id$', ps_ids, id)
          view(inline: form.render, layout: :layout_rmd)
        end

        r.post do
          pallet_sequence = interactor.find_pallet_sequence_attrs(id)
          res = interactor.repack_pallet(pallet_sequence[:pallet_id])
          if res.success
            pallet_sequence_id = interactor.pallet_sequence_ids(res.instance[:new_pallet_id]).first
            store_locally(:flash_notice, res.message)
            r.redirect("/rmd/finished_goods/repack_pallet/print_pallet_labels/#{pallet_sequence_id}")
          else
            store_locally(:error, res)
            r.redirect("/rmd/finished_goods/repack_pallet/scan_pallet_sequence/#{id}")
          end

        rescue Crossbeams::InfoError => e
          store_locally(:error, rmd_error_message(e.message))
          r.redirect("/rmd/finished_goods/repack_pallet/scan_pallet_sequence/#{id}")
        end
      end

      r.on 'print_pallet_labels', Integer do |id|
        prod_interactor = ProductionApp::ProductionRunInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

        r.get do
          pallet_sequence = interactor.find_pallet_sequence_attrs(id)
          if pallet_sequence.nil_or_empty?
            store_locally(:error, "Pallet sequence:#{id} doesn't exist")
            r.redirect('/rmd/finished_goods/repack_pallet/scan_pallet')
          end

          ps_ids = interactor.find_pallet_sequences_from_same_pallet(id)

          printer_repo = LabelApp::PrinterRepo.new

          notice = retrieve_from_local_store(:flash_notice)
          error = retrieve_from_local_store(:error)
          pallet_sequence.merge!(error_message: error.message) unless error.nil?

          form = Crossbeams::RMDForm.new(pallet_sequence,
                                         notes: notice,
                                         form_name: :pallet,
                                         scan_with_camera: @rmd_scan_with_camera,
                                         caption: "View Pallet #{pallet_sequence[:pallet_number]}",
                                         step_and_total: [ps_ids.index(id) + 1, ps_ids.length],
                                         reset_button: false,
                                         action: "/rmd/finished_goods/repack_pallet/print_pallet_labels/#{id}",
                                         button_caption: 'Print')
          fields_for_rmd_pallet_sequence_display(form, pallet_sequence)
          form.add_csrf_tag csrf_tag
          form.add_label(:verification_result, 'Verification Result', pallet_sequence[:verification_result])
          form.add_label(:verification_failure_reason, 'Verification Failure Reason', pallet_sequence[:verification_failure_reason])
          form.add_label(:fruit_sticker, 'Fruit Sticker', pallet_sequence[:fruit_sticker]) if AppConst::REQUIRE_FRUIT_STICKER_AT_PALLET_VERIFICATION
          form.add_select(:pallet_label_name, 'Pallet Label', value: prod_interactor.find_pallet_label_name_by_resource_allocation_id(pallet_sequence[:resource_allocation_id]), items: prod_interactor.find_pallet_labels, required: false)
          form.add_select(:printer, 'Printer', items: printer_repo.select_printers_for_application(AppConst::PRINT_APP_PALLET), required: false, value: printer_repo.default_printer_for_application(AppConst::PRINT_APP_PALLET))
          form.add_field(:qty_to_print, 'Qty To Print', required: false, prompt: true, data_type: :number)
          form.add_prev_next_nav('/rmd/finished_goods/repack_pallet/print_pallet_labels/$:id$', ps_ids, id)
          view(inline: form.render, layout: :layout_rmd)
        end

        r.post do
          res = prod_interactor.print_pallet_label_from_sequence(id,
                                                                 pallet_label_name: params[:pallet][:pallet_label_name],
                                                                 no_of_prints: params[:pallet][:qty_to_print],
                                                                 printer: params[:pallet][:printer])
          if res.success
            store_locally(:flash_notice, "Labels For Pallet: #{params[:pallet][:pallet_number]} Printed Successfully")
          else
            store_locally(:error, res)
          end
          r.redirect("/rmd/finished_goods/repack_pallet/print_pallet_labels/#{id}")
        end
      end
    end

    # --------------------------------------------------------------------------
    # CREATE PALLET TRIPSHEET
    # --------------------------------------------------------------------------
    r.on 'create_pallet_tripsheet' do
      interactor = FinishedGoodsApp::GovtInspectionSheetInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.get do
        form_state = {}
        notice = retrieve_from_local_store(:flash_notice)
        error = retrieve_from_local_store(:error)
        form_state.merge!(error_message: error) unless error.nil?

        form = Crossbeams::RMDForm.new(form_state,
                                       form_name: :location,
                                       notes: notice,
                                       scan_with_camera: @rmd_scan_with_camera,
                                       caption: 'Choose Location',
                                       action: '/rmd/finished_goods/create_pallet_tripsheet',
                                       button_caption: 'Submit')

        form.add_select(:planned_location_id,
                        'Planned Location',
                        items: MasterfilesApp::LocationRepo.new.for_select_location_for_assignment(AppConst::WAREHOUSE_RECEIVING_AREA),
                        prompt: true,
                        required: true)
        form.add_csrf_tag csrf_tag
        view(inline: form.render, layout: :layout_rmd)
      end

      r.post do
        res = interactor.manually_create_pallet_tripsheet(params[:location][:planned_location_id])

        unless res.success
          store_locally(:error, unwrap_failed_response(res))
          r.redirect('/rmd/finished_goods/create_pallet_tripsheet')
          return
        end

        r.redirect("/rmd/finished_goods/scan_tripsheet_pallet/#{res.instance}")
      end
    end

    r.on 'print_changed' do
      show =  case params[:changed_value]
              when 't'
                true
              when 'f', ''
                false
              end

      action = show ? :show_element : :hide_element
      json_actions([OpenStruct.new(type: action, dom_id: 'pallet_printer_row')])
    end

    r.on 'scan_tripsheet_pallet', Integer do |id|
      form_state = {}
      form_state.merge! retrieve_from_local_store(:form_state).to_h
      error = retrieve_from_local_store(:error)
      form_state.merge!(error_message: error) unless error.nil?

      form = Crossbeams::RMDForm.new(form_state,
                                     form_name: :pallet,
                                     scan_with_camera: @rmd_scan_with_camera,
                                     caption: 'Scan Tripeheet Pallet',
                                     action: "/rmd/finished_goods/create_pallet_vehicle_job_unit/#{id}",
                                     button_caption: 'Submit')

      form.behaviours do |behaviour|
        behaviour.input_change :print,
                               notify: [{ url: '/rmd/finished_goods/print_changed' }]
      end

      tripsheet_pallets = FinishedGoodsApp::GovtInspectionRepo.new.get_vehicle_job_units(id)
      form.add_label(:tripsheet_number, 'Tripsheet Number', id)
      form.add_field(:pallet_number, 'Pallet Number', scan: 'key248_all', scan_type: :pallet_number, submit_form: true, data_type: :number, required: false)

      unless tripsheet_pallets.empty?
        form.add_section_header('Pallets On Tripsheet')
        tripsheet_pallets.each do |o|
          form.add_label(:tripsheet_pallet, '', o[:pallet_number])
        end
      end

      form.add_toggle(:print, 'Print Tripsheet?')
      form.add_select(:printer,
                      'Printer',
                      items: LabelApp::PrinterRepo.new.select_printers_for_application(AppConst::PRINT_APP_PALLET_TRIPSHEET),
                      value: LabelApp::PrinterRepo.new.default_printer_for_application(AppConst::PRINT_APP_PALLET_TRIPSHEET),
                      required: false,
                      prompt: true,
                      hide_on_load: form_state[:print] != 't')
      form.add_button('Cancel', "/rmd/finished_goods/cancel_pallet_tripsheet/#{id}")
      form.add_button('Complete', "/rmd/finished_goods/complete_pallet_tripsheet/#{id}")
      form.add_csrf_tag csrf_tag
      view(inline: form.render, layout: :layout_rmd)
    end

    r.on 'complete_pallet_tripsheet', Integer do |id|
      interactor = FinishedGoodsApp::GovtInspectionSheetInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      res = interactor.complete_pallet_tripsheet(id, params[:pallet][:print], params[:pallet][:printer])
      if res.success
        if params[:pallet][:print] == 't'
          jasper_params = JasperParams.new('interwarehouse',
                                           current_user.login_name,
                                           vehicle_job_id: id)
          jasper_params.mode = :print
          jasper_params.printer = LabelApp::PrinterRepo.new.find_printer(params[:pallet][:printer])&.printer_code
          res = CreateJasperReport.call(jasper_params)
        end

        if res.success
          store_locally(:flash_notice, "Tripsheet:#{id} completed and printed successfully")
          r.redirect('/rmd/finished_goods/create_pallet_tripsheet')
        end
      end

      store_locally(:error, unwrap_failed_response(res))
      store_locally(:form_state, params[:pallet])
      r.redirect("/rmd/finished_goods/scan_tripsheet_pallet/#{id}")
    end

    r.on 'print_pallet_tripsheet', Integer do |id|
      jasper_params = JasperParams.new('interwarehouse',
                                       current_user.login_name,
                                       vehicle_job_id: id)
      res = CreateJasperReport.call(jasper_params)

      if res.success
        change_window_location_via_json(UtilityFunctions.cache_bust_url(res.instance), request.path)
      else
        show_error(res.message, fetch?(r))
      end
    end

    r.on 'continue_pallet_tripsheet' do
      interactor = FinishedGoodsApp::GovtInspectionSheetInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.get do
        form_state = {}
        notice = retrieve_from_local_store(:flash_notice)
        error = retrieve_from_local_store(:error)
        if error.is_a?(String)
          form_state.merge!(error_message: error)
        elsif !error.nil?
          form_state.merge!(error_message: error.message)
          form_state.merge!(errors: error.errors) unless error.errors.nil_or_empty?
        end

        form = Crossbeams::RMDForm.new(form_state,
                                       form_name: :vehicle_job,
                                       notes: notice,
                                       scan_with_camera: @rmd_scan_with_camera,
                                       caption: 'Scan Tripsheet',
                                       action: '/rmd/finished_goods/continue_pallet_tripsheet',
                                       button_caption: 'Submit')

        form.add_field(:tripsheet_number, 'Tripsheet Number', scan: 'key248_all', scan_type: :vehicle_job, submit_form: false, required: true, lookup: false)
        form.add_csrf_tag csrf_tag
        view(inline: form.render, layout: :layout_rmd)
      end

      r.post do
        res = interactor.can_continue_tripsheet(params[:vehicle_job][:tripsheet_number])
        if res.success
          r.redirect("/rmd/finished_goods/scan_tripsheet_pallet/#{params[:vehicle_job][:tripsheet_number]}")
        else
          store_locally(:error, unwrap_failed_response(res))
          r.redirect('/rmd/finished_goods/continue_pallet_tripsheet')
        end
      end
    end

    r.on 'cancel_pallet_tripsheet', Integer do |id|
      interactor = FinishedGoodsApp::GovtInspectionSheetInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      res = interactor.cancel_manual_tripsheet(id)
      if res.success
        store_locally(:flash_notice, res.message)
        r.redirect('/rmd/finished_goods/create_pallet_tripsheet')
      else
        store_locally(:error, unwrap_failed_response(res))
        r.redirect("/rmd/finished_goods/scan_tripsheet_pallet/#{id}")
      end
    end

    r.on 'create_pallet_vehicle_job_unit', Integer do |id|
      interactor = FinishedGoodsApp::GovtInspectionSheetInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      res = MesscadaApp::ScanCartonLabelOrPallet.call(scanned_number: params[:pallet][:carton_number])
      params[:pallet][:carton_number] = res.instance.carton_label_id

      res = interactor.create_pallet_vehicle_job_unit(id, params[:pallet][:pallet_number], params[:pallet][:carton_number])

      if res.instance[:carton_required]
        form_state = { pallet_number: params[:pallet][:pallet_number] }
        form_state.merge!(error_message: res.message)
        form = Crossbeams::RMDForm.new(form_state,
                                       form_name: :pallet,
                                       scan_with_camera: @rmd_scan_with_camera,
                                       caption: 'Scan Tripsheet Pallet Carton',
                                       action: "/rmd/finished_goods/create_pallet_vehicle_job_unit/#{id}",
                                       button_caption: 'Submit')

        form.add_field(:pallet_number, 'Pallet Number', required: false, hide_on_load: true)
        form.add_field(:carton_number, 'Carton Number', data_type: :number, scan: 'key248_all', scan_type: :carton_label_id, submit_form: true, required: true)
        form.add_csrf_tag csrf_tag
        return view(inline: form.render, layout: :layout_rmd)
      end

      store_locally(:error, unwrap_failed_response(res)) unless res.success
      r.redirect("/rmd/finished_goods/scan_tripsheet_pallet/#{id}")
    end
    # --------------------------------------------------------------------------
    # MOVE DECK PALLETS
    # --------------------------------------------------------------------------
    r.on 'move_deck_pallets' do
      interactor = FinishedGoodsApp::PalletMovementsInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.get do
        form_state = {}
        notice = retrieve_from_local_store(:flash_notice)
        error = retrieve_from_local_store(:error)
        if error.is_a?(String)
          form_state.merge!(error_message: error)
        elsif !error.nil?
          form_state.merge!(error_message: error.message)
          form_state.merge!(errors: error.errors) unless error.errors.nil_or_empty?
        end
        form = Crossbeams::RMDForm.new(form_state,
                                       form_name: :location,
                                       notes: notice,
                                       scan_with_camera: @rmd_scan_with_camera,
                                       caption: 'Scan Location',
                                       action: '/rmd/finished_goods/move_deck_pallets',
                                       button_caption: 'Submit')

        form.add_field(:deck, 'Deck', scan: 'key248_all', scan_type: :location, submit_form: false, required: true, lookup: true)
        form.add_field(:location_to, 'To Location', scan: 'key248_all', scan_type: :location, submit_form: false, required: true, lookup: true)
        form.add_csrf_tag csrf_tag
        view(inline: form.render, layout: :layout_rmd)
      end

      r.post do
        res = interactor.move_deck_pallets(params[:location][:deck], params[:location][:deck_scan_field], params[:location][:location_to], params[:location][:location_to_scan_field])
        if res.success
          store_locally(:flash_notice, res.message)
        else
          store_locally(:error, res)
        end
        r.redirect('/rmd/finished_goods/move_deck_pallets')
      end
    end

    # --------------------------------------------------------------------------
    # VIEW DECK PALLETS
    # --------------------------------------------------------------------------
    r.on 'view_deck_pallets' do
      interactor = MesscadaApp::MesscadaInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.get do
        form_state = {}
        error = retrieve_from_local_store(:error)
        if error.is_a?(String)
          form_state.merge!(error_message: error)
        elsif !error.nil?
          form_state.merge!(error_message: error.message)
          form_state.merge!(errors: error.errors) unless error.errors.nil_or_empty?
        end
        form = Crossbeams::RMDForm.new(form_state,
                                       form_name: :location,
                                       notes: nil,
                                       scan_with_camera: @rmd_scan_with_camera,
                                       caption: 'Scan Location',
                                       action: '/rmd/finished_goods/view_deck_pallets',
                                       button_caption: 'Submit')

        form.add_field(:location, 'Location', scan: 'key248_all', scan_type: :location, submit_form: true, required: true, lookup: true)
        form.add_csrf_tag csrf_tag
        view(inline: form.render, layout: :layout_rmd)
      end

      r.post do
        res = interactor.get_deck_pallets(params[:location][:location], params[:location][:location_scan_field])
        if res.success
          is_empty_deck = res.instance[:pallets].find_all { |p| p[:pallet_number] }.empty?
          notice = "Deck: #{res.instance[:deck_code]} is empty" if is_empty_deck

          form = Crossbeams::RMDForm.new({},
                                         form_name: :location,
                                         notes: notice,
                                         scan_with_camera: @rmd_scan_with_camera,
                                         caption: "Positions for deck:#{res.instance[:deck_code]}",
                                         no_submit: true,
                                         action: '/')
          unless is_empty_deck
            res.instance[:pallets].each do |e|
              form.add_label(e[:pos], "Position #{e[:pos]}", e[:pallet_number])
            end
          end
          form.add_csrf_tag csrf_tag
          view(inline: form.render, layout: :layout_rmd)
        else
          store_locally(:error, res)
          r.redirect('/rmd/finished_goods/view_deck_pallets')
        end
      end
    end
  end

  def offload_valid_vehicle_pallet(route, id) # rubocop:disable Metrics/AbcSize
    interactor = FinishedGoodsApp::GovtInspectionSheetInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

    res = interactor.offload_vehicle_pallet(params[:pallet][:pallet_number])
    if res.success
      store_locally(:flash_notice, res.message)
    else
      store_locally(:error, res)
    end

    if !res.instance[:vehicle_job_offloaded]
      route.redirect("/rmd/finished_goods/scan_offload_vehicle_pallet/#{id}")
    else
      form = Crossbeams::RMDForm.new({},
                                     form_name: :pallet,
                                     scan_with_camera: @rmd_scan_with_camera,
                                     caption: 'Offload Pallet',
                                     action: '/',
                                     reset_button: false,
                                     no_submit: true,
                                     button_caption: '')

      form.add_section_header("#{res.instance[:pallets_moved]} Pallets have been moved to location #{res.instance[:location]}")
      form.add_csrf_tag csrf_tag
      view(inline: form.render, layout: :layout_rmd)
    end
  end
end
