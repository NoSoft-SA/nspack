Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'View', functional_area: 'Finished Goods', program: 'Dispatch', url: '/finished_goods/dispatch/loads/last/view', group: 'Last Load', seq: 5
    add_program_function 'Edit', functional_area: 'Finished Goods', program: 'Dispatch', url: '/finished_goods/dispatch/loads/last/edit', group: 'Last Load', seq: 6
    add_program_function 'Allocate', functional_area: 'Finished Goods', program: 'Dispatch', url: '/finished_goods/dispatch/loads/last/allocate', group: 'Last Load', seq: 7
  end

  down do
    drop_program_function 'View', functional_area: 'Finished Goods', program: 'Dispatch'
    drop_program_function 'Edit', functional_area: 'Finished Goods', program: 'Dispatch'
    drop_program_function 'Allocate', functional_area: 'Finished Goods', program: 'Dispatch'
  end
end