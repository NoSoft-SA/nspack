Sequel.migration do
  up do
    run <<~SQL
      CREATE OR REPLACE FUNCTION public.pallets_next_pallet_number()
        RETURNS trigger AS
      $BODY$
        DECLARE
          p_gln TEXT;
          p_seq_len INTEGER;
          p_next_val TEXT;
          p_seq_name TEXT;
          p_seq TEXT;
          p_pallet_base_number TEXT;
        BEGIN
          EXECUTE 'SELECT resource_properties ->> ''gln''
          FROM plant_resources
          WHERE id = $1'
          INTO p_gln
          USING NEW.plt_line_resource_id;

          IF (p_gln IS NULL) THEN
              RAISE EXCEPTION 'Cannot generate a pallet number. There is no GLN for packhouse id %, line id %.', NEW.plt_packhouse_resource_id, NEW.plt_line_resource_id;
          END IF;

          p_seq_len = 17 - length(p_gln); -- no of digits to pad to

          p_seq_name = 'gln_seq_for_' || p_gln;
          EXECUTE format('SELECT nextval(''%I'')::text AS seq'::text, p_seq_name) INTO p_next_val ;

          IF (length(p_next_val) > p_seq_len) THEN
            RAISE EXCEPTION 'Cannot generate a pallet number. The sequence % has overflowed. It needs to be reset or a new GLN number is required', p_seq_name;
          END IF;

          EXECUTE format('SELECT lpad(''%s'', %s, ''0'') AS seq'::text, p_next_val, p_seq_len) INTO p_seq;

          p_pallet_base_number = p_gln || p_seq;
          NEW.pallet_number = fn_sscc_number_with_check_digit(p_pallet_base_number);

          RETURN NEW;
        END
      $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      ALTER FUNCTION public.pallets_next_pallet_number()
        OWNER TO postgres;
    SQL
  end

  down do
    run <<~SQL
      CREATE OR REPLACE FUNCTION public.pallets_next_pallet_number()
        RETURNS trigger AS
      $BODY$
        DECLARE
          p_company_prefix TEXT;
          p_gln TEXT;
          p_seq_name TEXT;
          p_seq TEXT;
          p_pallet_base_number TEXT;
        BEGIN
          EXECUTE 'SELECT resource_properties ->> ''gln''
          FROM plant_resources
          WHERE id = $1'
          INTO p_gln
          USING NEW.plt_line_resource_id;

          IF (p_gln IS NULL) THEN
            EXECUTE 'SELECT resource_properties ->> ''gln''
            FROM plant_resources
            WHERE id = $1'
            INTO p_gln
            USING NEW.plt_packhouse_resource_id;
          END IF;

          IF (p_gln IS NULL) THEN
              RAISE EXCEPTION 'Cannot generate a pallet number. There is no GLN for packhouse id %, line id %.', NEW.plt_packhouse_resource_id, NEW.plt_line_resource_id;
          END IF;
          
          EXECUTE 'SELECT p.resource_properties ->> ''company_prefix''
          FROM plant_resources
          JOIN tree_plant_resources t ON t.descendant_plant_resource_id = plant_resources.id
          JOIN plant_resources p ON p.id = t.ancestor_plant_resource_id AND p.plant_resource_type_id = (SELECT id from plant_resource_types WHERE plant_resource_type_code = ''SITE'')
          WHERE plant_resources.id = $1' INTO p_company_prefix USING NEW.plt_line_resource_id;

          IF (p_company_prefix IS NULL) THEN
              RAISE EXCEPTION 'Cannot generate a pallet number. There is no COMPANY PREFIX for the SITE housing packhouse id %, line id %.', NEW.plt_packhouse_resource_id, NEW.plt_line_resource_id;
          END IF;

          p_seq_name = 'gln_seq_for_' || p_gln;
          EXECUTE format('SELECT to_char(nextval(''%I''), ''FM00009'') AS seq'::text, p_seq_name) INTO p_seq;

          p_pallet_base_number = p_company_prefix || p_gln || p_seq;
          NEW.pallet_number = fn_sscc_number_with_check_digit(p_pallet_base_number);

          RETURN NEW;
        END
      $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      ALTER FUNCTION public.pallets_next_pallet_number()
        OWNER TO postgres;
    SQL
  end
end
