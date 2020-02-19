# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
class Nspack < Roda
  route 'config', 'quality' do |r|
    # ORCHARD TEST TYPES
    # --------------------------------------------------------------------------
    r.on 'orchard_test_types', Integer do |id|
      interactor = QualityApp::OrchardTestTypeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:orchard_test_types, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('config', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial_or_page(r) { Quality::Config::OrchardTestType::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('config', 'read')
          show_partial_or_page(r) { Quality::Config::OrchardTestType::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_orchard_test_type(id, params[:orchard_test_type])
          if res.success
            flash[:notice] = res.message
            redirect_to_last_grid(r)
          else
            re_show_form(r, res) { Quality::Config::OrchardTestType::Edit.call(id, form_values: params[:orchard_test_type], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('config', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_orchard_test_type(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'orchard_test_types' do
      interactor = QualityApp::OrchardTestTypeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('config', 'new')
        show_partial_or_page(r) { Quality::Config::OrchardTestType::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_orchard_test_type(params[:orchard_test_type])
        if res.success
          flash[:notice] = res.message
          redirect_to_last_grid(r)
        else
          re_show_form(r, res, url: '/quality/config/orchard_test_types/new') do
            Quality::Config::OrchardTestType::New.call(form_values: params[:orchard_test_type],
                                                       form_errors: res.errors,
                                                       remote: fetch?(r))
          end
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
