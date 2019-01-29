set heading off;
set pagesize 0; 
set feedback off; 
set verify off;
set echo off;
SELECT round((SELECT sum(to_number(value, 99999999999)) FROM v$sysstat WHERE name IN ('user rollbacks', 'user commits')) / (SELECT (sysdate - startup_time) * 24 * 60 * 60 AS seconds FROM v$instance),0) avg_tx_per_second FROM dual;
exit
