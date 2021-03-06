Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    drop_program_function 'Cartons', functional_area: 'Production', program: 'Runs', match_group: 'List Objects'
    drop_program_function 'Cartons', functional_area: 'Production', program: 'Runs', match_group: 'List Objects'
  end

  down do
    add_program_function 'Cartons', functional_area: 'Production', program: 'Runs', url: '/list/cartons', seq: 3, group: 'List Objects'
    add_program_function 'Cartons', functional_area: 'Production', program: 'Runs', url: '/search/cartons', seq: 4, group: 'Search Objects'
  end
end
