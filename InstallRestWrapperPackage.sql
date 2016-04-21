-- Created By Akshay Kasukhela, Caelan Evans, Seth Milligan, modified by Roy Falik and Michael Kloc
-- For Dr. Philip Cannata


drop package rwp;
drop type returnTableType;
drop type returnObjectType;



-- Defines the format of each row/entry --
CREATE OR REPLACE TYPE returnObjectType 
AS OBJECT
(
  R_ID          INT,
  DISPLAY_VAL   VARCHAR(255),
  RETURN_VAL    VARCHAR(255)
)
/


-- Creates a type which is a table of the type above, i.e this table will contain entries in the format defined above -- 
CREATE OR REPLACE TYPE returnTableType
   AS TABLE OF returnObjectType
/



-- Create our package which will contain releavnt functions/ types,etc... -- 
CREATE OR REPLACE PACKAGE rwp
AS
    TYPE stringCollectionType IS TABLE OF VARCHAR(255) INDEX BY PLS_INTEGER;    
    FUNCTION doLOV(table_name VARCHAR2, display_value_column VARCHAR2, return_value_column VARCHAR2, where_expression  VARCHAR2  DEFAULT 'WHERE TRUE')  RETURN returnTableType PIPELINED;
END;
/



-- Helper function which takes in a string as input, and returns a collection of strings, where each entry is a column mentioned in the input string --
CREATE OR REPLACE FUNCTION parseExpressionForColumns(expr VARCHAR2) RETURN rwp.stringCollectionType IS

rmatch varchar(255);
match_count PLS_INTEGER;
col_name varchar(255);
column_names rwp.stringCollectionType;       

BEGIN
    match_count := REGEXP_COUNT (expr, '\[([^\[])+\]');               -- Use regex to find number of potential columns in the expression
    column_names(1) := (match_count+1);                               -- Store the size as the first entry of the collection

    for i in 2 .. (match_count+1)
    LOOP
        rmatch := REGEXP_SUBSTR(expr,'\[([^\[])+\]', 1, (i-1));       -- Extract the matched expression / [c:column_name]
        rmatch := SUBSTR(rmatch, 2, length(rmatch)-2);                -- Remove the prefexing [c: and trailing ]
        column_names(i) := rmatch;                                    -- Insert the column name into the collection
    END LOOP;

    RETURN column_names;
   
END;
/




-- Define our piplined function, which uses the APEX REST API to request data from the cornot server --> parse it --> pipe it into our return table --> return the table when done. 
CREATE OR REPLACE PACKAGE BODY rwp AS
FUNCTION doLOV(table_name VARCHAR2, display_value_column VARCHAR2, return_value_column VARCHAR2, where_expression VARCHAR2 DEFAULT 'WHERE TRUE' ) RETURN returnTableType PIPELINED IS

request_result clob;
json_values                   apex_json.t_values;
row_count                     PLS_INTEGER;
d_val                         varchar(255);
r_val                         varchar(255);
expr_cpy                      varchar(255);
column_names_in_expression    stringCollectionType;  
num_cols_in_expression        PLS_INTEGER;
data                          stringCollectionType;
myexp                         varchar(255);
ret_val_column                varchar(255);
rmatch                        varchar(255);
where_expr                    varchar(255);
match_count                   varchar(255);

BEGIN

    --VVVVVV CHANGE THIS INFORMATION TO MATCH YOUR GROUP'S INFO VVVVVVV
    
    apex_web_service.g_request_headers(1).name := 'DB';
    apex_web_service.g_request_headers(1).value := 'OracleNoSQL';

    apex_web_service.g_request_headers(2).name := 'USER';
    apex_web_service.g_request_headers(2).value := 'WDBF2';

    apex_web_service.g_request_headers(3).name := 'PASS';
    apex_web_service.g_request_headers(3).value := 'localhost:8041';

    apex_web_service.g_request_headers(4).name := 'MODE';
    apex_web_service.g_request_headers(4).value := 'native_mode';

    apex_web_service.g_request_headers(5).name := 'MODEL';
    apex_web_service.g_request_headers(5).value := 'F2';

    apex_web_service.g_request_headers(6).name := 'returnDimensions';
    apex_web_service.g_request_headers(6).value := 'False';

    apex_web_service.g_request_headers(7).name := 'returnFor';
    apex_web_service.g_request_headers(7).value := 'SIM_JSON';
    
    --^^^^^^ CHANGE THIS INFORMATION TO MATCH YOUR GROUP'S INFO ^^^^^^
    
    
    -- Extract the RETURN_VALUE Column name for the input expression
    ret_val_column := REGEXP_SUBSTR(return_value_column, '\[([^\[])+\]', 1, 1); 
    ret_val_column := SUBSTR(ret_val_column, 2, length(ret_val_column)-2);  
    
    
    -- Procedure to replace all [c:colum_name] expressions in the where clause, with their actual column name, i.e WHERE [c:first_name] ---> WHERE first_name
    where_expr := where_expression;
    match_count := REGEXP_COUNT (where_expr, '\[([^\[])+\]'); 
    
    
    for i in 1 .. (match_count)
    LOOP
         rmatch := REGEXP_SUBSTR(where_expr, '\[([^\[])+\]', 1, 1);
         rmatch := SUBSTR(rmatch, 2, length(rmatch)-2); 
         where_expr := REGEXP_REPLACE(where_expr, '\[([^\[])+\]', rmatch,1,1);
    END LOOP;
    
    
    -- The request we will send to the rest server --
    myexp := '''from '|| table_name ||' retrieve * ' || where_expr || ';''';
    
    
    -- Fire the reqeuest using APEX's REST API --
    request_result := apex_web_service.make_rest_request(
      p_url => 'aevum.cs.utexas.edu:8040/rest/native',  -- CHANGE THIS
      p_http_method => 'GET',
      p_parm_name   => APEX_UTIL.string_to_table('query'),
      p_parm_value  => APEX_UTIL.string_to_table(myexp)  
    );

    -- Parse the JSON result into a CLOB -- 
    apex_json.parse(
      p_values => json_values,
      p_source => request_result,
      p_strict => false 
    );
    
    -- Get how many rows were returned -- 
    row_count := apex_json.get_count(
      p_path   => ret_val_column,  
      p_values => json_values
    );
    
    
    -- Get the columns mentioned in the display value expression --
    column_names_in_expression := parseExpressionForColumns(display_value_column);
    num_cols_in_expression := column_names_in_expression(1);
    
    
    -- Begin parsing data for each row --
    FOR i in 1 .. row_count
    LOOP
        -- Collect all the data requested in the display value parameter       
        FOR j in 2  .. num_cols_in_expression
        LOOP                                                        
           data((j-1)) := apex_json.get_varchar2(
             p_path   => ''||column_names_in_expression(j) || '[%d]',                
             p0       => (i),
             p_values => json_values
          );
        END LOOP;
        
        expr_cpy := display_value_column;
        
        -- format the display value data for this row as specified by the expression
        FOR k in 1 .. (num_cols_in_expression-1)
        LOOP
             -- we use regex to match our data into the [column_name]s in the expression, hence formatting our data as the user specified
             expr_cpy := REGEXP_REPLACE(expr_cpy, '\[([^\[])+\]', data(k),1,1); 
             
        END LOOP;
        
       
      d_val := expr_cpy;
      
      -- Get the return value data for this row 
      r_val := apex_json.get_varchar2(
         p_path   => ''|| ret_val_column || '[%d]',
         p0       => i,
         p_values => json_values
      );

       -- Pipe the row
      PIPE ROW (returnObjectType(i,d_val,r_val));
    END LOOP;
    RETURN;
    END;
END;
/
