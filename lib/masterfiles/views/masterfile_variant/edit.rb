# frozen_string_literal: true

module Masterfiles
  module General
    module MasterfileVariant
      class Edit
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:masterfile_variant, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Masterfile Variant'
              form.action "/masterfiles/general/masterfile_variants/#{id}"
              form.remote!
              form.method :update
              form.add_field :variant
              form.add_field :masterfile_code
              form.add_field :variant_code
            end
          end

          layout
        end
      end
    end
  end
end
