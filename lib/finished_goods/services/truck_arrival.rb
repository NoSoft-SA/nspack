# frozen_string_literal: true

module FinishedGoodsApp
  class TruckArrival < BaseService
    attr_reader :vehicle_params, :container_params, :load_id, :user_name, :messages

    def initialize(load_id, vehicle_attrs, container_attrs, user)
      @vehicle_params = vehicle_attrs.to_h
      @container_params = container_attrs.to_h

      @load_id = load_id
      @vehicle_id = @vehicle_params.delete(:load_vehicle_id)
      @container_id = @container_params.delete(:load_container_id)

      @user_name = user.user_name
      @messages = []
    end

    def call
      create_vehicle
      update_vehicle
      delete_container_when_not_required

      unless @container_params.empty?
        create_container
        update_container
      end
      success_response(messages.join(', '), load_id)
    end

    private

    def delete_container_when_not_required
      container_id = repo.get_id(:load_containers, load_id: load_id)
      return if container_id.nil? | !@container_params.empty?

      container_repo.delete_load_container(container_id)
      messages << 'Deleted container'
    end

    def create_vehicle
      return unless @vehicle_id.nil?

      vehicle_id = vehicle_repo.create_load_vehicle(@vehicle_params)
      repo.log_status(:load_vehicles, vehicle_id, 'CREATED', user_name: @user_name)
      repo.log_status(:loads, @load_id, 'TRUCK ARRIVED', user_name: @user_name)
      pallet_ids = repo.select_values(:pallets, :id, load_id: @load_id)
      repo.log_multiple_statuses(:pallets, pallet_ids, 'TRUCK ARRIVED', user_name: @user_name)
      messages << 'Logged Truck Arrival'
    end

    def update_vehicle
      return if @vehicle_id.nil?

      # compare instance with vehicle_params
      instance = vehicle_repo.find_load_vehicle(@vehicle_id).to_h.reject { |k, _| %i[id active].include?(k) }
      return if instance == @vehicle_params

      vehicle_repo.update_load_vehicle(@vehicle_id, @vehicle_params)
      messages << 'Updated load vehicle'
    end

    def create_container
      return unless @container_id.nil?

      container_id = container_repo.create_load_container(@container_params)
      repo.log_status(:load_containers, container_id, 'CREATED', user_name: @user_name)
      messages << 'Created load container'
    end

    def update_container
      return if @container_id.nil?

      # compare instance with container_params
      ignore = %i[id active tare_weight max_payload actual_payload]
      ignore = %i[id active] if AppConst::CR_FG.verified_gross_mass_required_for_loads?

      instance = container_repo.find_load_container(@container_id).to_h.reject { |k, _| ignore.include?(k) }
      # update date field if weight changed
      @container_params[:verified_gross_weight_date] = Time.now if instance[:verified_gross_weight] != @container_params[:verified_gross_weight]
      return if instance == @container_params

      container_repo.update_load_container(@container_id, @container_params)
      messages << 'Updated load container'
    end

    def repo
      @repo ||= LoadRepo.new
    end

    def vehicle_repo
      @vehicle_repo ||= LoadVehicleRepo.new
    end

    def container_repo
      @container_repo ||= LoadContainerRepo.new
    end
  end
end
