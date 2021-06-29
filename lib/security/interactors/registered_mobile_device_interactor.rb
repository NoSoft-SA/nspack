# frozen_string_literal: true

module SecurityApp
  class RegisteredMobileDeviceInteractor < BaseInteractor
    def repo
      @repo ||= RegisteredMobileDeviceRepo.new
    end

    def registered_mobile_device(id)
      repo.find_registered_mobile_device(id)
    end

    def validate_registered_mobile_device_params(params)
      RegisteredMobileDeviceSchema.call(params)
    end

    def rmd_for_ip(ip_address)
      instance = repo.find_by_ip_address(ip_address)
      if instance
        success_response('ok', instance)
      else
        failed_response('not set')
      end
    end

    def setup_rmd(ip_address, params)
      instance = repo.find_by_ip_address(ip_address)
      if instance
        res = validate_registered_mobile_device_params(instance.to_h.merge(params))
        repo.update_registered_mobile_device(instance.id, res)
      else
        res = validate_registered_mobile_device_params(params.merge(ip_address: ip_address))
        repo.create_registered_mobile_device(res)
      end
    end

    def create_registered_mobile_device(params)
      res = validate_registered_mobile_device_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_registered_mobile_device(res)
        log_status(:registered_mobile_devices, id, 'CREATED')
        log_transaction
      end
      instance = registered_mobile_device(id)
      success_response("Created registered mobile device #{instance[:ip_address]}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { ip_address: ['This registered mobile device already exists'] }))
    end

    def update_registered_mobile_device(id, params) # rubocop:disable Metrics/AbcSize
      res = validate_registered_mobile_device_params(params)
      return validation_failed_response(res) if res.failure?

      attrs = res.to_h
      robot = attrs.delete(:act_as_robot)
      res_id, read_id = (robot || '').split('_')
      repo.transaction do
        repo.update_registered_mobile_device(id, attrs.merge(act_as_system_resource_id: res_id, act_as_reader_id: read_id))
        log_transaction
      end
      instance = registered_mobile_device(id)
      success_response("Updated registered mobile device #{instance[:ip_address]}",
                       instance)
    end

    def delete_registered_mobile_device(id)
      name = registered_mobile_device(id).ip_address
      repo.transaction do
        repo.delete_registered_mobile_device(id)
        log_status(:registered_mobile_devices, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted registered mobile device #{name}")
    end

    def toggle_camera_scan(ip_address)
      rmd = repo.find_by_ip_address(ip_address)
      return failed_response('This device is not a Registered Mobile Device') if rmd.nil?

      repo.update_registered_mobile_device(rmd.id, scan_with_camera: !rmd.scan_with_camera)
      instance = registered_mobile_device(rmd.id)
      success_response("Toggled camera scan #{instance[:ip_address]}",
                       instance)
    end
  end
end
