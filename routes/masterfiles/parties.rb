# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
# rubocop:disable Metrics/BlockLength

class Nspack < Roda
  route 'parties', 'masterfiles' do |r|
    r.on 'organizations', Integer do |id|
      interactor = MasterfilesApp::OrganizationInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:organizations, id) do
        handle_not_found(r)
      end

      r.on 'edit' do
        check_auth!('parties', 'edit')
        show_partial { Masterfiles::Parties::Organization::Edit.call(id) }
      end
      r.is do
        r.get do
          check_auth!('parties', 'read')
          show_partial { Masterfiles::Parties::Organization::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_organization(id, params[:organization])
          if res.success
            update_grid_row(id, changes: { party_id: res.instance[:party_id],
                                           parent: res.instance[:parent_organization],
                                           short_description: res.instance[:short_description],
                                           medium_description: res.instance[:medium_description],
                                           long_description: res.instance[:long_description],
                                           vat_number: res.instance[:vat_number] },
                                notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Parties::Organization::Edit.call(id, params[:organization], res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('parties', 'delete')
          res = interactor.delete_organization(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            flash[:error] = res.message
            redirect_to_last_grid(r)
          end
        end
      end
    end
    r.on 'organizations' do
      interactor = MasterfilesApp::OrganizationInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.on 'changed', String do |field|
        if field == 'short_desc'
          if params[:changed_value].length > 2
            json_show_element('short_desc_warn')
          else
            json_hide_element('short_desc_warn')
          end
        end
      end

      r.on 'new' do
        check_auth!('parties', 'new')
        show_partial_or_page(r) { Masterfiles::Parties::Organization::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_organization(params[:organization])
        if res.success
          flash[:notice] = res.message
          redirect_to_last_grid(r)
        else
          re_show_form(r, res, url: '/masterfiles/parties/organizations/new') do
            Masterfiles::Parties::Organization::New.call(form_values: params[:organization],
                                                         form_errors: res.errors,
                                                         remote: fetch?(r))
          end
        end
      end
    end

    r.on 'people', Integer do |id|
      interactor = MasterfilesApp::PersonInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:people, id) do
        handle_not_found(r)
      end

      r.on 'edit' do
        check_auth!('parties', 'edit')
        show_partial { Masterfiles::Parties::Person::Edit.call(id) }
      end
      r.is do
        r.get do
          check_auth!('parties', 'read')
          show_partial { Masterfiles::Parties::Person::Show.call(id) }
        end
        r.patch do
          res = interactor.update_person(id, params[:person])
          if res.success
            update_grid_row(id,
                            changes: { title: res.instance[:title],
                                       first_name: res.instance[:first_name],
                                       surname: res.instance[:surname],
                                       vat_number: res.instance[:vat_number] },
                            notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Parties::Person::Edit.call(id, params[:person], res.errors) }
          end
        end
        r.delete do
          check_auth!('parties', 'delete')
          res = interactor.delete_person(id)
          delete_grid_row(id, notice: res.message)
        end
      end
    end
    r.on 'people' do
      interactor = MasterfilesApp::PersonInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do
        check_auth!('parties', 'new')
        show_partial_or_page(r) { Masterfiles::Parties::Person::New.call(remote: fetch?(r)) }
      end
      r.post do
        res = interactor.create_person(params[:person])
        if res.success
          flash[:notice] = res.message
          redirect_to_last_grid(r)
        else
          re_show_form(r, res, url: '/masterfiles/parties/people/new') do
            Masterfiles::Parties::Person::New.call(form_values: params[:person],
                                                   form_errors: res.errors,
                                                   remote: fetch?(r))
          end
        end
      end
    end

    r.on 'addresses', Integer do |id|
      interactor = MasterfilesApp::AddressInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:addresses, id) do
        handle_not_found(r)
      end

      r.on 'edit' do
        check_auth!('parties', 'edit')
        show_partial { Masterfiles::Parties::Address::Edit.call(id) }
      end
      r.is do
        r.get do
          check_auth!('parties', 'read')
          show_partial { Masterfiles::Parties::Address::Show.call(id) }
        end
        r.patch do
          res = interactor.update_address(id, params[:address])
          if res.success
            update_grid_row(id,
                            changes: { address_type_id: res.instance[:address_type_id],
                                       address_line_1: res.instance[:address_line_1],
                                       address_line_2: res.instance[:address_line_2],
                                       address_line_3: res.instance[:address_line_3],
                                       city: res.instance[:city],
                                       postal_code: res.instance[:postal_code],
                                       country: res.instance[:country] },
                            notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Parties::Address::Edit.call(id, params[:address], res.errors) }
          end
        end
        r.delete do
          check_auth!('parties', 'delete')
          res = interactor.delete_address(id)
          delete_grid_row(id, notice: res.message)
        end
      end
    end
    r.on 'addresses' do
      interactor = MasterfilesApp::AddressInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do
        check_auth!('parties', 'new')
        show_partial_or_page(r) { Masterfiles::Parties::Address::New.call(remote: fetch?(r)) }
      end
      r.post do
        res = interactor.create_address(params[:address])
        if res.success
          flash[:notice] = res.message
          redirect_to_last_grid(r)
        else
          re_show_form(r, res, url: '/masterfiles/parties/addresses/new') do
            Masterfiles::Parties::Address::New.call(form_values: params[:address],
                                                    form_errors: res.errors,
                                                    remote: fetch?(r))
          end
        end
      end
    end

    r.on 'contact_methods', Integer do |id|
      interactor = MasterfilesApp::ContactMethodInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:contact_methods, id) do
        handle_not_found(r)
      end

      r.on 'edit' do
        check_auth!('parties', 'edit')
        show_partial { Masterfiles::Parties::ContactMethod::Edit.call(id) }
      end
      r.is do
        r.get do
          check_auth!('parties', 'read')
          show_partial { Masterfiles::Parties::ContactMethod::Show.call(id) }
        end
        r.patch do
          res = interactor.update_contact_method(id, params[:contact_method])
          if res.success
            update_grid_row(id,
                            changes: { contact_method_type_id: res.instance[:contact_method_type_id],
                                       contact_method_code: res.instance[:contact_method_code] },
                            notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Parties::ContactMethod::Edit.call(id, params[:contact_method], res.errors) }
          end
        end
        r.delete do
          check_auth!('parties', 'delete')
          res = interactor.delete_contact_method(id)
          delete_grid_row(id, notice: res.message)
        end
      end
    end
    r.on 'contact_methods' do
      interactor = MasterfilesApp::ContactMethodInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do
        check_auth!('parties', 'new')
        show_partial_or_page(r) { Masterfiles::Parties::ContactMethod::New.call(remote: fetch?(r)) }
      end
      r.post do
        res = interactor.create_contact_method(params[:contact_method])
        if res.success
          flash[:notice] = res.message
          redirect_to_last_grid(r)
        else
          re_show_form(r, res, url: '/masterfiles/parties/contact_methods/new') do
            Masterfiles::Parties::ContactMethod::New.call(form_values: params[:contact_method],
                                                          form_errors: res.errors,
                                                          remote: fetch?(r))
          end
        end
      end
    end

    r.on 'link_addresses', Integer do |id|
      r.post do
        interactor = MasterfilesApp::PartyInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

        res = interactor.link_addresses(id, multiselect_grid_choices(params))
        if res.success
          flash[:notice] = res.message
        else
          flash[:error] = res.message
        end
        redirect_to_last_grid(r)
      end
    end
    r.on 'link_contact_methods', Integer do |id|
      r.post do
        interactor = MasterfilesApp::PartyInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

        res = interactor.link_contact_methods(id, multiselect_grid_choices(params))
        if res.success
          flash[:notice] = res.message
        else
          flash[:error] = res.message
        end
        redirect_to_last_grid(r)
      end
    end
  end
end

# rubocop:enable Metrics/ClassLength
# rubocop:enable Metrics/BlockLength
