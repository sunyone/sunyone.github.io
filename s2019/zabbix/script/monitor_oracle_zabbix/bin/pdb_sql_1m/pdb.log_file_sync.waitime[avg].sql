set heading off;
set pagesize 0; 
set feedback off; 
set verify off;
set echo off;
SELECT AVERAGE_WAIT FROM v$system_event WHERE event = 'log file sync';
exit
