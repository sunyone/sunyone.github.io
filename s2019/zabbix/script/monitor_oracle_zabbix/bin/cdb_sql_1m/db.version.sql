set heading off;
set pagesize 0; 
set feedback off; 
set verify off;
set echo off;
select banner from sys.v_$version WHERE banner LIKE '%Database%';
-- select banner from sys.v_$version;
-- select COMP_ID||' '||COMP_NAME||' '||VERSION||' '||STATUS||' <br />' from dba_registry union SELECT ' - SERVERNAME = <b>'||UTL_INADDR.get_host_name ||'</b> - SERVERADDRESS = <b>'||UTL_INADDR.get_host_address||'</b> <br />'from dual union SELECT ' - DB_NAME = <b>'||SYS_CONTEXT ('USERENV', 'DB_NAME') ||'</b> - INSTANCE_NAME = <b>' ||SYS_CONTEXT ('USERENV', 'INSTANCE_NAME')||'</b> <br />' FROM dual;
exit
