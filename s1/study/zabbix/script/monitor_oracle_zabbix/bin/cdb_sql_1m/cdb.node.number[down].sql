set heading off;
set pagesize 0; 
set feedback off; 
set verify off;
set echo off;
select count(*) from sys.gv_$instance where status<>'OPEN';
exit
