set heading off;
set pagesize 0; 
set feedback off; 
set verify off;
set echo off;
select count(*) "procnum" from v$process;
exit
