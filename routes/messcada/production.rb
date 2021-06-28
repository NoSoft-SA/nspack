# frozen_string_literal: true

class Nspack < Roda
  route 'production', 'messcada' do |r|
    # --------------------------------------------------------------------------
    # CARTON/FG BIN LABELING
    # view-source:http://192.168.50.106:9296/messcada/production/carton_labeling?device=CLM-101B1
    # --------------------------------------------------------------------------
    r.on 'carton_labeling' do
      interactor = MesscadaApp::MesscadaInteractor.new(system_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.is do
        r.get do
          res = MesscadaApp::AddSystemResourceIncentiveToParams.call(params, has_button: true)
          res = interactor.carton_labeling(res.instance) if res.success
          if res.success
            res.instance
          else
            feedback = MesscadaApp::RobotFeedback.new(device: params[:device],
                                                      status: false,
                                                      msg: unwrap_failed_response(res),
                                                      line1: 'Label printing failed',
                                                      line6: 'Label printing failed')
            Crossbeams::RobotResponder.new(feedback).render
          end
        end
      end
    end

    r.on 'carton_verification' do
      interactor = MesscadaApp::MesscadaInteractor.new(system_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'weighing' do
        r.on 'labeling' do
          # --------------------------------------------------------------------------
          # CARTON/FG BIN VERIFICATION + WEIGHING + LABELING
          # view-source:http://192.168.50.106:9296/messcada/production/carton_verification/weighing/labeling?carton_number=123&gross_weight=600.23&measurement_unit=kg&device=CLM-01-B01
          # --------------------------------------------------------------------------

          r.get do
            res = interactor.carton_verification_and_weighing_and_labeling(params, request.ip)
            feedback = if res.success
                         MesscadaApp::RobotFeedback.new(device: params[:device],
                                                        status: true,
                                                        line1: res.message)
                       else
                         MesscadaApp::RobotFeedback.new(device: params[:device],
                                                        status: false,
                                                        line1: unwrap_failed_response(res))
                       end
            Crossbeams::RobotResponder.new(feedback).render
          end
        end

        # --------------------------------------------------------------------------
        # CARTON/FG BIN VERIFICATION + WEIGHING
        # view-source:http://192.168.50.106:9296/messcada/production/carton_verification/weighing?carton_number=123&gross_weight=600.23&measurement_unit=kg&device=CLM-01-B01
        # --------------------------------------------------------------------------
        r.get do
          res = interactor.carton_verification_and_weighing(params)
          feedback = if res.success
                       MesscadaApp::RobotFeedback.new(device: params[:device],
                                                      status: true,
                                                      line1: res.message)
                     else
                       MesscadaApp::RobotFeedback.new(device: params[:device],
                                                      status: false,
                                                      line1: unwrap_failed_response(res))
                     end
          Crossbeams::RobotResponder.new(feedback).render
        end
      end

      # --------------------------------------------------------------------------
      # PURE CARTON/FG BIN VERIFICATION
      # view-source:http://192.168.50.106:9296/messcada/production/carton_verification?carton_number=123&device=CLM-01-B01
      # --------------------------------------------------------------------------
      r.get do
        res = interactor.carton_verification(params[:carton_number])
        feedback = if res.success
                     MesscadaApp::RobotFeedback.new(device: params[:device],
                                                    status: true,
                                                    line1: res.message)
                   else
                     MesscadaApp::RobotFeedback.new(device: params[:device],
                                                    status: false,
                                                    line1: unwrap_failed_response(res))
                   end
        Crossbeams::RobotResponder.new(feedback).render
      rescue Rack::QueryParser::InvalidParameterError => e
        ErrorMailer.send_exception_email(e, subject: 'Carton verification invalid parameter', message: "Invalid param from route: #{request.path} with #{request.query_string}")

        feedback = MesscadaApp::RobotFeedback.new(device: '',
                                                  status: false,
                                                  line1: 'Unable to read barcode')
        return Crossbeams::RobotResponder.new(feedback).render
      end
    end

    # --------------------------------------------------------------------------
    # PALLET VERIFICATION/WEIGHING/LABELLING
    # view-source:http://192.168.43.148:9296/messcada/production/pallet_verification/pallet_weighing/pallet_labeling?pallet_number=123&device=CLM101B1&gross_weight=1134&measurement_unit=kg
    # --------------------------------------------------------------------------
    r.on 'pallet_verification' do
      r.on 'pallet_weighing' do
        r.on 'pallet_labeling' do
          interactor = MesscadaApp::MesscadaInteractor.new(system_user, {}, { route_url: request.path, request_ip: request.ip }, {})
          prod_run_interactor = ProductionApp::ProductionRunInteractor.new(system_user, {}, { route_url: request.path, request_ip: request.ip }, {})

          res = interactor.pallet_weighing_for_labeling(system_user, params)
          res = prod_run_interactor.print_pallet_label(res.instance[:pallet_id], printer:  LabelApp::PrinterRepo.new.robot_peripheral_printer(params[:device]), pallet_label_name: AppConst::DEFAULT_PALLET_LABEL_NAME) if res.success

          feedback = if res.success
                       MesscadaApp::RobotFeedback.new(device: params[:device],
                                                      status: true,
                                                      line1: res.message)
                     else
                       MesscadaApp::RobotFeedback.new(device: params[:device],
                                                      status: false,
                                                      msg: unwrap_failed_response(res))
                     end
          Crossbeams::RobotResponder.new(feedback).render
        end
      end
    end
  end
end
