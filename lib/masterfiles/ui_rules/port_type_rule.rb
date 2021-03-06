# frozen_string_literal: true

module UiRules
  class PortTypeRule < Base
    def generate_rules
      @repo = MasterfilesApp::PortTypeRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'port_type'
    end

    def set_show_fields
      fields[:port_type_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        port_type_code: { required: true, force_uppercase: true },
        description: {}
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_port_type(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(port_type_code: nil,
                                    description: nil)
    end
  end
end
