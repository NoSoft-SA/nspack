# frozen_string_literal: true

module UiRules
  class RmtClassRule < Base
    def generate_rules
      @repo = MasterfilesApp::FruitRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode
      # set_complete_fields if @mode == :complete
      # set_approve_fields if @mode == :approve

      # add_approve_behaviours if @mode == :approve

      form_name 'rmt_class'
    end

    def set_show_fields
      fields[:rmt_class_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    # def set_approve_fields
    #   set_show_fields
    #   fields[:approve_action] = { renderer: :select, options: [%w[Approve a], %w[Reject r]], required: true }
    #   fields[:reject_reason] = { renderer: :textarea, disabled: true }
    # end

    # def set_complete_fields
    #   set_show_fields
    #   user_repo = DevelopmentApp::UserRepo.new
    #   fields[:to] = { renderer: :select, options: user_repo.email_addresses(user_email_group: AppConst::EMAIL_GROUP_RMT_CLASS_APPROVERS), caption: 'Email address of person to notify', required: true }
    # end

    def common_fields
      {
        rmt_class_code: { required: true },
        description: { required: true }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_rmt_class(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(rmt_class_code: nil,
                                    description: nil)
    end

    # private

    # def add_approve_behaviours
    #   behaviours do |behaviour|
    #     behaviour.enable :reject_reason, when: :approve_action, changes_to: ['r']
    #   end
    # end
  end
end
