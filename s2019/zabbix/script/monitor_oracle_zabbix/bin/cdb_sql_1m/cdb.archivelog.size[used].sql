set heading off;
set pagesize 0; 
set feedback off; 
set verify off;
set echo off;
set numwidth 30;
select space_used from v$recovery_file_dest;
exit
