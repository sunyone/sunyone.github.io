set heading off;
set pagesize 0; 
set feedback off; 
set verify off;
set echo off;
set numwidth 30;
-- select round(100*(TOTAL_MB-FREE_MB)/TOTAL_MB,2) used_percent from v$asm_diskgroup d where d.name='DATADG';
SELECT ROUND(100*(SUM(total_mb)-SUM(free_mb))/SUM(total_mb),2) FROM v$asm_disk WHERE name LIKE 'DATA%';
exit
