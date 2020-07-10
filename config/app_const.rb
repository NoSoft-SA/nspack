# frozen_string_literal: true

# A class for defining global constants in a central place.
class AppConst # rubocop:disable Metrics/ClassLength
  def self.development?
    ENV['RACK_ENV'] == 'development'
  end

  # Any value that starts with y, Y, t or T is considered true.
  # All else is false.
  def self.check_true(val)
    val.match?(/^[TtYy]/)
  end

  # Take an environment variable and interpret it
  # as a boolean.
  def self.make_boolean(key, required: false)
    val = if required
            ENV.fetch(key)
          else
            ENV.fetch(key, 'f')
          end
    check_true(val)
  end

  # Helper to create hash of label sizes from a 2D array.
  def self.make_label_size_hash(array)
    Hash[array.map { |w, h| ["#{w}x#{h}", { 'width': w, 'height': h }] }].freeze
  end

  # Client-specific code
  CLIENT_CODE = ENV.fetch('CLIENT_CODE')
  IMPLEMENTATION_OWNER = ENV.fetch('IMPLEMENTATION_OWNER')
  SHOW_DB_NAME = ENV.fetch('DATABASE_URL').rpartition('@').last
  URL_BASE = ENV.fetch('URL_BASE')
  APP_CAPTION = ENV.fetch('APP_CAPTION')

  # labeling cached setup data path
  LABELING_CACHED_DATA_FILEPATH = File.expand_path('../tmp/run_cache', __dir__)

  # carton verification
  CARTON_EQUALS_PALLET = make_boolean('CARTON_EQUALS_PALLET')
  CARTON_VERIFICATION_REQUIRED = make_boolean('CARTON_VERIFICATION_REQUIRED')
  PROVIDE_PACK_TYPE_AT_VERIFICATION = make_boolean('PROVIDE_PACK_TYPE_AT_VERIFICATION')

  # carton palletizing
  USE_CARTON_PALLETIZING = make_boolean('USE_CARTON_PALLETIZING')
  DEFAULT_PALLET_LABEL_NAME = ENV['DEFAULT_PALLET_LABEL_NAME']
  AUTO_PRINT_PALLET_LABEL_ON_BAY = make_boolean('AUTO_PRINT_PALLET_LABEL_ON_BAY')

  # General
  DEFAULT_KEY = 'DEFAULT'

  # Production Runs
  ALLOW_CULTIVAR_GROUP_MIXING = make_boolean('ALLOW_CULTIVAR_GROUP_MIXING')

  # Deliveries
  DELIVERY_DEFAULT_FARM = ENV['DEFAULT_FARM']
  DELIVERY_CAPTURE_INNER_BINS = make_boolean('CAPTURE_INNER_BINS')
  DELIVERY_CAPTURE_BIN_WEIGHT_AT_FRUIT_RECEPTION = make_boolean('CAPTURE_BIN_WEIGHT_AT_FRUIT_RECEPTION')
  DELIVERY_DEFAULT_RMT_CONTAINER_TYPE = ENV.fetch('DEFAULT_RMT_CONTAINER_TYPE')
  DELIVERY_CAPTURE_CONTAINER_MATERIAL = make_boolean('CAPTURE_CONTAINER_MATERIAL')
  DELIVERY_CAPTURE_CONTAINER_MATERIAL_OWNER = make_boolean('CAPTURE_CONTAINER_MATERIAL_OWNER')
  DELIVERY_CAPTURE_DAMAGED_BINS = make_boolean('CAPTURE_DAMAGED_BINS')
  DELIVERY_USE_DELIVERY_DESTINATION = make_boolean('USE_DELIVERY_DESTINATION')
  DELIVERY_CAPTURE_EMPTY_BINS = make_boolean('CAPTURE_EMPTY_BINS')
  DELIVERY_CAPTURE_TRUCK_AT_FRUIT_RECEPTION = make_boolean('CAPTURE_TRUCK_AT_FRUIT_RECEPTION')
  USE_PERMANENT_RMT_BIN_BARCODES = make_boolean('USE_PERMANENT_RMT_BIN_BARCODES')
  ALLOW_AUTO_BIN_ASSET_NUMBER_ALLOCATION = make_boolean('ALLOW_AUTO_BIN_ASSET_NUMBER_ALLOCATION')
  EDIT_BIN_RECEIVED_DATE = make_boolean('EDIT_BIN_RECEIVED_DATE')
  DEFAULT_DELIVERY_LOCATION = ENV['DEFAULT_DELIVERY_LOCATION']
  BIN_SCANNING_BATCH_SIZE = ENV.fetch('BIN_SCANNING_BATCH_SIZE', 10)
  # Regular expression(s) to validate bin asset numbers when present (in case they are typed in incorrectly)
  # If more than one format is required, separate with commas (no spaces).
  BIN_ASSET_REGEX = ENV.fetch('BIN_ASSET_REGEX', '.+')

  # Resources
  PHC_LEVEL = ENV.fetch('PHC_LEVEL')
  GLN_OR_LINE_NUMBERS = ENV.fetch('GLN_OR_LINE_NUMBERS').split(',')

  # Constants for pallet movements:
  CALCULATE_PALLET_DECK_POSITIONS = make_boolean('CALCULATE_PALLET_DECK_POSITIONS')
  PALLET_MIX_RULES_SCOPE = ENV.fetch('PALLET_MIX_RULES_SCOPE', '').split(',')
  GLOBAL_PALLET_MIX = 'GLOBAL'

  # Constants for pallet statuses:
  PALLETIZED_NEW_PALLET = 'PALLETIZED_NEW_PALLET'
  RW_PALLET_SINGLE_EDIT = 'RW_PALLET_SINGLE_EDIT'
  RW_PALLET_BATCH_EDIT = 'RW_PALLET_BATCH_EDIT'
  PALLETIZED_SEQUENCE_ADDED = 'PALLETIZED_SEQUENCE_ADDED'
  PALLETIZED_SEQUENCE_REPLACED = 'PALLETIZED_SEQUENCE_REPLACED'
  PALLETIZED_SEQUENCE_UPDATED = 'PALLETIZED_SEQUENCE_UPDATED'
  PALLET_WEIGHED = 'PALLET WEIGHED'
  PALLET_MOVED = 'PALLET_MOVED'
  PALLET_SCRAPPED = 'PALLET SCRAPPED'
  PALLET_UNSCRAPPED = 'PALLET UNSCRAPPED'
  PALLETIZING = 'PALLETIZING'

  # Constants for cartons:
  CARTON_TRANSFER = 'CARTON TRANSFER'
  SEQ_REMOVED_BY_CTN_TRANSFER = 'SEQUENCE REMOVED BY CARTON TRANSFER'
  PALLET_COMPLETED_ON_BAY = 'PALLET COMPLETED ON BAY'
  PALLET_RETURNED_TO_BAY = 'PALLET RETURNED TO BAY'
  PALLET_SCRAPPED_BY_CTN_TRANSFER = 'PALLET SCRAPPED BY CARTON TRANSFER'

  # Constants for stock types:
  PALLET_STOCK_TYPE = 'PALLET'
  BIN_STOCK_TYPE = 'BIN'

  # Constants for pallet build statuses:
  PALLET_FULL_BUILD_STATUS = 'FULL'

  # Constants for rmt bin statuses:
  RMT_BIN_TIPPED_MANUALLY = 'TIPPED MANUALLY'
  RMT_BIN_WEIGHED_MANUALLY = 'WEIGHED MANUALLY'
  RMT_BIN_MOVED = 'BIN_MOVED'
  BULK_WEIGH_RMT_BINS = 'BULK WEIGH BINS MANUALLY'
  RMT_BIN_RECEIPT_DATE_OVERRIDE = 'RECEIPT DATE OVERRIDE'

  # Constants for PM Types
  PM_TYPE_FRUIT_STICKER = 'fruit_sticker'

  # Pallet verification
  REQUIRE_FRUIT_STICKER_AT_PALLET_VERIFICATION = make_boolean('REQUIRE_FRUIT_STICKER_AT_PALLET_VERIFICATION')
  COMBINE_CARTON_AND_PALLET_VERIFICATION = make_boolean('COMBINE_CARTON_AND_PALLET_VERIFICATION')
  CAPTURE_PALLET_WEIGHT_AT_VERIFICATION = make_boolean('CAPTURE_PALLET_WEIGHT_AT_VERIFICATION')
  PALLET_IS_IN_STOCK_WHEN_VERIFIED = make_boolean('PALLET_IS_IN_STOCK_WHEN_VERIFIED')
  PALLET_WEIGHT_REQUIRED_FOR_INSPECTION = make_boolean('PALLET_WEIGHT_REQUIRED_FOR_INSPECTION')
  PRINT_PALLET_LABEL_AT_PALLET_VERIFICATION = make_boolean('PRINT_PALLET_LABEL_AT_PALLET_VERIFICATION')

  # Constants for pallets exit_ref
  PALLET_EXIT_REF_SCRAPPED = 'SCRAPPED'
  PALLET_EXIT_REF_REMOVED = 'REMOVED'
  PALLET_EXIT_REF_REPACKED = 'REPACKED'

  # Constants for rmt_bins exit_ref
  BIN_EXIT_REF_UNSCRAPPED = 'BIN UNSCRAPPED'

  # Constants for dispatch:
  DEFAULT_CARGO_TEMP_ON_ARRIVAL = ENV['DEFAULT_CARGO_TEMP_ON_ARRIVAL']

  # Constants for roles:
  ROLE_IMPLEMENTATION_OWNER = 'IMPLEMENTATION_OWNER'
  ROLE_CUSTOMER = 'CUSTOMER'
  ROLE_SUPPLIER = 'SUPPLIER'
  ROLE_MARKETER = 'MARKETER'
  ROLE_FARM_OWNER = 'FARM_OWNER'
  ROLE_RMT_BIN_OWNER = 'RMT_BIN_OWNER'
  ROLE_RMT_CUSTOMER = 'RMT_CUSTOMER'
  ROLE_SHIPPING_LINE = 'SHIPPING_LINE'
  ROLE_SHIPPER = 'SHIPPER'
  ROLE_FINAL_RECEIVER = 'FINAL_RECEIVER'
  ROLE_EXPORTER = 'EXPORTER'
  ROLE_BILLING_CLIENT = 'BILLING_CLIENT'
  ROLE_CONSIGNEE = 'CONSIGNEE'
  ROLE_HAULIER = 'HAULIER'
  ROLE_INSPECTOR = 'INSPECTOR'
  ROLE_INSPECTION_BILLING = 'INSPECTION_BILLING'
  ROLE_TARGET_CUSTOMER = 'TARGET CUSTOMER'
  ROLE_TRANSPORTER = 'TRANSPORTER'
  ROLE_FARM_MANAGER = 'FARM_MANAGER'

  # Target Market Type: 'PACKED'
  PACKED_TM_GROUP = 'PACKED'

  # Product Setup default marketing organization
  DEFAULT_MARKETING_ORG = ENV['DEFAULT_MARKETING_ORG']

  # Defaults for Packaging
  DEFAULT_FG_PACKAGING_TYPE = ENV.fetch('DEFAULT_FG_PACKAGING_TYPE', 'CARTON') # Can be BIN or CARTON
  REQUIRE_PACKAGING_BOM = make_boolean('REQUIRE_PACKAGING_BOM')
  BASE_PACK_EQUALS_STD_PACK = make_boolean('BASE_PACK_EQUALS_STD_PACK')

  # Default packing method
  DEFAULT_PACKING_METHOD = ENV.fetch('DEFAULT_PACKING_METHOD', 'NORMAL')

  # First Intake
  DEFAULT_FIRST_INTAKE_LOCATION = ENV['DEFAULT_FIRST_INTAKE_LOCATION']
  CREATE_STOCK_AT_FIRST_INTAKE = make_boolean('CREATE_STOCK_AT_FIRST_INTAKE')

  # Default UOM TYPE
  UOM_TYPE = 'INVENTORY'

  # Constants for Reworks run types:
  RUN_TYPE_SINGLE_PALLET_EDIT = 'SINGLE PALLET EDIT'
  RUN_TYPE_BATCH_PALLET_EDIT = 'BATCH PALLET EDIT'
  RUN_TYPE_SCRAP_PALLET = 'SCRAP PALLET'
  RUN_TYPE_UNSCRAP_PALLET = 'UNSCRAP PALLET'
  RUN_TYPE_REPACK = 'REPACK PALLET'
  RUN_TYPE_BUILDUP = 'BUILDUP'
  RUN_TYPE_TIP_BINS = 'TIP BINS'
  RUN_TYPE_WEIGH_RMT_BINS = 'WEIGH RMT BINS'
  RUN_TYPE_RECALC_NETT_WEIGHT = 'RECALC NETT WEIGHT'
  RUN_TYPE_CHANGE_DELIVERIES_ORCHARDS = 'CHANGE DELIVERIES ORCHARDS'
  RUN_TYPE_SCRAP_BIN = 'SCRAP BIN'
  RUN_TYPE_UNSCRAP_BIN = 'UNSCRAP BIN'
  RUN_TYPE_BULK_PRODUCTION_RUN_UPDATE = 'BULK PRODUCTION RUN UPDATE'
  RUN_TYPE_BULK_BIN_RUN_UPDATE = 'BULK BIN RUN UPDATE'
  RUN_TYPE_DELIVERY_DELETE = 'DELIVERY DELETE'
  RUN_TYPE_BULK_WEIGH_BINS = 'BULK WEIGH BINS'
  RUN_TYPE_BULK_UPDATE_PALLET_DATES = 'BULK UPDATE PALLET DATES'

  # Constants for Reworks run actions:
  REWORKS_ACTION_SINGLE_EDIT = 'SINGLE EDIT'
  REWORKS_ACTION_BATCH_EDIT = 'BATCH EDIT'
  REWORKS_ACTION_CLONE = 'CLONE'
  REWORKS_ACTION_REMOVE = 'REMOVE'
  REWORKS_ACTION_EDIT_CARTON_QUANTITY = 'EDIT CARTON QUANTITY'
  REWORKS_ACTION_CHANGE_PRODUCTION_RUN = 'CHANGE PRODUCTION RUN'
  REWORKS_ACTION_CHANGE_FARM_DETAILS = 'CHANGE FARM DETAILS'
  REWORKS_ACTION_SET_GROSS_WEIGHT = 'SET GROSS WEIGHT'
  REWORKS_ACTION_UPDATE_PALLET_DETAILS = 'UPDATE PALLET DETAILS'
  REWORKS_ACTION_BULK_PALLET_RUN_UPDATE = 'BULK PALLET RUN UPDATE'
  REWORKS_ACTION_BULK_BIN_RUN_UPDATE = 'BULK BIN RUN UPDATE'
  REWORKS_ACTION_CHANGE_DELIVERIES_ORCHARDS = 'CHANGE DELIVERIES ORCHARDS'

  REWORKS_REPACK_PALLET_STATUS = 'REPACK SCRAP'
  REWORKS_REPACK_PALLET_NEW_STATUS = 'REPACKED'
  REWORKS_REPACK_SCRAP_REASON = 'REPACKED'

  REWORKS_MOVE_BIN_BUSINESS_PROCESS = 'REWORKS_MOVE_BIN'
  BIN_TIP_MOVE_BIN_BUSINESS_PROCESS = 'BIN_TIP_MOVE_BIN'
  REWORKS_MOVE_PALLET_BUSINESS_PROCESS = 'MOVE_PALLET'
  REWORKS_BULK_UPDATE_PALLET_DATES = 'REWORKS BULK UPDATE PALLET DATES'

  # Routes that do not require login:
  BYPASS_LOGIN_ROUTES = [
    '/masterfiles/config/label_templates/published',
    '/messcada/.*'
  ].freeze

  # Menu
  FUNCTIONAL_AREA_RMD = 'RMD'

  # Logging
  FIELDS_TO_EXCLUDE_FROM_DIFF = %w[label_json png_image].freeze

  # MesServer
  LABEL_SERVER_URI = ENV.fetch('LABEL_SERVER_URI')
  POST_FORM_BOUNDARY = 'AaB03x'

  # Labels
  SHARED_CONFIG_HOST_PORT = ENV.fetch('SHARED_CONFIG_HOST_PORT')
  LABEL_VARIABLE_SETS = ENV.fetch('LABEL_VARIABLE_SETS').strip.split(',')
  LABEL_PUBLISH_NOTIFY_URLS = ENV.fetch('LABEL_PUBLISH_NOTIFY_URLS', '').split(',')
  BATCH_PRINT_MAX_LABELS = ENV.fetch('BATCH_PRINT_MAX_LABELS', 20).to_i
  PREVIEW_PRINTER_TYPE = ENV.fetch('PREVIEW_PRINTER_TYPE', 'zebra')

  # Label sizes. The arrays contain width then height.
  DEFAULT_LABEL_DIMENSION = ENV.fetch('DEFAULT_LABEL_DIMENSION', '84x64')
  LABEL_SIZES = if ENV['LABEL_SIZES']
                  AppConst.make_label_size_hash(ENV['LABEL_SIZES'].split(';').map { |s| s.split(',') })
                else
                  AppConst.make_label_size_hash(
                    [
                      [84,   64], [84,  100], [97,   78], [78,   97], [77,  130], [100,  70],
                      [100,  84], [100, 100], [105, 250], [130, 100], [145,  50], [100, 150]
                    ]
                  )
                end

  # Label names for barcode printing:
  LABEL_LOCATION_BARCODE = ENV.fetch('LABEL_LOCATION_BARCODE', 'NSPACK_LOCATION')
  LABEL_BIN_BARCODE = ENV.fetch('LABEL_BIN_BARCODE', 'MAIN_BIN')
  LABEL_CARTON_VERIFICATION = ENV.fetch('LABEL_CARTON_VERIFICATION', 'BIN_VERIFICATION')

  # Printers
  PRINTER_USE_INDUSTRIAL = 'INDUSTRIAL'
  PRINTER_USE_OFFICE = 'OFFICE'

  PRINT_APP_LOCATION = 'Location'
  PRINT_APP_BIN = 'Bin'
  PRINT_APP_CARTON = 'Carton'
  PRINT_APP_PALLET = 'Pallet'

  PRINTER_APPLICATIONS = [
    PRINT_APP_LOCATION,
    PRINT_APP_BIN,
    PRINT_APP_CARTON,
    PRINT_APP_PALLET
  ].freeze

  # These will need to be configured per installation...
  BARCODE_PRINT_RULES = {
    location: { format: 'LC%d', fields: [:id] },
    # sku: { format: 'SK%d', fields: [:sku_number] },
    # delivery: { format: 'DN%d', fields: [:delivery_number] },
    bin: { format: 'BN%d', fields: [:id] }
  }.freeze

  BARCODE_SCAN_RULES = [
    { regex: '^LC(\\d+)$', type: 'location', field: 'id' },
    # { regex: '^(\\D\\D\\D)$', type: 'location', field: 'location_short_code' },
    # { regex: '^(\\D\\D\\D)$', type: 'dummy', field: 'code' },
    # { regex: '^SK(\\d+)', type: 'sku', field: 'sku_number' },
    { regex: '^DN(\\d+)', type: 'delivery', field: 'delivery_number' },
    { regex: '^BN(\\d+)', type: 'bin', field: 'id' },
    { regex: '^(\\d+)', type: 'pallet_number', field: 'pallet_number' },
    { regex: '^(\\d+)', type: 'carton_label_id', field: 'id' },
    # { regex: '^SK(\\d+)', type: 'bin_asset', field: 'bin_asset_number' }, # asset no should change to string and this should not require SK.
    { regex: '^([A-Z0-9]+)', type: 'bin_asset', field: 'bin_asset_number' }, # asset no should change to string and this should not require SK.
    { regex: '^(\\d+)', type: 'load', field: 'id' },
    { regex: '^(\\d+)', type: 'vehicle_job', field: 'id' }
  ].freeze

  # Per scan type, per field, set attributes for displaying a lookup value below a scan field.
  # The key matches a key in BARCODE_PRINT_RULES. (e.g. :location)
  # The hash for that key is keyed by the value of the BARCODE_SCAN_RULES :field. (e.g. :id)
  # The rules for that field are: the table to read, the field to match the scanned value and the field to display in the form.
  # If a join is required, specify join: table_name and on: Hash of field on source table: field on target table.
  BARCODE_LOOKUP_RULES = {
    location: {
      id: { table: :locations, field: :id, show_field: :location_long_code },
      location_short_code: { table: :locations, field: :location_short_code, show_field: :location_long_code }
    },
    sku: {
      sku_number: { table: :mr_skus,
                    field: :sku_number,
                    show_field: :product_variant_code,
                    join: :material_resource_product_variants,
                    on: { id: :mr_product_variant_id } }
    }
  }.freeze

  # Que
  QUEUE_NAME = ENV.fetch('QUEUE_NAME', 'default')

  # Mail
  ERROR_MAIL_RECIPIENTS = ENV.fetch('ERROR_MAIL_RECIPIENTS')
  ERROR_MAIL_PREFIX = ENV.fetch('ERROR_MAIL_PREFIX')
  SYSTEM_MAIL_SENDER = ENV.fetch('SYSTEM_MAIL_SENDER')
  EMAIL_REQUIRES_REPLY_TO = make_boolean('EMAIL_REQUIRES_REPLY_TO')
  EMAIL_GROUP_LABEL_APPROVERS = 'label_approvers'
  EMAIL_GROUP_LABEL_PUBLISHERS = 'label_publishers'
  EMAIL_GROUP_EDI_NOTIFIERS = 'edi_notifiers'
  USER_EMAIL_GROUPS = [EMAIL_GROUP_LABEL_APPROVERS, EMAIL_GROUP_LABEL_PUBLISHERS, EMAIL_GROUP_EDI_NOTIFIERS].freeze

  # Business Processes
  # PROCESS_DELIVERIES = 'DELIVERIES'
  # PROCESS_VEHICLE_JOBS = 'VEHICLE JOBS'
  # PROCESS_BULK_STOCK_ADJUSTMENTS = 'BULK STOCK ADJUSTMENTS'
  PROCESS_ADHOC_TRANSACTIONS = 'ADHOC_TRANSACTIONS'
  PROCESS_RECEIVE_EMPTY_BINS = 'RECEIVE_EMPTY_BINS'
  PROCESS_ISSUE_EMPTY_BINS = 'ISSUE_EMPTY_BINS'

  # Storage Types
  STORAGE_TYPE_PALLETS = 'PALLETS'

  # Locations: Location Types
  LOCATION_TYPES_WAREHOUSE = 'WAREHOUSE'
  LOCATION_TYPES_RECEIVING_BAY = 'RECEIVING BAY'
  LOCATION_TYPES_COLD_BAY_DECK = ENV.fetch('LOCATION_TYPES_COLD_BAY_DECK', 'DECK')
  LOCATION_TYPES_EMPTY_BIN = 'EMPTY_BIN'
  INSTALL_LOCATION = ENV.fetch('INSTALL_LOCATION')
  raise "Install location #{INSTALL_LOCATION} cannot be more than 7 characters in length" if INSTALL_LOCATION.length > 7

  # Loads:
  DEFAULT_EXPORTER = ENV['DEFAULT_EXPORTER']
  DEFAULT_INSPECTION_BILLING = ENV['DEFAULT_INSPECTION_BILLING']
  DEFAULT_DEPOT = ENV['DEFAULT_DEPOT']
  IN_TRANSIT_LOCATION = 'IN_TRANSIT_EX_PACKHSE'
  SCRAP_LOCATION = 'SCRAP_PACKHSE'
  UNSCRAP_LOCATION = 'UNSCRAP_PACKHSE'
  VGM_REQUIRED = make_boolean('VGM_REQUIRED')
  MAX_PALLETS_ON_LOAD = ENV['MAX_PALLETS_ON_LOAD'] || 50
  TEMP_TAIL_REQUIRED_TO_SHIP = make_boolean('TEMP_TAIL_REQUIRED_TO_SHIP')
  # Constants for port types:
  PORT_TYPE_POL = 'POL'
  PORT_TYPE_POD = 'POD'

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
  # * mark_code
  # * marketing_variety_code
  # * org_code
  # * product_chars
  # * size_count_value
  # * size_reference
  # * size_ref_or_count
  # * standard_pack_code
  # * target_market_group_name
  CLM_BUTTON_CAPTION_FORMAT = ENV['CLM_BUTTON_CAPTION_FORMAT']

  # Does this installation require login when printing a label from a robot?
  INCENTIVISED_LABELING = make_boolean('INCENTIVISED_LABELING')

  # pi Robots can display 6 lines of text, while T2n robots can only display 4.
  # If all robots on site are homogenous, set the value here.
  # Else it will be looked up from the module name.
  ROBOT_DISPLAY_LINES = ENV.fetch('ROBOT_DISPLAY_LINES', 0).to_i
  ROBOT_MSG_SEP = '###'

  # ERP_PURCHASE_INVOICE_URI = ENV.fetch('ERP_PURCHASE_INVOICE_URI', 'default')

  BIG_ZERO = BigDecimal('0')
  # The maximum size of an integer in PostgreSQL
  MAX_DB_INT = 2_147_483_647

  # ISO 2-character country codes
  ISO_COUNTRY_CODES = %w[
    AF AL DZ AS AD AO AI AQ AG AR AM AW AU AT AZ BS BH BD BB BY BE BZ BJ
    BM BT BO BQ BA BW BV BR IO BN BG BF BI CV KH CM CA KY CF TD CL CN CX
    CC CO KM CD CG CK CR HR CU CW CY CZ CI DK DJ DM DO EC EG SV GQ ER EE
    SZ ET FK FO FJ FI FR GF PF TF GA GM GE DE GH GI GR GL GD GP GU GT GG
    GN GW GY HT HM VA HN HK HU IS IN ID IR IQ IE IM IL IT JM JP JE JO KZ
    KE KI KP KR KW KG LA LV LB LS LR LY LI LT LU MO MG MW MY MV ML MT MH
    MQ MR MU YT MX FM MD MC MN ME MS MA MZ MM NA NR NP NL NC NZ NI NE NG
    NU NF MP NO OM PK PW PS PA PG PY PE PH PN PL PT PR QA MK RO RU RW RE
    BL SH KN LC MF PM VC WS SM ST SA SN RS SC SL SG SX SK SI SB SO ZA GS
    SS ES LK SD SR SJ SE CH SY TW TJ TZ TH TL TG TK TO TT TN TR TM TC TV
    UG UA AE GB UM US UY UZ VU VE VN VG VI WF EH YE ZM ZW AX
  ].freeze

  # Addendum: place of issue for export certificate
  ADDENDUM_PLACE_OF_ISSUE = ENV.fetch('ADDENDUM_PLACE_OF_ISSUE', 'CPT')
  raise Crossbeams::FrameworkError, "#{ADDENDUM_PLACE_OF_ISSUE} is not a valid code" unless ADDENDUM_PLACE_OF_ISSUE.match?(/cpt|dbn|plz|mpm|oth/i)

  # Inspection - Signee caption
  GOVT_INSPECTION_SIGNEE_CAPTION = ENV.fetch('GOVT_INSPECTION_SIGNEE_CAPTION', 'Packhouse manager')

  # EDI Settings
  EDI_NETWORK_ADDRESS = ENV.fetch('EDI_NETWORK_ADDRESS', '999')
  EDI_RECEIVE_DIR = ENV['EDI_RECEIVE_DIR']
  EDI_FLOW_PS = 'PS'
  EDI_FLOW_PO = 'PO'
  EDI_FLOW_UISTK = 'UISTK'
  EDI_AUTO_CREATE_MF = make_boolean('EDI_AUTO_CREATE_MF')
  PS_APPLY_SUBSTITUTES = make_boolean('PS_APPLY_SUBSTITUTES')
  DEPOT_DESTINATION_TYPE = 'DEPOT'
  PARTY_ROLE_DESTINATION_TYPE = 'PARTY_ROLE'
  DESTINATION_TYPES = [DEPOT_DESTINATION_TYPE, PARTY_ROLE_DESTINATION_TYPE].freeze
  EDI_OUT_RULES_TEMPLATE = {
    EDI_FLOW_PS => {
      depot: false,
      roles: [ROLE_MARKETER, ROLE_TARGET_CUSTOMER]
    },
    EDI_FLOW_PO => {
      depot: true,
      roles: [ROLE_CUSTOMER, ROLE_SHIPPER, ROLE_EXPORTER]
    },
    EDI_FLOW_UISTK => {
      depot: false,
      roles: [ROLE_MARKETER]
    }
  }.freeze

  MF_VARIANT_RULES = { Standard_Pack_Codes: { table_name: 'standard_pack_codes',
                                              column_name: 'standard_pack_code' },
                       PUCs: { table_name: 'pucs',
                               column_name: 'puc_code' },
                       Marketing_Varieties: { table_name: 'marketing_varieties',
                                              column_name: 'marketing_variety_code' },
                       Fruit_Size_References: { table_name: 'fruit_size_references',
                                                column_name: 'size_reference' },
                       Marks: { table_name: 'marks',
                                column_name: 'mark_code' },
                       Inventory_Codes: { table_name: 'inventory_codes',
                                          column_name: 'inventory_code' },
                       Grades: { table_name: 'grades',
                                 column_name: 'grade_code' },
                       Packed_TM_Group: { table_name: 'target_market_groups',
                                          column_name: 'target_market_group_name' },
                       Organizations: { table_name: 'organizations',
                                        column_name: 'medium_description' },
                       Depots: { table_name: 'depots',
                                 column_name: 'depot_code' },
                       Cities: { table_name: 'destination_cities',
                                 column_name: 'city_name' },
                       Ports: { table_name: 'ports',
                                column_name: 'port_code' },
                       Vessels: { table_name: 'vessels',
                                  column_name: 'vessel_code' } }.freeze

  SOLAS_VERIFICATION_METHOD = ENV['SOLAS_VERIFICATION_METHOD']
  SAMSA_ACCREDITATION = ENV['SAMSA_ACCREDITATION']

  RPT_INDUSTRY = ENV['RPT_INDUSTRY']
  JASPER_REPORTS_PATH = ENV['JASPER_REPORTS_PATH']
  USE_EXTENDED_PALLET_PICKLIST = make_boolean('USE_EXTENDED_PALLET_PICKLIST')

  # Titan: Govt Inspections
  TITAN_ENVIRONMENT = { UAT: 'uatapigateway', STAGING: 'stagingapigateway', PRODUCTION: 'apigateway' }[ENV.fetch('TITAN_ENVIRONMENT', 'UAT').to_sym]
  TITAN_API_USER_ID = ENV['TITAN_API_USER_ID']
  TITAN_API_SECRET = ENV['TITAN_API_SECRET']

  # QUALITY APP result types
  PASS_FAIL = 'Pass/Fail'
  CLASSIFICATION = 'Classification'
  QUALITY_RESULT_TYPE = [PASS_FAIL, CLASSIFICATION].freeze
  PHYT_CLEAN_STANDARD = 'PhytCleanStandardData'
  QUALITY_API_NAMES = [PHYT_CLEAN_STANDARD].freeze
  BYPASS_QUALITY_TEST_PRE_RUN_CHECK = make_boolean('BYPASS_QUALITY_TEST_PRE_RUN_CHECK')
  BYPASS_QUALITY_TEST_LOAD_CHECK = make_boolean('BYPASS_QUALITY_TEST_LOAD_CHECK')

  # PhytClean
  PHYT_CLEAN_ENVIRONMENT = 'https://www.phytclean.co.za'
  PHYT_CLEAN_API_USERNAME = ENV['PHYT_CLEAN_API_USERNAME']
  PHYT_CLEAN_API_PASSWORD = ENV['PHYT_CLEAN_API_PASSWORD']
  PHYT_CLEAN_SEASON_ID = ENV['PHYT_CLEAN_SEASON_ID']

  # eCert
  E_CERT_ENVIRONMENT = { QA: 'http://qa.', PRODUCTION: 'https://' }[ENV.fetch('E_CERT_ENVIRONMENT', 'QA').to_sym]
  E_CERT_API_CLIENT_ID = ENV['E_CERT_API_CLIENT_ID']
  E_CERT_API_CLIENT_SECRET = ENV['E_CERT_API_CLIENT_SECRET']
  E_CERT_BUSINESS_ID = ENV['E_CERT_BUSINESS_ID']
  E_CERT_BUSINESS_NAME = ENV['E_CERT_BUSINESS_NAME']
  E_CERT_INDUSTRY = ENV['E_CERT_INDUSTRY']

  ASSET_TRANSACTION_TYPES = { adhoc_move: 'ADHOC_MOVE',
                              adhoc_create: 'ADHOC_CREATE',
                              adhoc_destroy: 'ADHOC_DESTROY',
                              receive: 'RECEIVE_BINS',
                              issue: 'ISSUE_BINS',
                              bin_tip: 'BIN_TIP',
                              rebin: 'REBIN' }.freeze

  # Bin Control
  ONSITE_EMPTY_BIN_LOCATION = ENV['ONSITE_EMPTY_BIN_LOCATION']
  MAX_BINS_ON_LOAD = ENV['MAX_BINS_ON_LOAD'] || 50

  # Complete Pallet
  PLT_LABEL_QTY_TO_PRINT = 4
end
