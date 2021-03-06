# frozen_string_literal: true

module UiRules
  class InnerPmMarkRule < Base
    def generate_rules
      @repo = MasterfilesApp::InnerPmMarkRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'inner_pm_mark'
    end

    def set_show_fields
      fields[:inner_pm_mark_code] = { renderer: :label, caption: 'Inner PKG Mark' }
      fields[:description] = { renderer: :label }
      fields[:tu_mark] = { renderer: :label, as_boolean: true, caption: 'TU Mark' }
      fields[:ri_mark] = { renderer: :label, as_boolean: true, caption: 'Fruit Mark' }
      fields[:ru_mark] = { renderer: :label, as_boolean: true, caption: 'RU Mark' }
    end

    def common_fields
      {
        inner_pm_mark_code: { caption: 'Inner PKG Mark', required: true, force_uppercase: true },
        description: { required: true },
        tu_mark: { renderer: :checkbox, caption: 'TU Mark' },
        ri_mark: { renderer: :checkbox, caption: 'Fruit Mark' },
        ru_mark: { renderer: :checkbox, caption: 'RU Mark' }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_inner_pm_mark(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(inner_pm_mark_code: nil,
                                    description: nil,
                                    tu_mark: false,
                                    ri_mark: false,
                                    ru_mark: false)
    end
  end
end
