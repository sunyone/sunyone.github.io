# 北京节点服务器数量
SELECT g.name, count(*)
FROM groups g
JOIN hosts_groups hg ON g.groupid=hg.groupid
JOIN hosts h ON hg.hostid=h.hostid
WHERE h.status IN (0, 1)
  AND (g.name NOT LIKE 'ORACLE-%' AND g.name NOT IN ('Zabbix servers', '智能网管PaaS平台-服务总线前置服务器'))
GROUP BY g.name

# 服务总线前置服务器数量
SELECT g.name, count(*)
FROM groups g
JOIN hosts_groups hg ON g.groupid=hg.groupid
JOIN hosts h ON hg.hostid=h.hostid
WHERE h.status IN (0, 1)
  AND g.name = '智能网管PaaS平台-服务总线前置服务器'


# 北京节点服务器分组数量
SELECT substring_index(g.name, '-', 1) g_name, count(*)
FROM groups g
JOIN hosts_groups hg ON g.groupid=hg.groupid
JOIN hosts h ON hg.hostid=h.hostid
WHERE h.status IN (0, 1)
  AND (g.name NOT LIKE 'ORACLE-%' AND g.name NOT IN ('Zabbix servers', '智能网管PaaS平台-服务总线前置服务器'))
GROUP BY g_name


# 北京服务器类型异常的
SELECT * FROM (
# 北京服务器类型(物理/虚拟)统计
SELECT g.name g_name, h.name h_name, i.key_ i_key, hs.value
FROM groups g
JOIN hosts_groups hg ON g.groupid=hg.groupid
JOIN hosts h ON hg.hostid=h.hostid
LEFT JOIN items i ON h.hostid=i.hostid
LEFT JOIN history_str hs ON i.itemid=hs.itemid
WHERE h.status IN (0, 1)
  AND (g.name NOT LIKE 'ORACLE-%' AND g.name NOT IN ('Zabbix servers', '智能网管PaaS平台-服务总线前置服务器'))
  AND i.key_='system.product.name'
  #AND hs.value = 'VMware Virtual Platform' #AND hs.clock> (UNIX_TIMESTAMP()-600)
GROUP BY g_name, h_name
ORDER BY g_name, h_name

) a WHERE a.value IS NULL OR a.value = '' OR a.value LIKE 'Not' OR a.value LIKE 'sudo%'


# 北京主机内存
#SELECT round(sum(a.value)/1024/1024/1024/1024,2) 'mem_total(TB)' FROM (  #内存大小
SELECT * FROM (

# 北京内存有问题的项
SELECT g.name g_name, h.name h_name, i.key_ i_key, tu.value_min value, i.error
FROM groups g
JOIN hosts_groups hg ON g.groupid=hg.groupid
JOIN hosts h ON hg.hostid=h.hostid
LEFT JOIN items i ON h.hostid=i.hostid
LEFT JOIN (SELECT itemid, value_min FROM trends_uint WHERE clock> (UNIX_TIMESTAMP()-7200)) tu ON i.itemid=tu.itemid
WHERE h.status IN (0, 1)
  AND (g.name NOT LIKE 'ORACLE-%' AND g.name NOT IN ('Zabbix servers', '智能网管PaaS平台-服务总线前置服务器'))
  AND i.key_='vm.memory.size[total]' 
GROUP BY g_name, h_name
ORDER BY g_name, h_name

) a WHERE a.value IS NULL OR a.value = ''  #内存大小监控项有问题的主机


# 北京cpu核数
SELECT * FROM (

SELECT g.name g_name, h.name h_name, h.status, h.maintenance_status, i.key_ i_key, tu.value_min value, i.error
FROM groups g
JOIN hosts_groups hg ON g.groupid=hg.groupid
JOIN hosts h ON hg.hostid=h.hostid
LEFT JOIN items i ON h.hostid=i.hostid
LEFT JOIN (SELECT itemid, value_min FROM trends_uint WHERE clock> (UNIX_TIMESTAMP()-10800)) tu ON i.itemid=tu.itemid
WHERE h.status IN (0, 1)
  AND (g.name NOT LIKE 'ORACLE-%' AND g.name NOT IN ('Zabbix servers', '智能网管PaaS平台-服务总线前置服务器'))
  AND i.key_='system.cpu.num[online]'
GROUP BY g_name, h_name
ORDER BY g_name, h_name

) a WHERE a.value IS NULL OR a.value = ''   #CPU核数监控项有问题的主机


# 北京CPU利用率
SELECT * FROM (

SELECT g.name g_name, h.name h_name, h.status, h.maintenance_status, i.key_ i_key, tr.value_avg value, i.error
FROM groups g
JOIN hosts_groups hg ON g.groupid=hg.groupid
JOIN hosts h ON hg.hostid=h.hostid
LEFT JOIN items i ON h.hostid=i.hostid
LEFT JOIN (SELECT itemid, value_avg FROM trends WHERE from_unixtime(clock)>='2018-09-01' AND from_unixtime(clock)<'2018-10-01') tr ON i.itemid=tr.itemid
WHERE h.status IN (0, 1)
  AND (g.name NOT LIKE 'ORACLE-%' AND g.name NOT IN ('Zabbix servers', '智能网管PaaS平台-服务总线前置服务器'))
  AND i.key_='custom.cpu.util[,util]'  #i.key_='custom.vm.memory.util' #内存利用率
GROUP BY g_name, h_name
ORDER BY g_name, h_name

) a WHERE a.value IS NULL OR a.value = ''   #CPU利用率监控项有问题的主机

# 北京CPU利用率最小、平均、最大值  206秒
SELECT substring_index(g.name, '-', 1) g_name, MIN(tr.value_min) value_min, AVG(tr.value_avg) value_avg, MAX(tr.value_max) value_max
FROM groups g
JOIN hosts_groups hg ON g.groupid=hg.groupid
JOIN hosts h ON hg.hostid=h.hostid
LEFT JOIN items i ON h.hostid=i.hostid
LEFT JOIN (SELECT * FROM trends WHERE from_unixtime(clock)>='2018-09-01' AND from_unixtime(clock)<'2018-10-01') tr ON i.itemid=tr.itemid
WHERE h.status IN (0, 1)
  AND (g.name NOT LIKE 'ORACLE-%' AND g.name NOT IN ('Zabbix servers', '智能网管PaaS平台-服务总线前置服务器'))
  AND i.key_='custom.cpu.util[,util]' #i.key_='custom.vm.memory.util' #内存利用率
GROUP BY g_name
ORDER BY g_name


