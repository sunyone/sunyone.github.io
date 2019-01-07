#!/bin/bash

starttime=$(date '+%Y-%m-%d %H:%M:%S')
UP_home=/inm/app/UPScript
app_home=$UP_home/monitor_oracle_zabbix
logFile=$app_home/log/app-1h-$(date '+%Y%m').log
export ORACLE_HOME=${app_home}/oracle-client
export LD_LIBRARY_PATH=${app_home}/oracle-client
zbx_server_ip=10.0.168.124
zbx_server_port=10051
zbx_dir=/inm/app/zabbix/zabbix

function tablespace(){
    pdb=$1
    $ORACLE_HOME/sqlplus -S system/ctinm1123@${pdb} @${app_home}/bin/pdb_sql_1h/tablespace.txt 1> ${app_home}/log/.tbs.${pdb}.tmp

    tbs=($(awk '{printf "%s ",$1}' ${app_home}/log/.tbs.${pdb}.tmp))
    zbx_sender_file=${app_home}/log/.tbs.zbx.${pdb}.tmp
    printf "${pdb} ora.tablespace.discovery " >${zbx_sender_file}
    printf '{"data":[' >>${zbx_sender_file}
    for index in ${!tbs[@]}; do
        #echo ${tbs[${index}]}
        if [[ "${#tbs[@]}" -gt 1 && "${index}" -ne "$((${#tbs[@]}-1))" ]];then
            printf '{"{#TABLESPACE_NAME}":"'${tbs[${index}]}'"},' >>${zbx_sender_file}
        else [[ "${index}" -eq "((${#port[@]}-1))" ]]
            printf '{"{#TABLESPACE_NAME}":"'${tbs[${index}]}'"}' >>${zbx_sender_file}
        fi
    done
    printf ']}' >>${zbx_sender_file}
    ${zbx_dir}/bin/zabbix_sender -vv -z ${zbx_server_ip} -p ${zbx_server_port} -i ${zbx_sender_file} >/dev/null 2>&1
    zbx_sender_status=$(echo $?)
    echo "[$(date "+%Y%m%d %H:%M:%S")] zbx_sender run status is ${zbx_sender_status}. ${pdb}: key="ora.tablespace.discovery"." >> ${logFile}

    awk '{printf "%s pdb.tbs.size[%s,create] %s\n","'${pdb}'",$1,$3}' ${app_home}/log/.tbs.${pdb}.tmp >${zbx_sender_file}
    awk '{printf "%s pdb.tbs.size[%s,used] %s\n","'${pdb}'",$1,$4}' ${app_home}/log/.tbs.${pdb}.tmp >>${zbx_sender_file}
    awk '{printf "%s pdb.tbs.size[%s,free] %s\n","'${pdb}'",$1,$5}' ${app_home}/log/.tbs.${pdb}.tmp >>${zbx_sender_file}
    awk '{printf "%s pdb.tbs.size[%s,pused] %s\n","'${pdb}'",$1,$6}' ${app_home}/log/.tbs.${pdb}.tmp >>${zbx_sender_file}
    ${zbx_dir}/bin/zabbix_sender -vv -z ${zbx_server_ip} -p ${zbx_server_port} -i ${zbx_sender_file} >/dev/null 2>&1
    zbx_sender_status=$(echo $?)
    echo "[$(date "+%Y%m%d %H:%M:%S")] zbx_sender run status is ${zbx_sender_status}. ${pdb}: key="pdb.tbs.size"." >> ${logFile}
}


for pdb in $(grep -E "ORACLE.*PDB" ${ORACLE_HOME}/network/admin/tnsnames.ora|cut -d' ' -f1); do
    {
    tablespace $pdb
    } &
done
wait

endtime=$(date '+%Y-%m-%d %H:%M:%S')
start_seconds=$(date --date="$starttime" +%s);
end_seconds=$(date --date="$endtime" +%s);
echo -e "[$(date "+%Y%m%d %H:%M:%S")] 本次运行时间： "$((end_seconds-start_seconds))"s.\n"  >> ${logFile}
