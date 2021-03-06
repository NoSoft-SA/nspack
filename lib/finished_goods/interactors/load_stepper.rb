# frozen_string_literal: true

module FinishedGoodsApp
  class LoadStep < BaseStep
    def initialize(step_key, user, ip)
      super(user, step_key, ip)
    end

    def allocate_pallet(scanned_number)
      case scanned_number
      when *allocated
        allocated.delete(scanned_number)
        message = "Removed: #{scanned_number}"
      else
        allocated << scanned_number
        message = "Added: #{scanned_number}"
      end
      write(current_step)
      message
    end

    def load_pallet(scanned_number) # rubocop:disable Metrics/AbcSize
      case scanned_number
      when *allocated
        scanned << allocated.delete(scanned_number)
        form_state[:error_message] = nil
        message = "Loaded: #{scanned_number}"
      when *scanned
        allocated << scanned.delete(scanned_number)
        form_state[:error_message] = nil
        message = "Unloaded: #{scanned_number}"
      else
        form_state[:error_message] = "Pallet number: #{scanned_number}, not on load: #{form_state[:load_id]}"
      end
      write(current_step)
      message
    end

    def setup_load(load_id)
      load_flat = LoadRepo.new.find_load(load_id)
      initial_count = LoadRepo.new.all_hash(:pallets, load_id: load_id).length

      raise 'Setup Load called without load_id' if load_flat.nil?

      form_state = { load_id: load_id,
                     allocation_count: initial_count }
      %i[voyage_code vehicle_number container_code requires_temp_tail temp_tail].each do |k|
        form_state[k] = load_flat.to_h[k]
      end

      allocated = LoadRepo.new.select_values(:pallets, :pallet_number, load_id: load_id)

      write(form_state: form_state, allocated: allocated, initial_allocated: allocated.clone, scanned: [])
    end

    def id
      form_state && form_state[:load_id]
    end

    def form_state
      current_step[:form_state] ||= {}
    end

    def allocated
      current_step[:allocated] ||= []
    end

    def initial_allocated
      current_step[:initial_allocated] ||= []
    end

    def scanned
      current_step[:scanned] ||= []
    end

    def ready_to_ship?
      allocated.empty?
    end

    def error?
      !form_state[:error_message].nil?
    end

    def progress_count
      allocated.length
    end

    def allocation_progress
      allocated.nil_or_empty? ? nil : "Pallets allocated: #{progress_count}<br>#{allocated.join('<br>')}"
    end

    def progress
      return '' if current_step.nil?

      scanned_progress = scanned.nil_or_empty? ? '' : "<br>Scanned Pallets<br>#{scanned.join('<br>')}"
      <<~HTML
        Pallets to scan: #{progress_count}<br>#{allocated.join('<br>')}<br>
        #{scanned_progress}
      HTML
    end

    private

    def current_step
      @current_step ||= read || {}
    end
  end
end
