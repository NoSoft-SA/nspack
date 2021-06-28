# frozen_string_literal: true

module MasterfilesApp
  module PackagingFactory # rubocop:disable Metrics/ModuleLength
    def create_pallet_base(opts = {})
      id = get_available_factory_record(:pallet_bases, opts)
      return id unless id.nil?

      default = {
        pallet_base_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        length: Faker::Number.number(digits: 4),
        width: Faker::Number.number(digits: 4),
        edi_in_pallet_base: Faker::Lorem.word,
        edi_out_pallet_base: Faker::Lorem.word,
        cartons_per_layer: Faker::Number.number(digits: 4),
        material_mass: Faker::Number.decimal,
        active: true
      }
      DB[:pallet_bases].insert(default.merge(opts))
    end

    def create_pallet_stack_type(opts = {})
      id = get_available_factory_record(:pallet_stack_types, opts)
      return id unless id.nil?

      default = {
        stack_type_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        stack_height: Faker::Number.number(digits: 4),
        active: true
      }
      DB[:pallet_stack_types].insert(default.merge(opts))
    end

    def create_pallet_format(opts = {})
      id = get_available_factory_record(:pallet_formats, opts)
      return id unless id.nil?

      pallet_base_id = create_pallet_base
      pallet_stack_type_id = create_pallet_stack_type
      default = {
        description: Faker::Lorem.unique.word,
        pallet_base_id: pallet_base_id,
        pallet_stack_type_id: pallet_stack_type_id,
        active: true
      }
      DB[:pallet_formats].insert(default.merge(opts))
    end

    def create_cartons_per_pallet(opts = {})
      id = get_available_factory_record(:cartons_per_pallet, opts)
      return id unless id.nil?

      pallet_format_id = create_pallet_format
      basic_pack_code_id = create_basic_pack
      default = {
        description: Faker::Lorem.unique.word,
        pallet_format_id: pallet_format_id,
        basic_pack_id: basic_pack_code_id,
        cartons_per_pallet: Faker::Number.number(digits: 4),
        layers_per_pallet: Faker::Number.number(digits: 4),
        active: true
      }
      DB[:cartons_per_pallet].insert(default.merge(opts))
    end

    def create_pm_composition_level(opts = {})
      id = get_available_factory_record(:pm_composition_levels, opts)
      return id unless id.nil?

      default = {
        composition_level: Faker::Number.number(digits: 4),
        description: Faker::Lorem.unique.word,
        active: true
      }
      DB[:pm_composition_levels].insert(default.merge(opts))
    end

    def create_pm_type(opts = {})
      id = get_available_factory_record(:pm_types, opts)
      return id unless id.nil?

      pm_composition_level_id = create_pm_composition_level
      default = {
        pm_composition_level_id: pm_composition_level_id,
        pm_type_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        short_code: Faker::Lorem.word
      }
      DB[:pm_types].insert(default.merge(opts))
    end

    def create_pm_subtype(opts = {})
      id = get_available_factory_record(:pm_subtypes, opts)
      return id unless id.nil?

      pm_type_id = create_pm_type
      default = {
        pm_type_id: pm_type_id,
        subtype_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        short_code: Faker::Lorem.word
      }
      DB[:pm_subtypes].insert(default.merge(opts))
    end

    def create_pm_product(opts = {})
      id = get_available_factory_record(:pm_products, opts)
      return id unless id.nil?

      opts[:pm_subtype_id] ||= create_pm_subtype
      opts[:basic_pack_id] ||= create_basic_pack
      default = {
        erp_code: Faker::Lorem.unique.word,
        product_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        material_mass: Faker::Number.decimal,
        height_mm: Faker::Number.number(digits: 4),
        gross_weight_per_unit: nil,
        items_per_unit: Faker::Number.number(digits: 4)
      }
      DB[:pm_products].insert(default.merge(opts))
    end

    def create_pm_bom(opts = {})
      id = get_available_factory_record(:pm_boms, opts)
      return id unless id.nil?

      default = {
        bom_code: Faker::Lorem.unique.word,
        erp_bom_code: Faker::Lorem.word,
        description: Faker::Lorem.word,
        active: true,
        system_code: Faker::Lorem.word,
        gross_weight: Faker::Number.decimal,
        nett_weight: Faker::Number.decimal
      }
      DB[:pm_boms].insert(default.merge(opts))
    end

    def create_pm_boms_product(opts = {})
      id = get_available_factory_record(:pm_boms_products, opts)
      return id unless id.nil?

      opts[:pm_product_id] ||= create_pm_product(force_create: true)
      opts[:pm_bom_id] ||= create_pm_bom(force_create: true)
      opts[:uom_id] ||= create_uom

      default = {
        quantity: Faker::Number.decimal,
        active: true
      }
      DB[:pm_boms_products].insert(default.merge(opts))
    end

    def create_packing_method(opts = {})
      id = get_available_factory_record(:packing_methods, opts)
      return id unless id.nil?

      default = {
        packing_method_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        actual_count_reduction_factor: Faker::Number.decimal,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:packing_methods].insert(default.merge(opts))
    end

    def create_pm_mark(opts = {})
      id = get_available_factory_record(:pm_marks, opts)
      return id unless id.nil?

      mark_id = create_mark
      default = {
        mark_id: mark_id,
        packaging_marks: BaseRepo.new.array_of_text_for_db_col(%w[A B C]),
        description: Faker::Lorem.unique.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:pm_marks].insert(default.merge(opts))
    end

    def create_label_template(opts = {})
      id = get_available_factory_record(:label_templates, opts)
      return id unless id.nil?

      default = {
        label_template_name: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        application: Faker::Lorem.word,
        variables: BaseRepo.new.array_of_text_for_db_col(%w[A B C]),
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:label_templates].insert(default.merge(opts))
    end
  end
end
