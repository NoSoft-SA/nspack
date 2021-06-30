# frozen_string_literal: true

module ProductionApp
  module ResourceFactory
    def create_plant_resource(opts = {}) # rubocop:disable Metrics/AbcSize
      id = get_available_factory_record(:plant_resources, opts)
      return id unless id.nil?

      opts[:plant_resource_type_id] ||= create_plant_resource_type
      opts[:system_resource_id] ||= create_system_resource
      opts[:location_id] ||= create_location

      packhouse_no = opts.delete(:packhouse_no) || 1
      gln = opts.delete(:gln) || '11111111'
      phc = opts.delete(:phc) || '1111'
      DB["create sequence public.gln_seq_for_#{gln}"].first

      default = {
        plant_resource_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        resource_properties: BaseRepo.new.hash_for_jsonb_col(packhouse_no: packhouse_no, gln: gln, phc: phc),
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:plant_resources].insert(default.merge(opts))
    end

    def create_plant_resource_type(opts = {})
      default = {
        plant_resource_type_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        icon: Faker::Lorem.word,
        packpoint: false,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:plant_resource_types].insert(default.merge(opts))
    end

    def create_system_resource(opts = {})
      id = get_available_factory_record(:system_resources, opts)
      return id unless id.nil?

      opts[:system_resource_type_id] ||= create_system_resource_type
      opts[:plant_resource_type_id] ||= create_plant_resource_type
      default = {
        system_resource_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:system_resources].insert(default.merge(opts))
    end

    def create_system_resource_type(opts = {})
      default = {
        system_resource_type_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        computing_device: false,
        peripheral: false,
        icon: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:system_resource_types].insert(default.merge(opts))
    end
  end
end
