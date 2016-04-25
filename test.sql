set serveroutput on;

CREATE OR REPLACE TYPE stringCollectionType IS TABLE OF VARCHAR(255) INDEX BY PLS_INTEGER; 
/

CREATE OR REPLACE TYPE returnObjectType AS OBJECT
(
  R_ID    number,
  col1    VARCHAR(255),
  col2    VARCHAR(255),
  col3    VARCHAR(255),
  col4    VARCHAR(255),
  CONSTRUCTOR FUNCTION returnObjectType
    ( R_ID     number,
       colVals  stringCollectionType
    ) RETURN SELF AS result
);
/

CREATE OR REPLACE TYPE BODY returnObjectType AS
     CONSTRUCTOR FUNCTION returnObjectType
     ( R_ID     number,
       colVals  stringCollectionType
     ) RETURN SELF AS result
     AS
     BEGIN
        SELF.R_ID := r_id;
        SELF.col1 := colVals(1);
        SELF.col2 := colVals(2);
        SELF.col3 := colVals(3);
        SELF.col4 := colVals(4);
        RETURN;
     END;
END;
/

DECLARE
  colVals stringCollectionType;   
  r1 returnObjectType;
  type table_varchar is table of varchar2(10);
  var_table_varchar  table_varchar;
BEGIN
  for i in 1 .. 4 loop
    colVals(i) := 'shit';
  end loop;
  r1 := NEW returnObjectType(1, colVals);
END;
/