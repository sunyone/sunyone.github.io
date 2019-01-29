set heading off;
set pagesize 0; 
set feedback off; 
set verify off;
set echo off;
set numwidth 30;
select round(100*space_used/space_limit,2) from v$recovery_file_dest;
exit
