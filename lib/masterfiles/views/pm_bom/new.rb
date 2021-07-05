# frozen_string_literal: true

module Masterfiles
  module Packaging
    module PmBom
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:pm_bom, :new, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New PKG BOM'
              form.action '/masterfiles/packaging/pm_boms'
              form.remote! if remote
              form.add_field :bom_code
              form.add_field :system_code
              form.add_field :erp_bom_code
              form.add_field :description
              form.add_field :label_description
              form.add_field :gross_weight
              form.add_field :nett_weight
            end
          end

          layout
        end
      end
    end
  end
end
