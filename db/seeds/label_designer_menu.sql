INSERT INTO programs (program_name, program_sequence, functional_area_id)
VALUES ('Master Lists', 1, (SELECT id FROM functional_areas WHERE functional_area_name = 'Label Designer'));

INSERT INTO programs_webapps (program_id, webapp)
VALUES ((SELECT id FROM programs WHERE program_name = 'Master Lists' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Label Designer')), 'Nspack');

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Designs' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Label Designer')), 'List labels', '/list/labels/with_params?key=active', 1);
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Designs' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Label Designer')), 'New label', '/labels/labels/labels/new', 2);
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Designs' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Label Designer')), 'Archived labels', '/list/labels/with_params?key=inactive', 4);

INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence)
VALUES ((SELECT id FROM programs WHERE program_name = 'Master Lists' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Label Designer')), 'Label Types', '/list/master_lists/with_params?key=label_type', 1);


INSERT INTO programs_users (user_id, program_id, security_group_id)
VALUES ((SELECT id FROM users ORDER BY id LIMIT 1),
  (SELECT id FROM programs WHERE program_name = 'Designs' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Label Designer')),
  (SELECT id FROM security_groups g WHERE g.security_group_name = 'basic'));

INSERT INTO programs_users (user_id, program_id, security_group_id)
VALUES ((SELECT id FROM users ORDER BY id LIMIT 1),
  (SELECT id FROM programs WHERE program_name = 'Master Lists' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'Label Designer')),
  (SELECT id FROM security_groups g WHERE g.security_group_name = 'basic'));



-- PROGRAM FUNCTION Import label
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence,
                               group_name, restricted_user_access, show_in_iframe)
VALUES ((SELECT id FROM programs WHERE program_name = 'Designs'
          AND functional_area_id = (SELECT id FROM functional_areas
                                    WHERE functional_area_name = 'Label Designer')),
        'Import label',
        '/labels/labels/labels/import',
        4,
        NULL,
        true,
        false);

-- PROGRAM FUNCTION Archived labels
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence,
                               group_name, restricted_user_access, show_in_iframe)
VALUES ((SELECT id FROM programs WHERE program_name = 'Designs'
          AND functional_area_id = (SELECT id FROM functional_areas
                                    WHERE functional_area_name = 'Label Designer')),
        'Archived labels',
        '/list/labels/with_params?key=inactive',
        4,
        NULL,
        false,
        false);



-- PROGRAM: Publish
INSERT INTO programs (program_name, program_sequence, functional_area_id)
VALUES ('Publish', 3,
        (SELECT id FROM functional_areas WHERE functional_area_name = 'Label Designer'));

-- LINK program to webapp
INSERT INTO programs_webapps (program_id, webapp)
VALUES ((SELECT id FROM programs
                   WHERE program_name = 'Publish'
                     AND functional_area_id = (SELECT id
                                               FROM functional_areas
                                               WHERE functional_area_name = 'Label Designer')),
                                               'Nspack');


-- PROGRAM FUNCTION Select and publish
INSERT INTO program_functions (program_id, program_function_name, url, program_function_sequence,
                               group_name, restricted_user_access, show_in_iframe)
VALUES ((SELECT id FROM programs WHERE program_name = 'Publish'
          AND functional_area_id = (SELECT id FROM functional_areas
                                    WHERE functional_area_name = 'Label Designer')),
        'Select and publish',
        '/labels/publish/batch',
        1,
        NULL,
        false,
        false);
