# frozen_string_literal: true

module Crossbeams
  class ClientEdiRules < BaseClientRules
    include Crossbeams::AutoDocumentation

    CLIENT_SETTINGS = {
      hb: { install_location: 'HABATA',
            load_id_prefix: '',
            ps_apply_substitutes: false },
      hl: { install_location: 'HABATA',
            load_id_prefix: '',
            ps_apply_substitutes: false },
      kr: { install_location: 'KR',
            load_id_prefix: '',
            ps_apply_substitutes: false },
      um: { install_location: 'MATCOLD',
            load_id_prefix: '',
            ps_apply_substitutes: false },
      ud: { install_location: 'UNIFRUT',
            load_id_prefix: '',
            ps_apply_substitutes: false },
      sr: { install_location: 'SRKIRKW',
            load_id_prefix: '',
            ps_apply_substitutes: false },
      sr2: { install_location: 'SRADDO',
             load_id_prefix: 'A',
             ps_apply_substitutes: false }
    }.freeze

    def initialize(client_code)
      super
      @settings = CLIENT_SETTINGS.fetch(client_code.to_sym)
      validate_settings
    end

    def apply_substitutes_for_ps?(explain: false)
      return 'For PS EDI out, should the system place special values in these columns: original_account, saftbin1, saftbin2 and product_characteristic_code?' if explain

      setting(:ps_apply_substitutes)
    end

    private

    def validate_settings
      loc = setting(:install_location)
      raise "Install location #{loc} cannot be more than 7 characters in length" if loc.length > 7
    end
  end
end
