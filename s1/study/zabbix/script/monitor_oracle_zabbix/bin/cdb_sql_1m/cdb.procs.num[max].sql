set heading off;
set pagesize 0; 
set feedback off; 
set verify off;
set echo off;
select value "maxprocs" from v$parameter where name ='processes';
exit
