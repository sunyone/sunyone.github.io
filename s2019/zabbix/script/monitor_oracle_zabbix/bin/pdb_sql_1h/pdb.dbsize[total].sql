set heading off;
set pagesize 0; 
set feedback off; 
set verify off;
set echo off;
set numwidth 50;
select sum(bytes) from dba_data_files;
exit
