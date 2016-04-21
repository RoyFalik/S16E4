SELECT DISPLAY_VAL as d,
RETURN_VAL as r
FROM TABLE(rwp.doLOV('person', '[first_name], [first_name]','[person_id]'))