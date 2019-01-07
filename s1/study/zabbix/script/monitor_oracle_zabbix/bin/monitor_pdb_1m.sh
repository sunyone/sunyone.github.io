#!/bin/bash

starttime=$(date '+%Y-%m-%d %H:%M:%S')
UP_home=/inm/app/UPScript
app_home=$UP_home/monitor_oracle_zabbix
logFile=$app_home/log/app-1m-$(date "+%Y%m").log
export ORACLE_HOME=${app_home}/oracle-client
export LD_LIBRARY_PATH=${app_home}/oracle-client
zbx_server_ip=10.0.168.124
zbx_server_port=10051
zbx_dir=/inm/app/zabbix/zabbix


for pdb in $(grep -E "ORACLE.*PDB" ${ORACLE_HOME}/network/admin/tnsnames.ora|cut -d' ' -f1); do
    {
    #echo $pdb
    for f in $(ls ${app_home}/bin/pdb_sql_1m/*.sql); do
        sql_file_name=$(echo ${f##*/})
        key=$(echo ${sql_file_name%.*})
        VALUE=$($ORACLE_HOME/sqlplus -S system/ctinm1123@${pdb} @$f)
        value=$(echo ${VALUE}| sed 's/^[ \t]*//g'| sed 's/[ \t]*$//g')

        echo $f
        ${zbx_dir}/bin/zabbix_sender -z ${zbx_server_ip} -p ${zbx_server_port} -s "${pdb}" -k "${key}" -o "${value}" #>/dev/null 2>&1
        zbx_sender_status=$(echo $?)
        echo "[$(date "+%Y%m%d %H:%M:%S")] zbx_sender run status is ${zbx_sender_status}. ${pdb}: ${key}="${value}"." >> ${logFile}
    done
    } &
done
wait

endtime=$(date '+%Y-%m-%d %H:%M:%S')
start_seconds=$(date --date="$starttime" +%s);
end_seconds=$(date --date="$endtime" +%s);
echo -e "[$(date "+%Y%m%d %H:%M:%S")] 本次运行时间： "$((end_seconds-start_seconds))"s.\n"  >> ${logFile}
