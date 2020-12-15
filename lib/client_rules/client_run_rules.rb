# frozen_string_literal: true

module Crossbeams
  class ClientRunRules
    include Crossbeams::AutoDocumentation

    attr_reader :settings

    CLIENT_SETTINGS = {
      hb: { run_allocations: false },
      hl: { run_allocations: true },
      um: { run_allocations: true },
      ud: { run_allocations: true },
      sr: { run_allocations: true },
      sr2: { run_allocations: true }
    }.freeze

    def initialize(client_code)
      @settings = CLIENT_SETTINGS.fetch(client_code.to_sym)
    end

    def no_run_allocations?(explain: false)
      return 'Does this client not do allocation of product setup to resource?' if explain

      !settings[:run_allocations]
    end

    # def without_desc
    #   'No desc...'
    # end
    #
    # def with_parm(xyz, explain: false)
    #   return 'This method gets a parameter - x or y' if explain
    #
    #   "return #{xyz}"
    # end
    #
    # def with_two_parm(xyz, abc, explain: false)
    #   return 'This method gets a parameter - X or A' if explain
    #
    #   "return #{xyz}, #{abc}"
    # end
  end
end
