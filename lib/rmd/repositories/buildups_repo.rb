# frozen_string_literal: true

module RmdApp
  class BuildupsRepo < BaseRepo
    build_for_select :pallet_buildups,
                     label: :destination_pallet_number,
                     value: :id,
                     no_active_check: true,
                     order_by: :destination_pallet_number

    crud_calls_for :pallet_buildups, name: :pallet_buildup, wrapper: PalletBuildup

    def get_shipped(pallets)
      DB[:pallets].where(pallet_number: pallets, shipped: true).select_map(:pallet_number)
    end

    def get_scrapped(pallets)
      DB[:pallets].where(pallet_number: pallets, scrapped: true).select_map(:pallet_number)
    end

    def get_zero_qty_pallets(pallets)
      DB[:pallets].where(pallet_number: pallets, carton_quantity: 0).select_map(:pallet_number)
    end

    def get_build_up_pallets(pallets) # rubocop:disable Metrics/AbcSize
      cond = pallets.map { |p| "'#{p}' = ANY (b.source_pallets)" }.join(' or ')
      query = "SELECT *
               FROM pallet_buildups b
               WHERE b.completed is false AND (b.destination_pallet_number IN ('#{pallets.join("','")}') OR #{cond})"
      buildups = DB[query].all
      (buildups.map { |r| r[:source_pallets] }.flatten.uniq + buildups.map { |r| r[:destination_pallet_number] }.flatten.uniq) & pallets
    end

    def pallets_ctn_qty_sum(pallets)
      DB[:pallets].where(pallet_number: pallets).select_map(:carton_quantity).sum
    end

    def get_pallets(pallets)
      DB[:pallets].where(pallet_number: pallets).select_map(:pallet_number)
    end

    def buildup_carton?(carton_number, pallet_buildup_id)
      query = <<~SQL
        select id
        from pallet_buildups
        where id = ?
        AND (select distinct s.pallet_number
        from cartons c
        join pallet_sequences s on s.id=c.pallet_sequence_id
        where c.carton_label_id = ?) = ANY (pallet_buildups.source_pallets)
      SQL
      !DB[query, pallet_buildup_id, carton_number].first.nil?
    end

    def find_pallet_by_carton_number(carton_label_id)
      query = <<~SQL
        SELECT pallet_sequences.pallet_number
        FROM pallet_sequences
        INNER JOIN cartons ON (cartons.pallet_sequence_id = pallet_sequences.id)
        WHERE cartons.carton_label_id = ?
      SQL
      DB[query, carton_label_id].select_map(:pallet_number).first
    end
  end
end
