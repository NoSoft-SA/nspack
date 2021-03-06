Sequel.migration do
  up do
    run <<~SQL
      CREATE VIEW public.vw_orchard_test_results_flat AS
        SELECT DISTINCT
          ott.id AS test_type_id,
          ott.test_type_code,
          ott.description,
          otr.classification,
          otr.passed,
          otr.api_result,
          ott.api_pass_result,
          ott.api_default_result,
          otr.freeze_result,
          otr.applicable_from,
          otr.applicable_to,
          ott.api_name,
          ott.api_attribute,
          array_agg(distinct otr.id order by otr.id) AS orchard_test_results_ids,
          array_agg(distinct otr.puc_id order by otr.puc_id) AS puc_ids,
          string_agg(distinct pucs.puc_code, ', ' order by pucs.puc_code) AS puc_codes,
          array_agg(distinct otr.orchard_id order by otr.orchard_id) AS orchard_ids,
          string_agg(distinct orchards.orchard_code, ', ' order by orchards.orchard_code) AS orchards_codes,
          array_agg(distinct otr.cultivar_id order by otr.cultivar_id) AS cultivar_ids,
          string_agg(distinct cultivars.cultivar_code, ', ' order by cultivars.cultivar_code) AS cultivar_codes,
      
          CASE
              WHEN ott.applies_to_all_markets THEN (SELECT array_agg(tmg.id) FROM target_market_groups tmg)
              ELSE ott.applicable_tm_group_ids
              END AS tm_group_ids,
          CASE
              WHEN ott.applies_to_all_markets THEN (SELECT string_agg(tmg.target_market_group_name , ', ') FROM target_market_groups tmg)
              ELSE (SELECT string_agg(tmg.target_market_group_name , ', ') FROM target_market_groups tmg WHERE tmg.id = ANY (ott.applicable_tm_group_ids))
              END AS tm_group_codes
      
        FROM orchard_test_types ott
        JOIN orchard_test_results otr ON ott.id = otr.orchard_test_type_id
        JOIN pucs ON otr.puc_id = pucs.id
        JOIN orchards ON otr.orchard_id = orchards.id
        JOIN cultivars ON otr.cultivar_id = cultivars.id
        
        GROUP BY
            ott.id,
            otr.passed,
            otr.api_result,
            otr.classification,
            otr.freeze_result,
            otr.applicable_from,
            otr.applicable_to;

      ALTER TABLE public.vw_orchard_test_results_flat
      OWNER TO postgres;
    SQL
  end

  down do
    run <<~SQL
      DROP VIEW public.vw_orchard_test_results_flat;
    SQL
  end
end

