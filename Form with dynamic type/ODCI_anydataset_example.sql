create or replace type NColPipe as object 
( 
  l_parm varchar2(10),   -- The parameter given to the table function
  rows_requested number, -- The parameter given to the table function
  ret_type anytype,      -- The return type of the table function
  rows_returned number,  -- The number of rows currently returned by the table function
  static function ODCITableDescribe( rtype out anytype, p_parm in varchar2, p_rows_req in number := 2 )
  return number, 
  static function ODCITablePrepare( sctx out NColPipe, ti in sys.ODCITabFuncInfo, p_parm in varchar2, p_rows_req in number := 2 )
  return number, 
  static function ODCITableStart( sctx in out NColPipe, p_parm in varchar2, p_rows_req in number := 2 )
  return number, 
  member function ODCITableFetch( self in out NColPipe, nrows in number, outset out anydataset )
  return number,
  member function ODCITableClose( self in NColPipe )
  return number,
  static function show( p_parm in varchar2, p_rows_req in number := 2 )
  return anydataset pipelined using NColPipe
);
/ 

create or replace type body NColPipe as 
  static function ODCITableDescribe( rtype out anytype, p_parm in varchar2, p_rows_req in number := 2 )
  return number
  is
    atyp anytype; 
  begin 
    anytype.begincreate( dbms_types.typecode_object, atyp );
    if p_parm = 'one'
    then
      atyp.addattr( 'one'
                  , dbms_types.typecode_varchar2
                  , null
                  , null 
                  , 10
                  , null
                  , null
                  ); 
    elsif p_parm = 'two'
    then
      atyp.addattr( 'one'
                  , dbms_types.typecode_varchar2
                  , null
                  , null
                  , 10
                  , null
                  , null
                  ); 
      atyp.addattr( 'two'
                  , dbms_types.typecode_varchar2
                  , null
                  , null
                  , 10
                  , null
                  , null
                  ); 
    else
      atyp.addattr( p_parm || '1'
                  , dbms_types.typecode_varchar2
                  , null
                  , null
                  , 10
                  , null
                  , null
                  ); 
      atyp.addattr( p_parm || '2'
                  , dbms_types.typecode_varchar2
                  , null
                  , null
                  , 10
                  , null
                  , null
                  ); 
      atyp.addattr( p_parm || '3'
                  , dbms_types.typecode_number
                  , 10
                  , 0
                  , null
                  , null
                  , null
                  ); 
    end if;

    atyp.endcreate; 

    anytype.begincreate( dbms_types.typecode_table, rtype ); 

    rtype.SetInfo( null, null, null, null, null, atyp, dbms_types.typecode_object, 0 ); 

    rtype.endcreate(); 

    return odciconst.success;

  exception

    when others then

      return odciconst.error;

  end;   

--

  static function ODCITablePrepare( sctx out NColPipe, ti in sys.ODCITabFuncInfo, p_parm in varchar2, p_rows_req in number := 2 )

  return number

  is 

    elem_typ sys.anytype; 

    prec pls_integer; 

    scale pls_integer; 

    len pls_integer; 

    csid pls_integer; 

    csfrm pls_integer; 

    tc pls_integer; 

    aname varchar2(30); 

  begin 

    tc := ti.RetType.GetAttrElemInfo( 1, prec, scale, len, csid, csfrm, elem_typ, aname ); 

    sctx := NColPipe( p_parm, p_rows_req, elem_typ, 0 ); 

    return odciconst.success; 

  end; 

--

  static function ODCITableStart( sctx in out NColPipe, p_parm in varchar2, p_rows_req in number := 2 )

  return number

  is

  begin 

    return odciconst.success; 

  end; 

--

  member function ODCITableFetch( self in out NColPipe, nrows in number, outset out anydataset )

  return number

  is

  begin 

    anydataset.begincreate( dbms_types.typecode_object, self.ret_type, outset ); 

    for i in self.rows_returned + 1 .. self.rows_requested

    loop

      outset.addinstance;

      outset.piecewise(); 

      if self.l_parm = 'one'

      then

        outset.setvarchar2( to_char( i ) ); 

      elsif self.l_parm = 'two'

      then

        outset.setvarchar2( to_char( i ) ); 

        outset.setvarchar2( 'row: ' || to_char( i ) ); 

      else

        outset.setvarchar2( 'row: ' || to_char( i ) ); 

        outset.setvarchar2( 'row: ' || to_char( i ) ); 

        outset.setnumber( i ); 

      end if;

      self.rows_returned := self.rows_returned + 1;

    end loop;

    outset.endcreate; 

    return odciconst.success; 

  end; 

--  

  member function ODCITableClose( self in NColPipe )

  return number

  is

  begin

    return odciconst.success; 

  end; 

end; 

/