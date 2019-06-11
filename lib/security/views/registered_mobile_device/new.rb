# frozen_string_literal: true

module Security
  module Rmd
    module RegisteredMobileDevice
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:registered_mobile_device, :new, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.action '/security/rmd/registered_mobile_devices'
              form.remote! if remote
              form.add_field :ip_address
              form.add_field :start_page_program_function_id
              form.add_field :scan_with_camera
            end
          end

          layout
        end
      end
    end
  end
end
