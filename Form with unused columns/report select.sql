SELECT col1 as "First Name", col2 as "Last Name", col3 as "Home Address"
FROM TABLE(rwp.doLOV('person', '[first_name], [last_name], [home_address]','[person_id]'))