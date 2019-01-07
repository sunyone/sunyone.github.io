set heading off;
set pagesize 0; 
set feedback off; 
set verify off;
set echo off;
set numwidth 30;
-- select FREE_MB used_percent from v$asm_diskgroup d where d.name='DATADG';
SELECT SUM(free_mb) FROM v$asm_disk WHERE name LIKE 'DATA%';
exit
