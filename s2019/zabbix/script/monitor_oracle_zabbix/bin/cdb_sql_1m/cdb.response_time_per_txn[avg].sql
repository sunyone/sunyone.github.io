set heading off;
set pagesize 0; 
set feedback off; 
set verify off;
set echo off;
select ROUND((AVERAGE / 100),2) from SYS.V_$SYSMETRIC_SUMMARY t where METRIC_NAME='Response Time Per Txn';
exit
