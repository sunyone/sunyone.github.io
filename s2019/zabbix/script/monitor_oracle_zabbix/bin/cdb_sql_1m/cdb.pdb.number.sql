set heading off;
set pagesize 0; 
set feedback off; 
set verify off;
set echo off;
SELECT count(*) from v$PDBS WHERE name NOT LIKE '%PDB$%' ORDER BY name;
exit
