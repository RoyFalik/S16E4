SELECT col1 as "First Name", col2 as "Last Name", col3 as "Last Name2"
FROM TABLE(rwp.doLOV('person', '[first_name], [last_name], [last_name]','[person_id]'))