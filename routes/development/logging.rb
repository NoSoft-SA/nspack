# frozen_string_literal: true

class Nspack < Roda
  route 'logging', 'development' do |r|
    #
    # LOGGED ACTION DETAILS
    # --------------------------------------------------------------------------
    r.on 'logged_actions', Integer do |id|
      interactor = DevelopmentApp::LoggingInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(Sequel[:audit][:logged_actions], id) do
        handle_not_found(r)
      end

      r.is do
        r.get do       # SHOW
          check_auth!('logging', 'read')
          # using id of logged_action, build a grid of changes.
          show_page { Development::Logging::LoggedAction::Show.call(id) }
        end
      end

      r.on 'grid' do
        interactor.logged_actions_grid(id)
      rescue StandardError => e
        show_json_exception(e)
      end

      r.on 'diff' do
        left, right = interactor.diff_action(id)
        show_partial { Development::Logging::LoggedAction::Diff.call(id, left, right) }
      end

      r.on 'transaction_sql' do
        check_auth!('logging', 'read')
        sql = interactor.transaction_sql(id)
        show_partial { Development::Logging::LoggedAction::TransactionSql.call(id, sql) }
      end
    end

    # EXPORT DATA EVENT LOGS
    # --------------------------------------------------------------------------
    r.on 'export_data_event_logs', Integer do |id|
      interactor = DevelopmentApp::ExportDataEventLogInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:export_data_event_logs, id) do
        handle_not_found(r)
      end

      r.is do
        r.get do       # SHOW
          check_auth!('logging', 'read')
          show_partial { Development::Logging::ExportDataEventLog::Show.call(id) }
        end
      end
    end

    # QUE JOBS
    # --------------------------------------------------------------------------
    r.on 'que_jobs', Integer do |id|
      r.is do
        r.get do       # SHOW
          check_auth!('logging', 'read')
          show_partial { Development::Logging::QueJob::Show.call(id) }
        end
      end
    end

    r.on 'que_jobs' do
      r.on 'status' do
        check_auth!('logging', 'read')
        show_partial_or_page(r) { Development::Logging::QueJob::Status.call }
      end
    end
  end
end
