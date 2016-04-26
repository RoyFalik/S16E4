set serveroutput on;


CREATE OR REPLACE PACKAGE stringHelper IS
  TYPE stringCollectionType IS TABLE OF VARCHAR(255) INDEX BY PLS_INTEGER; 
END stringHelper;
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
      col1     VARCHAR default NULL,
      col2     VARCHAR default NULL,
      col3     VARCHAR default NULL,
      col4     VARCHAR default NULL
    ) RETURN SELF AS result,
  MEMBER FUNCTION populate (vals stringHelper.stringCollectionType) RETURN SELF AS result
);
/

CREATE OR REPLACE TYPE BODY returnObjectType AS
     CONSTRUCTOR FUNCTION returnObjectType
     ( R_ID     number,
       col1     VARCHAR default NULL,
       col2     VARCHAR default NULL,
       col3     VARCHAR default NULL,
       col4     VARCHAR default NULL
     ) RETURN SELF AS result
     AS
     BEGIN
        SELF.R_ID := r_id;
        SELF.col1 := col1;
        SELF.col2 := col2;
        SELF.col3 := col3;
        SELF.col4 := col4;
        RETURN;
     END;
     MEMBER FUNCTION populate (vals stringHelper.stringCollectionType) RETURN SELF AS result IS
      BEGIN
        SELF.col1 := vals(1);
        SELF.col2 := vals(2);
        SELF.col3 := vals(3);
        SELF.col4 := vals(4);
        RETURN SELF;
      END populate;
END;
/

DECLARE
  colVals stringHelper.stringCollectionType;   
  r1 returnObjectType;
  type table_varchar is table of varchar2(10);
  var_table_varchar  table_varchar;
BEGIN
  for i in 1 .. 4 loop
    colVals(i) := 'shit';
  end loop;
  r1 := NEW returnObjectType(1);
END;
/