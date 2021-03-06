# frozen_string_literal: true

module QualityApp
  class OrchardTestRepo < BaseRepo # rubocop:disable Metrics/ClassLength
    build_for_select :orchard_test_types,
                     label: :test_type_code,
                     value: :id,
                     order_by: :test_type_code
    build_inactive_select :orchard_test_types,
                          label: :test_type_code,
                          value: :id,
                          order_by: :test_type_code

    crud_calls_for :orchard_test_types, name: :orchard_test_type, wrapper: OrchardTestType
    crud_calls_for :orchard_test_results, name: :orchard_test_result, wrapper: OrchardTestResult

    def for_select_orchard_test_results(orchard_test_type_id)
      query = <<~SQL
        SELECT
            concat(pucs.puc_code, ' - ',orchards.orchard_code, ' - ',cultivars.cultivar_code) as code,
            orchard_test_results.id
        FROM orchard_test_results
        JOIN pucs ON pucs.id = orchard_test_results.puc_id
        JOIN orchards ON orchards.id = orchard_test_results.orchard_id
        JOIN cultivars ON cultivars.id = orchard_test_results.cultivar_id
        WHERE orchard_test_type_id = #{orchard_test_type_id}
        ORDER BY puc_code, orchard_code, cultivar_code
      SQL
      DB[query].select_map(%i[code id])
    end

    def for_select_orchard_test_api_attributes(api_name)
      DB[:orchard_test_api_attributes].where(api_name: api_name).select_map(%i[description api_attribute])
    end

    def find_orchard_test_type_flat(id)
      hash = find_hash(:orchard_test_types, id)
      query = <<~SQL
        SELECT
            CASE
                WHEN ott.applies_to_all_cultivars THEN (SELECT array_agg(c.id) AS array_agg FROM cultivars c)
                ELSE ott.applicable_cultivar_ids
            END AS applicable_cultivar_ids,
            CASE
                WHEN ott.applies_to_all_cultivars THEN (SELECT string_agg(c.cultivar_name, ', '::text) AS string_agg FROM cultivars c)
                ELSE (SELECT string_agg(c.cultivar_code, ', '::text) AS string_agg FROM cultivars c WHERE c.id = ANY (ott.applicable_cultivar_ids))
            END AS applicable_cultivars,
            CASE
                WHEN ott.applies_to_all_markets THEN (SELECT array_agg(tmg.id) AS array_agg FROM target_market_groups tmg)
                ELSE ott.applicable_tm_group_ids
            END AS applicable_tm_group_ids,
            CASE
                WHEN ott.applies_to_all_markets THEN (SELECT string_agg(tmg.target_market_group_name, ', '::text) AS string_agg FROM target_market_groups tmg)
                ELSE (SELECT string_agg(tmg.target_market_group_name, ', '::text) AS string_agg FROM target_market_groups tmg WHERE tmg.id = ANY (ott.applicable_tm_group_ids))
            END AS applicable_tm_groups,
            string_agg(DISTINCT commodity_groups.code, ', ') AS applicable_commodity_groups
        FROM orchard_test_types ott
        LEFT JOIN commodity_groups ON commodity_groups.id = ANY (ott.applicable_commodity_group_ids)
        WHERE ott.id = #{id}
        GROUP BY ott.id
      SQL
      OrchardTestTypeFlat.new(hash.merge(DB[query].first))
    end

    def find_orchard_test_result_flat(id)
      query = <<~SQL
        SELECT
            orchard_test_results.*,
            orchard_test_types.test_type_code AS orchard_test_type_code,
            orchard_test_types.api_name AS api_name,
            orchards.orchard_code,
            pucs.puc_code,
            cultivars.cultivar_name AS cultivar_code
        FROM orchard_test_results
        JOIN orchard_test_types ON orchard_test_types.id = orchard_test_results.orchard_test_type_id
        LEFT JOIN cultivars ON cultivars.id = orchard_test_results.cultivar_id
        LEFT JOIN orchards ON orchards.id = orchard_test_results.orchard_id
        LEFT JOIN pucs ON pucs.id = orchard_test_results.puc_id
        WHERE orchard_test_results.id = #{id}

      SQL
      hash = DB[query].first
      return nil if hash.nil?

      hash[:api_result] = nil if hash[:api_result].nil_or_empty?
      OrchardTestResultFlat.new(hash)
    end

    def failed_otmc_tests(orchard_id:, cultivar_id:, tm_group_id:)
      failed_test_types = []
      args = { orchard_id: orchard_id,
               cultivar_id: cultivar_id,
               passed: false,
               classification: false }
      test_type_ids = select_values(:orchard_test_results, :orchard_test_type_id, args)
      test_type_ids.each do |test_type_id|
        test_type = get(:orchard_test_types, test_type_id, :test_type_code)
        applies_to_all_markets = get(:orchard_test_types, test_type_id, :applies_to_all_markets)
        if applies_to_all_markets
          failed_test_types << test_type
        else
          applicable_tm_group_ids = get(:orchard_test_types, test_type_id, :applicable_tm_group_ids)
          failed_test_types << test_type if applicable_tm_group_ids.include? tm_group_id
        end
      end
      failed_test_types
    end

    def create_orchard_test_type(params)
      DB[:orchard_test_types].insert(prepare_array_values_for_db(params))
    end

    def update_orchard_test_type(id, params)
      attrs = params.to_h
      attrs[:applicable_tm_group_ids] = nil if attrs[:applies_to_all_markets]

      if attrs[:applies_to_all_cultivars]
        attrs[:applicable_cultivar_ids] = nil
        attrs[:applicable_commodity_group_ids] = nil
      end

      DB[:orchard_test_types].where(id: id).update(prepare_array_values_for_db(attrs))
    end

    def update_orchard_test_result(id, params)
      attrs = params.to_h
      attrs.delete(:api_response) if attrs[:api_response].nil_or_empty?
      attrs[:api_response] = hash_for_jsonb_col(attrs[:api_response]) if attrs.key?(:api_response)

      DB[:orchard_test_results].where(id: id).update(attrs)
    end

    def puc_orchard_cultivar(mode)
      id_arrays = if mode == :orchards
                    select_values(:orchards, %i[puc_id id cultivar_ids]).uniq
                  else
                    select_values(:pallet_sequences, %i[puc_id orchard_id cultivar_id]).uniq
                  end

      hash = {}
      id_arrays.each do |puc_id, orchard_id, cultivar_ids|
        puc = get(:pucs, puc_id, :puc_code)
        orchard = get(:orchards, orchard_id, :orchard_code).upcase
        Array(cultivar_ids).each do |cultivar_id|
          cultivar = get(:cultivars, cultivar_id, :cultivar_code)
          hash["PUC #{puc} - Orchard #{orchard}"] = "Cultivar #{cultivar}   "
        end
      end
      Hash[hash.sort]
    end
  end
end
