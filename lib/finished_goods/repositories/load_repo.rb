# frozen_string_literal: true

module FinishedGoodsApp
  class LoadRepo < BaseRepo # rubocop:disable Metrics/ClassLength
    build_for_select :loads,
                     label: :order_number,
                     value: :id,
                     order_by: :order_number
    build_inactive_select :loads,
                          label: :order_number,
                          value: :id,
                          order_by: :order_number

    crud_calls_for :loads, name: :load, wrapper: Load

    def find_load_flat(id)
      find_with_association(:loads,
                            id,
                            parent_tables: [{ parent_table: :voyage_ports,
                                              columns: %i[port_id voyage_id eta ata],
                                              foreign_key: :pod_voyage_port_id,
                                              flatten_columns: { port_id: :pod_port_id, voyage_id: :voyage_id, eta: :eta, ata: :ata } },
                                            { parent_table: :voyage_ports,
                                              columns: %i[port_id etd atd],
                                              foreign_key: :pol_voyage_port_id,
                                              flatten_columns: { port_id: :pol_port_id, etd: :etd, atd: :atd } },
                                            { parent_table: :voyages,
                                              columns: %i[voyage_type_id vessel_id voyage_number year voyage_code],
                                              foreign_key: :voyage_id,
                                              flatten_columns: { voyage_type_id: :voyage_type_id,
                                                                 vessel_id: :vessel_id,
                                                                 voyage_number: :voyage_number,
                                                                 voyage_code: :voyage_code,
                                                                 year: :year } }],
                            sub_tables: [{ sub_table: :load_voyages,
                                           columns: %i[shipping_line_party_role_id
                                                       shipper_party_role_id
                                                       booking_reference
                                                       memo_pad],
                                           one_to_one: { shipping_line_party_role_id: :shipping_line_party_role_id,
                                                         shipper_party_role_id: :shipper_party_role_id,
                                                         booking_reference: :booking_reference,
                                                         memo_pad: :memo_pad } },
                                         { sub_table: :load_vehicles,
                                           columns: %i[vehicle_number],
                                           one_to_one: { vehicle_number: :vehicle_number } },
                                         { sub_table: :load_containers,
                                           columns: %i[container_code],
                                           one_to_one: { container_code: :container_code } }],
                            lookup_functions: [{ function: :fn_current_status,
                                                 args: ['loads', id],
                                                 col_name: :status }],
                            wrapper: LoadFlat)
    end

    def last_load(exclude_shipped: false)
      ds = DB[:loads].order(:updated_at)
      ds = ds.exclude(shipped: true) if exclude_shipped
      ds.reverse.limit(1).get(:id)
    end

    def allocate_pallets(load_id, pallet_numbers, user_name)
      pallet_ids = select_values(:pallets, :id, pallet_number: pallet_numbers)
      return ok_response if pallet_ids.empty?

      DB[:pallets].where(id: pallet_ids).update(load_id: load_id, allocated: true, allocated_at: Time.now)
      log_multiple_statuses(:pallets, pallet_ids, 'ALLOCATED', user_name: user_name)

      # updates load status allocated
      DB[:loads].where(id: load_id).update(allocated: true, allocated_at: Time.now)
      log_status(:loads, load_id, 'ALLOCATED', user_name: user_name)

      ok_response
    end

    def unallocate_pallets(load_id, pallet_numbers, user_name) # rubocop:disable Metrics/AbcSize
      pallet_ids = select_values(:pallets, :id, pallet_number: pallet_numbers)
      return ok_response if pallet_ids.empty?

      DB[:pallets].where(id: pallet_ids).update(load_id: nil, allocated: false)
      log_multiple_statuses(:pallets, pallet_ids, 'UNALLOCATED', user_name: user_name)

      # find unallocated loads
      allocated_load_ids = DB[:pallets].where(load_id: load_id).distinct.select_map(:load_id)
      unallocated_load_ids = [load_id] - allocated_load_ids

      # log status for loads where all pallets have been unallocated
      unless unallocated_load_ids.empty?
        DB[:loads].where(id: unallocated_load_ids, shipped: false).update(allocated: false)
        log_multiple_statuses(:loads, unallocated_load_ids, 'UNALLOCATED', user_name: user_name)
      end

      ok_response
    end

    def org_code_for_po(load_id)
      pr_id = DB[:loads].where(id: load_id).get(:exporter_party_role_id)
      DB.get(Sequel.function(:fn_party_role_org_code, pr_id))
    end

    def update_pallets_shipped_at(load_id, shipped_at)
      DB[:pallets].where(load_id: load_id).update(shipped_at: shipped_at)
    end

    def set_pallets_target_customer(target_customer_id, pallet_ids)
      existing_pallet_ids = select_values(:pallets, :id, target_customer_party_role_id: target_customer_id)
      removed_pallet_ids = existing_pallet_ids - pallet_ids
      new_pallet_ids = pallet_ids - existing_pallet_ids
      DB[:pallets].where(id: removed_pallet_ids).update(target_customer_party_role_id: nil)
      DB[:pallets].where(id: new_pallet_ids).update(target_customer_party_role_id: target_customer_id)
    end
  end
end
