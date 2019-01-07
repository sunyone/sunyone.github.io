set heading off;
set pagesize 0; 
set feedback off; 
set verify off;
set echo off;
set numwidth 30;
-- select TOTAL_MB from v$asm_diskgroup d where d.name='DATADG';
SELECT SUM(total_mb) FROM v$asm_disk WHERE name LIKE 'DATA%';
exit
