declare
  statement varchar2(100);
begin
  for rec in (select username, sid, serial# from v$session where username like upper('&&1._%'))
  loop
  statement := 'alter system kill session '''||rec.sid||','||rec.serial#||''' immediate';
  dbms_output.put_line(statement);
  execute immediate statement;
  end loop;
end;
/
exit
