Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'New', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/change_deliveries_orchard', group: 'Change Deliveries Orchards', seq: 17
    add_program_function 'List', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_run_types/change_deliveries_orchards', group: 'Change Deliveries Orchards', seq: 18
  end

  down do
    drop_program_function 'New', functional_area: 'Production', program: 'Reworks', match_group: 'Change Deliveries Orchards'
    drop_program_function 'List', functional_area: 'Production', program: 'Reworks', match_group: 'Change Deliveries Orchards'
  end
end
