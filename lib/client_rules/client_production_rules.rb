# frozen_string_literal: true

module Crossbeams
  class ClientProductionRules < BaseClientRules # rubocop:disable Metrics/ClassLength
    include Crossbeams::AutoDocumentation

    CLIENT_SETTINGS = {
      hb: { run_allocations: true,
            pallet_label_seqs_sql: 'SELECT ps.production_run_id, o.orchard_code, c.cultivar_code, ps.nett_weight FROM pallet_sequences ps JOIN orchards o ON o.id = ps.orchard_id JOIN cultivars c ON c.id = ps.cultivar_id WHERE ps.pallet_id = ? ORDER BY ps.pallet_sequence_number',
            use_gtins: false,
            print_from_line_scanning: false,
            incentive_palletizing: true,
            clm_button_caption_format: '$:size_ref_or_count$ $:product_chars$ $:target_market_group_name$',
            provide_pack_type_at_verification: false,
            group_incentive_packer_roles: false,
            integrate_with_external_rmt_system: false,
            bin_tip_match_farm_on_group: false,
            default_marketing_org: 'HABATA',
            allow_cultivar_group_mix: true,
            use_packing_specifications: false,
            use_marketing_puc: false,
            carton_equals_pallet: { default: false, can_override: true },
            capture_product_setup_class: false,
            link_target_markets_to_target_customers: false,
            require_packaging_bom: false,
            capture_batch_number_for_pallets: true },
      hl: { run_allocations: true,
            pallet_label_seqs_sql: nil,
            use_gtins: false,
            print_from_line_scanning: false,
            incentive_palletizing: false,
            clm_button_caption_format: 'COUNT: $:actual_count_for_pack$',
            provide_pack_type_at_verification: true,
            group_incentive_packer_roles: false,
            integrate_with_external_rmt_system: false,
            bin_tip_match_farm_on_group: false,
            default_marketing_org: 'HABATA',
            allow_cultivar_group_mix: true,
            use_packing_specifications: false,
            use_marketing_puc: false,
            carton_equals_pallet: { default: false, can_override: true },
            capture_product_setup_class: false,
            link_target_markets_to_target_customers: false,
            require_packaging_bom: false,
            capture_batch_number_for_pallets: false },
      kr: { run_allocations: true,
            pallet_label_seqs_sql: 'SELECT p.puc_code, p.gap_code, ps.gtin_code, ps.carton_quantity FROM pallet_sequences ps JOIN pucs p ON p.id = ps.puc_id WHERE ps.pallet_id = ? ORDER BY ps.pallet_sequence_number',
            use_gtins: true,
            print_from_line_scanning: true,
            incentive_palletizing: false,
            clm_button_caption_format: nil,
            provide_pack_type_at_verification: false,
            group_incentive_packer_roles: true,
            integrate_with_external_rmt_system: true,
            bin_tip_match_farm_on_group: true,
            default_marketing_org: 'KR',
            allow_cultivar_group_mix: false,
            use_packing_specifications: true,
            use_marketing_puc: true,
            carton_equals_pallet: { default: false, can_override: false },
            capture_product_setup_class: true,
            link_target_markets_to_target_customers: true,
            require_packaging_bom: true,
            capture_batch_number_for_pallets: false },
      um: { run_allocations: true,
            pallet_label_seqs_sql: 'SELECT o.orchard_code, m.marketing_variety_code, s.size_reference, ps.carton_quantity FROM pallet_sequences ps JOIN orchards o ON o.id = ps.orchard_id JOIN marketing_varieties m ON m.id = ps.marketing_variety_id JOIN fruit_size_references s ON s.id = ps.fruit_size_reference_id WHERE ps.pallet_id = ? ORDER BY ps.pallet_sequence_number',
            use_gtins: false,
            print_from_line_scanning: false,
            incentive_palletizing: false,
            clm_button_caption_format: 'SIZE: $:size_reference$',
            provide_pack_type_at_verification: false,
            group_incentive_packer_roles: false,
            integrate_with_external_rmt_system: false,
            bin_tip_match_farm_on_group: false,
            default_marketing_org: 'UI',
            allow_cultivar_group_mix: false,
            use_packing_specifications: false,
            use_marketing_puc: false,
            carton_equals_pallet: { default: false, can_override: false },
            capture_product_setup_class: false,
            link_target_markets_to_target_customers: false,
            require_packaging_bom: false,
            capture_batch_number_for_pallets: false },
      ud: { run_allocations: true,
            pallet_label_seqs_sql: nil,
            use_gtins: false,
            print_from_line_scanning: false,
            incentive_palletizing: false,
            clm_button_caption_format: nil,
            provide_pack_type_at_verification: false,
            group_incentive_packer_roles: false,
            integrate_with_external_rmt_system: false,
            bin_tip_match_farm_on_group: false,
            default_marketing_org: 'UI',
            allow_cultivar_group_mix: true,
            use_packing_specifications: false,
            use_marketing_puc: false,
            carton_equals_pallet: { default: false, can_override: false },
            capture_product_setup_class: false,
            link_target_markets_to_target_customers: false,
            require_packaging_bom: false,
            capture_batch_number_for_pallets: false },
      sr: { run_allocations: true,
            pallet_label_seqs_sql: nil,
            use_gtins: false,
            print_from_line_scanning: false,
            incentive_palletizing: true,
            clm_button_caption_format: '$:size_ref_or_count$ $:product_chars$ $:target_market_group_name$',
            provide_pack_type_at_verification: false,
            group_incentive_packer_roles: false,
            integrate_with_external_rmt_system: false,
            bin_tip_match_farm_on_group: false,
            default_marketing_org: 'SY',
            allow_cultivar_group_mix: false,
            use_packing_specifications: false,
            use_marketing_puc: false,
            carton_equals_pallet: { default: false, can_override: false },
            capture_product_setup_class: false,
            link_target_markets_to_target_customers: false,
            require_packaging_bom: false,
            capture_batch_number_for_pallets: false },
      sr2: { run_allocations: true,
             pallet_label_seqs_sql: nil,
             use_gtins: false,
             print_from_line_scanning: false,
             incentive_palletizing: false,
             clm_button_caption_format: '$:size_reference$ $:product_chars$ $:target_market_group_name$',
             provide_pack_type_at_verification: false,
             group_incentive_packer_roles: false,
             integrate_with_external_rmt_system: false,
             bin_tip_match_farm_on_group: false,
             default_marketing_org: 'SY',
             allow_cultivar_group_mix: false,
             use_packing_specifications: false,
             use_marketing_puc: false,
             carton_equals_pallet: { default: false, can_override: true },
             capture_product_setup_class: false,
             link_target_markets_to_target_customers: false,
             require_packaging_bom: false,
             capture_batch_number_for_pallets: false }
    }.freeze
    # ALLOW_OVERFULL_REWORKS_PALLETIZING
    # BYPASS_QUALITY_TEST_LOAD_CHECK
    # BYPASS_QUALITY_TEST_PRE_RUN_CHECK
    # CAPTURE_PALLET_WEIGHT_AT_VERIFICATION
    # CARTON_EQUALS_PALLET
    # CARTON_VERIFICATION_REQUIRED
    # COMBINE_CARTON_AND_PALLET_VERIFICATION
    # DEFAULT_FG_PACKAGING_TYPE
    # DEFAULT_PACKING_METHOD
    # DEFAULT_PALLET_LABEL_NAME
    # NO_RUN_ALLOCATION
    # PALLET_IS_IN_STOCK_WHEN_VERIFIED
    # PALLET_MIX_RULES_SCOPE
    # PRINT_PALLET_LABEL_AT_PALLET_VERIFICATION
    # REQUIRE_EXTENDED_PACKAGING
    # REQUIRE_FRUIT_STICKER_AT_PALLET_VERIFICATION
    # REQUIRE_PACKAGING_BOM
    # ROBOT_DISPLAY_LINES
    # USE_CARTON_PALLETIZING

    PALLET_LBL_PSEQ_HEADS = {
      puc_code: 'PUC',
      gap_code: 'Gap code',
      gtin_code: 'GTIN',
      carton_quantity: 'Quantity',
      production_run_id: 'Run id',
      orchard_code: 'Orchard',
      cultivar_code: 'Cultivar',
      marketing_variety_code: 'Var',
      size_reference: 'Count'
    }.freeze

    def initialize(client_code)
      super
      @settings = CLIENT_SETTINGS.fetch(client_code.to_sym)
    end

    def no_run_allocations?(explain: false)
      return 'Does this client not do allocation of product setup to resource?' if explain

      !setting(:run_allocations)
    end

    def can_mix_cultivar_groups?(explain: false)
      return 'Can cultivar groups be mixed in a production run?' if explain

      setting(:allow_cultivar_group_mix)
    end

    def kromco_rmt_integration?(explain: false)
      return 'Is the client Kromco, and do they need to integrate with an external RMT system?' if explain

      setting(:integrate_with_external_rmt_system) && client_code == 'kr'
    end

    def bintip_allow_farms_of_same_group_to_match?(explain: false)
      return 'When tipping a bin against a run and the run farm is not the same as the bin farm, should the bin be allowed to tip if both farms belong to the same farm group?' if explain

      setting(:bin_tip_match_farm_on_group)
    end

    def group_incentive_has_packer_roles?(explain: false)
      return 'Do packers have different roles for participation in group incentives?' if explain

      setting(:group_incentive_packer_roles)
    end

    def use_gtins?(explain: false)
      return 'Use masterfile codes and/or variants to lookup a gtin_code to store on setups, cartons and sequences.' if explain

      setting(:use_gtins)
    end

    def button_caption_spec(explain: false)
      return 'Format for button captions of label-printing robots.' if explain

      # CLM_BUTTON_CAPTION_FORMAT
      #
      # This string provides a format for captions to display on buttons
      # of robots that print carton labels.
      # The string can contain any text and fruitspec tokens that are
      # delimited by $: and $. e.g. 'Count: $:actual_count_for_pack$'
      #
      # The possible fruitspec tokens are:
      # HBL: 'COUNT: $:actual_count_for_pack$'
      # UM : 'SIZE: $:size_reference$'
      # SR : '$:size_ref_or_count$ $:product_chars$ $:target_market_group_name$'
      # * actual_count_for_pack
      # * basic_pack_code
      # * commodity_code
      # * grade_code
      # * mark_code
      # * marketing_variety_code
      # * org_code
      # * product_chars
      # * size_count_value
      # * size_reference
      # * size_ref_or_count
      # * standard_pack_code
      # * target_market_group_name
      setting(:clm_button_caption_format)
    end

    def provide_pack_type_at_carton_verification?(explain: false)
      return 'Does a button have to be pressed at carton verification to assign the particular pack type?' if explain

      setting(:provide_pack_type_at_verification)
    end

    def run_provides_button_captions?(explain: false)
      return 'Should the run execution send captions to robots to refresh their buttons.' if explain

      setting(:clm_button_caption_format) || setting(:provide_pack_type_at_verification)
    end

    def sequences_label_variable_for_pallet(pallet_id, explain: false)
      return 'Prepare a table of sequence information for printing as a single label variable.' if explain

      query = setting(:pallet_label_seqs_sql)
      return [] unless query

      recs = DB[query, pallet_id].all
      UtilityFunctions.make_text_table(recs, heads: PALLET_LBL_PSEQ_HEADS, numbers: [:nett_weight], rjust: [:carton_quantity])
    end

    def use_packing_specifications?(explain: false)
      return 'Use packing specifications instead of product setup templates for extended packaging details.' if explain

      setting(:use_packing_specifications)
    end

    def use_marketing_puc?(explain: false)
      return "Lookup a marketing organization's puc and orchard values to store on cartons and sequences." if explain

      setting(:use_marketing_puc)
    end

    def carton_equals_pallet?(plant_resource_code: nil, explain: false)
      return "Does carton become a pallet. Setting: #{setting(:carton_equals_pallet).inspect}" if explain

      carton_equals_pallet = setting(:carton_equals_pallet)
      return carton_equals_pallet[:default] unless carton_equals_pallet[:can_override]
      return carton_equals_pallet[:default] if plant_resource_code.nil?

      robot_carton_equals_pallet = DB[:plant_resources]
                                   .where(plant_resource_code: plant_resource_code)
                                   .get(Sequel.lit("resource_properties ->> 'carton_equals_pallet'"))
      robot_carton_equals_pallet.nil_or_empty? ? carton_equals_pallet[:default] : robot_carton_equals_pallet == 't'
    end

    def capture_product_setup_class?(explain: false)
      return 'Show and capture rmt_class on product_setups and pallet_sequences forms.' if explain

      setting(:capture_product_setup_class)
    end

    def link_target_markets_to_target_customers?(explain: false)
      return 'Link target_markets to target_customers' if explain

      setting(:link_target_markets_to_target_customers)
    end

    def require_packaging_bom?(explain: false)
      return 'Show and capture packaging bom on product_setups and pallet_sequences forms.' if explain

      setting(:require_packaging_bom)
    end

    def capture_batch_number_for_pallets?(explain: false)
      return 'Capture batch number on pallets.' if explain

      setting(:capture_batch_number_for_pallets)
    end
  end
end
