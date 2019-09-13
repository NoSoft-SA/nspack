# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength

class Nspack < Roda
  # route 'publish', 'labels' do |r|
  route 'publish', 'labels' do |r|
    # BATCH PUBLISH
    # --------------------------------------------------------------------------
    interactor = LabelApp::PublishInteractor.new(current_user, {}, { route_url: request.path }, {})

    r.on 'batch' do
      r.is do
        show_page { Labels::Publish::Batch::Targets.call }
        # (If coming from "BACK" button, show plain section using cached list of targets
      end

      r.get 'callback_for_targets' do
        res = interactor.publishing_server_options
        # stash....
        if res.success
          show_in_callback { Labels::Publish::Batch::SelectTargets.call(res.instance) }
        elsif res.instance[:timeout]
          show_in_callback(content: 'Unable to get information - the server took too long to respond.',
                           content_style: :error,
                           error: res.message)
        elsif res.instance[:refused]
          show_in_callback(content: 'Unable to get information - the server might not be running.',
                           content_style: :error,
                           error: res.message)
        else
          show_json_error(res.message, status: 200)
        end
      end

      r.post 'select_labels' do
        res = interactor.select_targets(params[:batch]) #=> validate resolution
        show_page { Labels::Publish::Batch::SelectLabels.call(res.instance) }
        # VALIDATE: 1) printer chosen; 2) Server chosen, 3) Chosen server is configured for the chosen printer.
        # Store params in step (selected targets)
        # Get list of ELIGIBLE labels (approved) with publish history (Show date updated - max published date as days since published)
      end

      r.post 'publish' do
        # Validate: cannot publish multi without sub-labels...
        res = interactor.save_label_selections(multiselect_grid_choices(params))
        show_page { Labels::Publish::Batch::Publish.call(res.instance) }
      end

      r.get 'callback_for_send' do
        res = interactor.publish_labels # (store.read(:lbl_publish_steps))
        { content: render_partial { Labels::Publish::Batch::Send.call(res) } }.to_json
      end

      r.get 'feedback' do
        res = interactor.publishing_status
        if res.success
          content = render_partial { Labels::Publish::Batch::PublishState.call(res.instance) }
          payload = { content: content, continuePolling: !res.instance.done }
          payload[:finaliseProgressStep] = 'cbl-current-step' if res.instance.done
          { updateMessage: payload }.to_json
        else
          # Need to check res.instance - 204 means nothing sent yet; 404 means invalid file sent.
          { updateMessage: { content: res.message, continuePolling: true } }.to_json
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
