########### 创建存储过程汇聚数据 #############
# 创建错误类型表
CREATE TABLE up_zbx_ck_type (
  id TINYINT NOT NULL PRIMARY KEY,
  name VARCHAR ( 128 ) NOT NULL
);
INSERT INTO `up_zbx_ck_type` VALUES ('1', '停用设备');
INSERT INTO `up_zbx_ck_type` VALUES ('2', '失联proxy');
INSERT INTO `up_zbx_ck_type` VALUES ('3', '失联proxy影响设备');
INSERT INTO `up_zbx_ck_type` VALUES ('4', '未监控proxy');
INSERT INTO `up_zbx_ck_type` VALUES ('5', 'ping不通设备');
INSERT INTO `up_zbx_ck_type` VALUES ('6', '未监控ping设备');
INSERT INTO `up_zbx_ck_type` VALUES ('7', 'ping监控项无数据设备');
INSERT INTO `up_zbx_ck_type` VALUES ('8', 'agent宕设备');
INSERT INTO `up_zbx_ck_type` VALUES ('9', '未监控agent设备');
INSERT INTO `up_zbx_ck_type` VALUES ('10', 'agent监控项无数据');
INSERT INTO `up_zbx_ck_type` VALUES ('11', 'SSH无法连接设备');
INSERT INTO `up_zbx_ck_type` VALUES ('12', '未监控SSH连接设备');
INSERT INTO `up_zbx_ck_type` VALUES ('13', 'SNMP无法连接设备');
INSERT INTO `up_zbx_ck_type` VALUES ('14', 'IPMI无法连接设备');
INSERT INTO `up_zbx_ck_type` VALUES ('15', '其它有问题监控项');
INSERT INTO `up_zbx_ck_type` VALUES ('16', '当前告警数量');
INSERT INTO `up_zbx_ck_type` VALUES ('17', '自监控无数据的proxy');


# 创建错误数据表
#DROP TABLE up_zbx_ck_data;
CREATE TABLE up_zbx_ck_data (
  typeid TINYINT NOT NULL,
  g_name VARCHAR ( 255 ),
  h_name VARCHAR ( 128 ),
  h_description text,
  p_name VARCHAR ( 128 ),
  p_hostid BIGINT ( 20 ),
  error VARCHAR ( 2048 ),
  p_lastaccess VARCHAR ( 19 ),
  h_maintenance_status INT ( 11 ),
  i_name varchar(255),
  i_key varchar(255),
  i_state int(11),
  value VARCHAR ( 128 ),
  collect_time VARCHAR ( 13 )
  );
# 创建日志记录表
#DROP TABLE IF EXISTS `up_aggre_log`;
CREATE TABLE `up_aggre_log` (
  `infoname` varchar(50) DEFAULT NULL,
  `procname` varchar(200) DEFAULT NULL,
  `timeid` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `descname` varchar(2000) DEFAULT NULL
);

# 创建汇聚数据表
DROP TABLE up_zbx_ck_sum_data;
CREATE TABLE up_zbx_ck_sum_data (
  typeid TINYINT NOT NULL PRIMARY KEY,
  count_20181029 VARCHAR ( 128 ),
  count_20181030 VARCHAR ( 128 ),
  count_20181031 VARCHAR ( 128 ),
  count_20181101 VARCHAR ( 128 ),
  count_20181102 VARCHAR ( 128 ),
  count_20181103 VARCHAR ( 128 ),
  count_20181104 VARCHAR ( 128 ),
  count_20181105 VARCHAR ( 128 ),
  count_20181106 VARCHAR ( 128 ),
  count_20181107 VARCHAR ( 128 ),
  count_20181108 VARCHAR ( 128 ),
  count_20181109 VARCHAR ( 128 )
  );


# 1.停用设备
DROP PROCEDURE IF EXISTS up_zbx_proc_ck_host_stop;
DELIMITER $$
CREATE PROCEDURE up_zbx_proc_ck_host_stop ( )
BEGIN
  INSERT INTO up_aggre_log VALUES ('INFO', '01.停用设备:up_zbx_proc_ck_host_stop', sysdate(), 'BEGIN');
  INSERT INTO up_zbx_ck_data(typeid, g_name, h_name, h_description, error, h_maintenance_status, collect_time)
  SELECT 1 tyepid, g.name g_name, h.name h_name, h.description h_description, h.error, h.maintenance_status h_maintenance_status, DATE_FORMAT( NOW( ), '%Y-%m-%d %H' ) collect_time
  FROM
    groups g
    JOIN hosts_groups hg ON g.groupid = hg.groupid
    RIGHT JOIN hosts h ON hg.hostid = h.hostid
  WHERE h.status = 1;
  INSERT INTO up_aggre_log VALUES ('INFO', '01.停用设备:up_zbx_proc_ck_host_stop', sysdate(), 'END');
  COMMIT;
END$$
DELIMITER ;

# 2.失联的proxy(超过120秒没收到数据)
DROP PROCEDURE IF EXISTS up_zbx_proc_ck_proxystop;
DELIMITER $$
CREATE PROCEDURE up_zbx_proc_ck_proxystop ( )
BEGIN
  INSERT INTO up_aggre_log VALUES ('INFO', '02.失联的proxy:up_zbx_proc_ck_proxystop', sysdate(), 'BENIG');
  INSERT INTO up_zbx_ck_data(typeid, p_name, h_name, h_description, error, h_maintenance_status, p_lastaccess, collect_time)
  SELECT 2 typeid, p.host p_name, h2.name h_name, h2.description h_description, h2.error, h2.maintenance_status h_maintenance_status, FROM_UNIXTIME( p.lastaccess ) p_lastaccess, DATE_FORMAT( NOW( ), '%Y-%m-%d %H' ) collect_time
  FROM
    groups g
    JOIN hosts_groups hg ON g.groupid = hg.groupid
    RIGHT JOIN (SELECT hostid, proxy_hostid FROM hosts WHERE status = 0 ) h1 #排除停用主机
        ON hg.hostid = h1.hostid
    RIGHT JOIN (SELECT host, hostid, lastaccess FROM hosts WHERE status = 5 ) p ON h1.proxy_hostid = p.hostid
        LEFT JOIN (SELECT * FROM hosts WHERE status = 0 ) h2 ON p.host=h2.host # 关联出porxy所在的主机name
        LEFT JOIN (SELECT hostid, key_ FROM items WHERE key_='zabbix[queue]') i ON h2.hostid=i.hostid
  WHERE  (UNIX_TIMESTAMP()-p.lastaccess)>120  # 超过120秒没收到数据
  GROUP BY p_name;

  INSERT INTO up_aggre_log VALUES ('INFO', '02.失联的proxy:up_zbx_proc_ck_proxystop', sysdate(), 'END');
  COMMIT;
END$$
DELIMITER ;


# 3.proxy失联导致无数据的主机：
DROP PROCEDURE IF EXISTS up_zbx_proc_ck_host_proxystop;
DELIMITER $$
CREATE PROCEDURE up_zbx_proc_ck_host_proxystop ( )
BEGIN
  INSERT INTO up_aggre_log VALUES ('INFO', '03.proxy失联导致无数据的主机:up_zbx_proc_ck_host_proxystop', sysdate(), 'BENIG');
  INSERT INTO up_zbx_ck_data(typeid, g_name, h_name, h_description, p_hostid, error, h_maintenance_status, p_lastaccess, collect_time)
  SELECT 3 typeid, g.name g_name, h.name h_name, h.description h_description, h.proxy_hostid p_hostid, h.error, h.maintenance_status h_maintenance_status, FROM_UNIXTIME( h2.lastaccess, "%Y-%m-%d %H:%I:%S" ) p_lastaccess, DATE_FORMAT( NOW( ), '%Y-%m-%d %H' ) collect_time
  FROM
    groups g
    JOIN hosts_groups hg ON g.groupid = hg.groupid
    RIGHT JOIN hosts h  ON hg.hostid = h.hostid
    LEFT  JOIN hosts h2 ON h2.hostid = h.proxy_hostid
  WHERE
    h2.status = 5
    AND h.status = 0
    AND (h2.lastaccess = 0 OR ( unix_timestamp( ) - h2.lastaccess ) > 3600 );
  INSERT INTO up_aggre_log VALUES ('INFO', '03.proxy失联导致无数据的主机:up_zbx_proc_ck_host_proxystop', sysdate(), 'END');
  COMMIT;
END$$
DELIMITER ;


# 4.未监控的proxy：
DROP PROCEDURE IF EXISTS up_zbx_proc_ck_proxynomonitor;
DELIMITER $$
CREATE PROCEDURE up_zbx_proc_ck_proxynomonitor ( )
BEGIN
  INSERT INTO up_aggre_log VALUES ('INFO', '04.未监控的proxy:up_zbx_proc_ck_proxynomonitor', sysdate(), 'BEGIN');
  INSERT INTO up_zbx_ck_data(typeid, p_name, h_name, h_description, error, h_maintenance_status, p_lastaccess, collect_time)
  SELECT 4 typeid, p.host p_name, h2.name h_name, h2.description h_description, h2.error, h2.maintenance_status h_maintenance_status, FROM_UNIXTIME( p.lastaccess ) p_lastaccess, DATE_FORMAT( NOW( ), '%Y-%m-%d %H' ) collect_time
  FROM
    groups g
    JOIN hosts_groups hg ON g.groupid = hg.groupid
    RIGHT JOIN (SELECT hostid, proxy_hostid FROM hosts WHERE status = 0 ) h1 #排除停用主机
        ON hg.hostid = h1.hostid
    RIGHT JOIN (SELECT host, hostid, lastaccess FROM hosts WHERE status = 5 ) p ON h1.proxy_hostid = p.hostid
        LEFT JOIN (SELECT * FROM hosts WHERE status = 0 ) h2 ON p.host=h2.host # 关联出porxy所在的主机name
        LEFT JOIN (SELECT hostid, key_ FROM items WHERE key_='zabbix[queue]') i ON h2.hostid=i.hostid
  WHERE  key_ IS NULL
  GROUP BY p_name;

  INSERT INTO up_aggre_log VALUES ('INFO', '04.未监控的proxy:up_zbx_proc_ck_proxynomonitor', sysdate(), 'END');
  COMMIT;
END$$
DELIMITER ;

# 5.ping不通的设备
DROP PROCEDURE IF EXISTS up_zbx_proc_ck_ping_notong;
DELIMITER $$
CREATE PROCEDURE up_zbx_proc_ck_ping_notong ( )
BEGIN
  DECLARE done INT DEFAULT false;
  DECLARE g_name VARCHAR(255);
  DECLARE h_name VARCHAR(128);
  DECLARE h_description text;
  DECLARE error VARCHAR (2048);
  DECLARE h_maintenance_status INT ( 11 );
  DECLARE value VARCHAR(128);

  DECLARE cur CURSOR FOR
    (SELECT
    g.name AS g_name,
    h.name AS h_name,
    h.description AS h_description,
    h.error AS error,
    h.maintenance_status AS h_maintenance_status,
    t.value AS value
    FROM
      groups g
      JOIN hosts_groups hg ON g.groupid = hg.groupid
      JOIN hosts h ON hg.hostid = h.hostid
      JOIN (
	    	SELECT i.hostid, i.itemid, avg(v.value) value
        FROM items i LEFT JOIN history_uint v ON i.itemid = v.itemid
        WHERE
	    		( i.key_ = 'icmpping' OR i.key_ LIKE 'icmpping[%' ) AND v.clock >= (UNIX_TIMESTAMP() - 3600)
        GROUP BY i.hostid, i.itemid) t ON h.hostid = t.hostid
    WHERE h.status = 0 AND t.value = 0);
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = true;
  DECLARE EXIT HANDLER FOR SQLSTATE '40001' INSERT INTO up_aggre_log VALUES ('ERROR', '5.ping不通的设备：up_zbx_proc_ck_ping_notong', sysdate(), 'Deadlock found when trying to get lock; try restarting transaction.');
  
  INSERT INTO up_aggre_log VALUES ('INFO', '05.ping不通的设备：up_zbx_proc_ck_ping_notong', sysdate(), 'BEGIN');
  DELETE FROM up_zbx_ck_data WHERE typeid=5 AND collect_time=DATE_FORMAT( NOW( ), '%Y-%m-%d %H' );
  COMMIT;

  #SET @i=0;
  OPEN cur;
  FETCH cur INTO g_name, h_name, h_description, error, h_maintenance_status, value;
  WHILE(NOT done)
  DO
    #select group_name, host_name, count_value;
    #SET @i=@i+1;
    INSERT INTO up_zbx_ck_data (typeid, g_name, h_name, h_description, error, h_maintenance_status, value, collect_time) VALUES (5, g_name, h_name, h_description, error, h_maintenance_status, value, DATE_FORMAT( NOW( ), '%Y-%m-%d %H'));
    FETCH cur INTO g_name, h_name, h_description, error, h_maintenance_status, value;
  END WHILE;
  CLOSE cur;
  #SELECT @i;
  COMMIT;

  INSERT INTO up_aggre_log VALUES ('INFO', '05.ping不通的设备：up_zbx_proc_ck_ping_notong', sysdate(), 'END');
  COMMIT;
END$$
DELIMITER ;


# 6.没有对ping进行监控的设备(没有加载ping监控模板)
DROP PROCEDURE IF EXISTS up_zbx_proc_ck_ping_notempl;
DELIMITER $$
CREATE PROCEDURE up_zbx_proc_ck_ping_notempl ( )
BEGIN
  INSERT INTO up_aggre_log VALUES ('INFO', '06.没有对ping进行监控的设备:up_zbx_proc_ck_ping_notempl', sysdate(), 'BEGIN');
  INSERT INTO up_zbx_ck_data(typeid, g_name, h_name, h_description, h_maintenance_status, error, collect_time)
  SELECT 6 typeid, g.name g_name, h.name h_name, h.description h_description, h.maintenance_status h_maintenance_status, h.error, DATE_FORMAT( NOW( ), '%Y-%m-%d %H' ) collect_time
  FROM
    groups g
    JOIN hosts_groups hg ON g.groupid = hg.groupid
    RIGHT JOIN hosts h ON hg.hostid = h.hostid
  WHERE
    h.hostid NOT IN (
    SELECT DISTINCT h2.hostid FROM hosts h2 INNER JOIN items i ON h2.hostid = i.hostid WHERE i.key_ LIKE '%icmpping%') # 排除加载了ping模板的主机
    AND h.status = 0    # 排除停用主机
    AND h.flags <> 2    # 排除内置自动发现主机如EXSI/VM
    AND h.name not like '%no ping%' # 排除主机可见名上标注了“no ping”的主机
  ;

  INSERT INTO up_aggre_log VALUES ('INFO', '06.没有对ping进行监控的设备:up_zbx_proc_ck_ping_notempl', sysdate(), 'END');
  COMMIT;
END$$
DELIMITER ;


# 7.ping无数据
DROP PROCEDURE IF EXISTS up_zbx_proc_ck_ping_notdata;
DELIMITER $$
CREATE PROCEDURE up_zbx_proc_ck_ping_notdata ( )
BEGIN
  DECLARE group_name VARCHAR(128);
  DECLARE done INT DEFAULT false;
  #DECLARE cur CURSOR FOR select g.name from groups g where g.name='业务云平台(二长7楼)';
  DECLARE cur CURSOR FOR select g.name from groups g;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = true;
  INSERT INTO up_aggre_log VALUES ('INFO', '07.ping无数据的设备：up_zbx_proc_ck_ping_notdata', sysdate(), 'BEGIN');
  OPEN cur;
  FETCH cur INTO group_name;
  WHILE(NOT done)
  DO
    INSERT INTO up_zbx_ck_data(typeid, g_name, h_name, h_description, h_maintenance_status, error, value, collect_time)
    SELECT 7 typeid, g.name g_name, h.name h_name, h.description h_description, h.maintenance_status h_maintenance_status, h.error, t.value,DATE_FORMAT( NOW( ), '%Y-%m-%d %H' ) collect_time
    FROM
      groups g
      JOIN hosts_groups hg ON g.groupid = hg.groupid
      RIGHT JOIN hosts h  ON hg.hostid = h.hostid
      LEFT JOIN items i ON h.hostid = i.hostid
      LEFT JOIN history_uint t ON i.itemid=t.itemid
    WHERE
      (h.status = 0 AND h.flags <> 2) # 排除停用主机，排除内置自动发现主机如EXSI/VM
      AND (i.key_ = 'icmpping' OR i.key_ LIKE 'icmpping[%')
      AND t.clock> (UNIX_TIMESTAMP()-600)
      AND t.value IS NULL
      AND g.name=group_name
    GROUP BY h_name;
    FETCH cur INTO group_name;
  END WHILE;
  CLOSE cur;

  INSERT INTO up_aggre_log VALUES ('INFO', '07.ping无数据的设备：up_zbx_proc_ck_ping_notdata', sysdate(), 'END');
  COMMIT;
END$$
DELIMITER ;


# 8.agent不通的设备
DROP PROCEDURE IF EXISTS up_zbx_proc_ck_agent_stop;
DELIMITER $$
CREATE PROCEDURE up_zbx_proc_ck_agent_stop ( )
BEGIN
  INSERT INTO up_aggre_log VALUES ('INFO', '08.agent不通的设备:up_zbx_proc_ck_agent_stop', sysdate(), 'BEGIN');
  INSERT INTO up_zbx_ck_data(typeid, g_name, h_name, h_description, h_maintenance_status, error, collect_time)
  SELECT 8 typeid, g.name g_name, h.name h_name, h.description h_description, h.maintenance_status h_maintenance_status, h.error, DATE_FORMAT( NOW( ), '%Y-%m-%d %H' ) collect_time
  FROM
    groups g
    JOIN hosts_groups hg ON g.groupid = hg.groupid
    RIGHT JOIN hosts h  ON hg.hostid = h.hostid
  WHERE
    h.status = 0 and h.available=2;

  INSERT INTO up_aggre_log VALUES ('INFO', '08.agent不通的设备:up_zbx_proc_ck_agent_stop', sysdate(), 'END');
  COMMIT;
END$$
DELIMITER ;

# 9.没有监控agent状态的主机(未配置Template Zabbix Agent模板)
DROP PROCEDURE IF EXISTS up_zbx_proc_ck_agent_notempl;
DELIMITER $$
CREATE PROCEDURE up_zbx_proc_ck_agent_notempl ( )
BEGIN
  INSERT INTO up_aggre_log VALUES ('INFO', '09.没有监控agent状态的主机:up_zbx_proc_ck_agent_notempl', sysdate(), 'BEGIN');
  INSERT INTO up_zbx_ck_data(typeid, g_name, h_name, h_description, h_maintenance_status, error, collect_time)
  SELECT 9 typeid, g.name g_name, h.name h_name, h.description h_description, h.maintenance_status h_maintenance_status, h.error, DATE_FORMAT( NOW( ), '%Y-%m-%d %H' ) collect_time
  FROM
    (SELECT * FROM hosts WHERE status = 0 AND (available = 1 OR available = 2)) h #所有agent主机
    LEFT JOIN
    (SELECT hostid, key_ FROM items WHERE key_ = 'agent.ping') i #加载了agent模板的主机
    ON h.hostid = i.hostid
    JOIN hosts_groups hg ON hg.hostid = h.hostid
    JOIN groups g ON g.groupid = hg.groupid
  WHERE  i.key_ IS NULL
  ;

  INSERT INTO up_aggre_log VALUES ('INFO', '09.没有监控agent状态的主机:up_zbx_proc_ck_agent_notempl', sysdate(), 'END');
  COMMIT;
END$$
DELIMITER ;

# 10.配了agent模板没有数据的  600秒
DROP PROCEDURE IF EXISTS up_zbx_proc_ck_agent_nodata;
DELIMITER $$
CREATE PROCEDURE up_zbx_proc_ck_agent_nodata ( )
BEGIN
  DECLARE done INT DEFAULT false;
  DECLARE g_name VARCHAR(255);
  DECLARE h_name VARCHAR(128);
  DECLARE h_description text;
  DECLARE error VARCHAR (2048);
  DECLARE h_maintenance_status INT ( 11 );

  DECLARE cur CURSOR FOR
    (SELECT
      g.name AS gname,
      h.name AS hname,
      h.description AS h_description,
      h.error AS error,
      h.maintenance_status AS h_maintenance_status
    FROM
    	groups g
      JOIN hosts_groups hg ON g.groupid = hg.groupid
      JOIN hosts h ON hg.hostid = h.hostid
      LEFT JOIN (
    	  SELECT t1.hostid, avg(s.value) value
    	  FROM
    		  (SELECT h.hostid, i.itemid
    			 FROM hosts h JOIN items i ON h.hostid = i.hostid
    			 WHERE h.status = 0 AND h.available = 1 AND i.key_ = 'agent.ping'
    		  ) t1
    	    JOIN history_uint s ON t1.itemid = s.itemid
    	  WHERE s.clock >= (UNIX_TIMESTAMP() - 600)
    	  GROUP BY t1.hostid) t ON h.hostid = t.hostid
    WHERE h.status = 0 AND h.available = 1 AND t.value IS NULL
    );
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = true;
  DECLARE EXIT HANDLER FOR SQLSTATE '40001' INSERT INTO up_aggre_log VALUES ('ERROR', '10.配了agent模板没有数据的:up_zbx_proc_ck_agent_nodata', sysdate(), 'Deadlock found when trying to get lock; try restarting transaction.');
  
  INSERT INTO up_aggre_log VALUES ('INFO', '10.配了agent模板没有数据的:up_zbx_proc_ck_agent_nodata', sysdate(), 'BEGIN');
  DELETE FROM up_zbx_ck_data WHERE typeid=10 AND collect_time=DATE_FORMAT( NOW( ), '%Y-%m-%d %H' );
  COMMIT;

  #SET @i=0;
  OPEN cur;
  FETCH cur INTO g_name, h_name, h_description, error, h_maintenance_status;
  WHILE(NOT done)
  DO
    #select group_name, host_name, count_value;
    #SET @i=@i+1;
    INSERT INTO up_zbx_ck_data (typeid, g_name, h_name, h_description, error, h_maintenance_status, collect_time) VALUES (10, g_name, h_name, h_description, error, h_maintenance_status, DATE_FORMAT( NOW( ), '%Y-%m-%d %H'));
    FETCH cur INTO g_name, h_name, h_description, error, h_maintenance_status;
  END WHILE;
  CLOSE cur;
  #SELECT @i;
  COMMIT;

  INSERT INTO up_aggre_log VALUES ('INFO', '10.配了agent模板没有数据的:up_zbx_proc_ck_agent_nodata', sysdate(), 'END');
  COMMIT;
END$$
DELIMITER ;


# 11.SSH无法登录的设备
DROP PROCEDURE IF EXISTS up_zbx_proc_ck_ssh_notong;
DELIMITER $$
CREATE PROCEDURE up_zbx_proc_ck_ssh_notong ( )
BEGIN
  INSERT INTO up_aggre_log VALUES ('INFO', '11.SSH无法登录的设备:up_zbx_proc_ck_ssh_notong', sysdate(), 'BEGIN');
  INSERT INTO up_zbx_ck_data(typeid, g_name, h_name, h_description, h_maintenance_status, error, collect_time)
  SELECT 11 typeid, g.name g_name, h.name h_name, h.description h_description, h.maintenance_status h_maintenance_status, h.error, DATE_FORMAT( NOW( ), '%Y-%m-%d %H' ) collect_time
  FROM
    hosts_groups AS hg
    JOIN groups g ON g.groupid = hg.groupid
    JOIN items i ON hg.hostid = i.hostid
    JOIN hosts h ON h.hostid = i.hostid
  WHERE
    h.status = 0
    AND i.key_ LIKE '%ssh_echo%'
    AND i.error <> ''
    ;

  INSERT INTO up_aggre_log VALUES ('INFO', '11.SSH无法登录的设备:up_zbx_proc_ck_ssh_notong', sysdate(), 'END');
  COMMIT;
END$$
DELIMITER ;

# 12.未配置SSH连接监控的设备(没有配置监控模板) <1秒
DROP PROCEDURE IF EXISTS up_zbx_proc_ck_ssh_notempl;
DELIMITER $$
CREATE PROCEDURE up_zbx_proc_ck_ssh_notempl ( )
BEGIN
  INSERT INTO up_aggre_log VALUES ('INFO', '12.未配置SSH连接监控的设备:up_zbx_proc_ck_ssh_notempl', sysdate(), 'BEGIN');
  INSERT INTO up_zbx_ck_data(typeid, g_name, h_name, h_description, h_maintenance_status, error, collect_time)
  SELECT 12 typeid, g.name g_name, h.name h_name, h.description h_description, h.maintenance_status h_maintenance_status, h.error, DATE_FORMAT( NOW( ), '%Y-%m-%d %H' ) collect_time
  FROM
    (
    SELECT ht.templateid, h.hostid, h.name, h.description, h.maintenance_status, h.error
    FROM hosts_templates ht, hosts h
    WHERE ht.hostid = h.hostid AND status IN ( 0, 1 ) ) h
    INNER JOIN (SELECT hostid, name templatename FROM hosts WHERE status = 3 ) t ON t.hostid = h.templateid
    INNER JOIN hosts_groups hg ON hg.hostid = h.hostid
    INNER JOIN groups g ON g.groupid = hg.groupid
  WHERE
    LOWER( t.templatename ) LIKE '%ssh%'
    AND t.hostid NOT IN (SELECT h.hostid FROM hosts h INNER JOIN items i ON i.hostid = h.hostid WHERE i.key_ LIKE '%ssh_echo%')
    AND h.name not like '%no ssh%'
    ;

  INSERT INTO up_aggre_log VALUES ('INFO', '12.未配置SSH连接监控的设备:up_zbx_proc_ck_ssh_notempl', sysdate(), 'END');
  COMMIT;
END$$
DELIMITER ;


# 13.SNMP不通的设备 <1秒
DROP PROCEDURE IF EXISTS up_zbx_proc_ck_snmp_notong;
DELIMITER $$
CREATE PROCEDURE up_zbx_proc_ck_snmp_notong ( )
BEGIN
  INSERT INTO up_aggre_log VALUES ('INFO', '13.SNMP不通的设备:up_zbx_proc_ck_snmp_notong', sysdate(), 'BEGIN');
  INSERT INTO up_zbx_ck_data(typeid, g_name, h_name, h_description, h_maintenance_status, error, collect_time)
  SELECT 13 typeid, g.name g_name, h.name h_name, h.description h_description, h.maintenance_status h_maintenance_status, h.snmp_error error, DATE_FORMAT( NOW( ), '%Y-%m-%d %H' ) collect_time
  FROM
    groups g
    JOIN hosts_groups hg ON g.groupid = hg.groupid
    RIGHT JOIN hosts h ON hg.hostid = h.hostid
  WHERE
    h.status = 0 and h.snmp_available=2
    ;

  INSERT INTO up_aggre_log VALUES ('INFO', '13.SNMP不通的设备:up_zbx_proc_ck_snmp_notong', sysdate(), 'END');
  COMMIT;
END$$
DELIMITER ;

# 14.IPMI不通的设备 <1秒
DROP PROCEDURE IF EXISTS up_zbx_proc_ck_ipmi_notong;
DELIMITER $$
CREATE PROCEDURE up_zbx_proc_ck_ipmi_notong ( )
BEGIN
  INSERT INTO up_aggre_log VALUES ('INFO', '14.IPMI不通的设备:up_zbx_proc_ck_ipmi_notong', sysdate(), 'BEGIN');
  INSERT INTO up_zbx_ck_data(typeid, g_name, h_name, h_description, h_maintenance_status, error, collect_time)
  SELECT 13 typeid, g.name g_name, h.name h_name, h.description h_description, h.maintenance_status h_maintenance_status, h.ipmi_error error, DATE_FORMAT( NOW( ), '%Y-%m-%d %H' ) collect_time
  FROM
    groups g
    JOIN hosts_groups hg ON g.groupid = hg.groupid
    RIGHT JOIN hosts h ON hg.hostid = h.hostid
  WHERE
    h.status = 0 and h.ipmi_available=2
    ;

  INSERT INTO up_aggre_log VALUES ('INFO', '14.IPMI不通的设备:up_zbx_proc_ck_ipmi_notong', sysdate(), 'END');
  COMMIT;
END$$
DELIMITER ;


# 15.其它有问题监控项
#报错的监控项
DROP PROCEDURE IF EXISTS up_zbx_proc015_ck_itemerror;
DELIMITER $$
CREATE PROCEDURE up_zbx_proc015_ck_itemerror ( )
BEGIN
    DECLARE group_name VARCHAR(128);
    DECLARE done INT DEFAULT false;
    DECLARE cur CURSOR FOR select g.name from groups g;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = true;
    INSERT INTO up_aggre_log VALUES ('INFO', '15. 报错监控项：up_zbx_proc015_ck_itemerror', sysdate(), 'BEGIN');
    OPEN cur;
    FETCH cur INTO group_name;
    WHILE(NOT done)
    DO
        INSERT INTO up_zbx_ck_data(typeid, g_name, h_name, h_description, h_maintenance_status, i_name, i_key, i_state, error, collect_time)
        SELECT 15 typeid, g.name g_name, h.name h_name, h.description h_description, h.maintenance_status h_maintenance_status,i.name i_name, i.key_ i_key, i.state i_state, i.error error, DATE_FORMAT( NOW( ), '%Y-%m-%d %H' ) collect_time
        FROM
            groups g
            JOIN hosts_groups hg ON g.groupid = hg.groupid
            JOIN hosts h ON hg.hostid = h.hostid
            LEFT JOIN items i ON h.hostid = i.hostid
        WHERE
            h.status = 0
            AND h.maintenance_status=0 #排除维护设备
            AND i.status=0   #排除停用监控项
            AND i.type <> 17 #排除TRAP监控项
            AND i.error<>''
            AND i.key_ IN (
                #SELECT h.name, h.hostid, i.name, i.key_, i.itemid
                SELECT i.key_
                FROM groups g
                    JOIN hosts_groups hg ON g.groupid = hg.groupid
                    JOIN hosts h ON hg.hostid = h.hostid
                    JOIN items i ON h.hostid = i.hostid
                WHERE g.name = '泰岳主动监控模板组' AND h.status = 3 AND i.status = 0) #属于泰岳模板的监控项
            AND g.name=group_name
            #AND h.hostid not in (
            #    # SSH连接异常
            #    #SELECT g.name AS g_name, h.name AS h_name, i.key_, i.error
            #    SELECT h.hostid
            #    FROM
            #        hosts_groups AS hg
            #        JOIN groups g ON g.groupid = hg.groupid
            #        JOIN items i ON hg.hostid = i.hostid
            #        JOIN hosts h ON h.hostid = i.hostid
            #    WHERE
            #        h.status = 0
            #        AND i.key_ LIKE '%ssh_echo%' #i.key_ = 'ssh.run[check_pwd_exp,"{HOST.IP}","{$SSH_PORT}",]'
            #        AND i.error <> '' #AND from_unixtime(clock)>='2018-08-01'
            #        AND g.name=group_name
            #    ) # 排除SSH登录异常的主机
        ORDER BY g_name, h_name, i_key;
        FETCH cur INTO group_name;
    END WHILE;
    CLOSE cur;

    #OPEN cur;
    #FETCH cur INTO group_name;
    #WHILE(NOT done)
    #DO
    #    INSERT INTO up_zbx_ck_data(typeid, g_name, h_name, h_description, h_maintenance_status, i_name, i_key, i_state, error, collect_time)
    #    SELECT 15 typeid, g.name g_name, h.name h_name, h.description h_description, h.maintenance_status h_maintenance_status,i.name i_name, i.key_ i_key, i.state i_state, i.error error, DATE_FORMAT( NOW( ), '%Y-%m-%d %H' ) collect_time
    #    FROM
    #        groups g
    #        JOIN hosts_groups hg ON g.groupid = hg.groupid
    #        JOIN hosts h ON hg.hostid = h.hostid
    #        LEFT JOIN items i ON h.hostid = i.hostid
    #    WHERE
    #        h.status = 0
    #        AND i.status = 0
    #        AND i.key_ IN (
    #            #SELECT h.name, h.hostid, i.name, i.key_, i.itemid
    #            SELECT i.key_
    #            FROM groups g
    #                JOIN hosts_groups hg ON g.groupid = hg.groupid
    #                JOIN hosts h ON hg.hostid = h.hostid
    #                JOIN items i ON h.hostid = i.hostid
    #            WHERE g.name = '个人监控模板' AND h.status = 3 AND i.status = 0) #属于泰岳模板的监控项
    #        AND g.name=group_name
    #        AND h.hostid not in (
    #            # SSH连接异常
    #            #SELECT g.name AS g_name, h.name AS h_name, i.key_, i.error
    #            SELECT h.hostid
    #            FROM
    #                hosts_groups AS hg
    #                JOIN groups g ON g.groupid = hg.groupid
    #                JOIN items i ON hg.hostid = i.hostid
    #                JOIN hosts h ON h.hostid = i.hostid
    #            WHERE
    #                h.status = 0
    #                AND i.key_ LIKE '%ssh_echo%' #i.key_ = 'ssh.run[check_pwd_exp,"{HOST.IP}","{$SSH_PORT}",]'
    #                AND i.error <> '' #AND from_unixtime(clock)>='2018-08-01'
    #                AND g.name=group_name
    #            ) # 排除SSH登录异常的主机
    #        AND i.error<>''
    #    ORDER BY g_name, h_name, i_key;
    #    FETCH cur INTO group_name;
    #END WHILE;
    #CLOSE cur;

    INSERT INTO up_aggre_log VALUES ('INFO', '15. 报错监控项：up_zbx_proc015_ck_itemerror', sysdate(), 'END');
    COMMIT;
END$$
DELIMITER ;

#空值的监控项
DROP PROCEDURE IF EXISTS up_zbx_proc015_ck_itemnull;
DELIMITER $$
CREATE PROCEDURE up_zbx_proc015_ck_itemnull ( )
BEGIN
    DECLARE group_name VARCHAR(128);
    DECLARE done INT DEFAULT false;
    DECLARE cur CURSOR FOR select g.name from groups g;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = true;
    INSERT INTO up_aggre_log VALUES ('INFO', '15. 空值监控项：up_zbx_proc015_ck_itemnull', sysdate(), 'BEGIN');
    OPEN cur;
    FETCH cur INTO group_name;
    WHILE(NOT done)
    DO
        INSERT INTO up_zbx_ck_data(typeid, g_name, h_name, h_description, h_maintenance_status, i_name, i_key, i_state, value, collect_time)
        SELECT 15 typeid, g.name g_name, h.name h_name, h.description h_description, h.maintenance_status h_maintenance_status,i.name i_name, i.key_ i_key, i.state i_state, hi.value value, DATE_FORMAT( NOW( ), '%Y-%m-%d %H' ) collect_time
        FROM
          groups g
          JOIN hosts_groups hg ON g.groupid = hg.groupid
          RIGHT JOIN HOSTS h ON hg.hostid = h.hostid
          LEFT JOIN  items i on h.hostid = i.hostid
          LEFT JOIN history_text hi ON i.itemid = hi.itemid
        WHERE
          i.value_type=4
          AND h.status=0 AND i.status=0 AND i.error='' AND (hi.clock > UNIX_TIMESTAMP( ) - 3600)
          AND i.name IN (
                #SELECT h.name, h.hostid, i.name, i.key_, i.itemid
                SELECT i.name
                FROM groups g
                    JOIN hosts_groups hg ON g.groupid = hg.groupid
                    JOIN hosts h ON hg.hostid = h.hostid
                    JOIN items i ON h.hostid = i.hostid
                #WHERE g.name in ('泰岳主动监控模板组','个人监控模板') AND h.status = 3 AND i.status = 0) #属于泰岳模板的监控项
                WHERE g.name = '泰岳主动监控模板组' AND h.status = 3 AND i.status = 0) #属于泰岳模板的监控项
          AND  g.name=group_name
          AND hi.value=''
        GROUP BY g_name, h_name, i_name;
        FETCH cur INTO group_name;
    END WHILE;
    CLOSE cur;
    INSERT INTO up_aggre_log VALUES ('INFO', '15. 空值监控项：up_zbx_proc015_ck_itemnull', sysdate(), 'END');
    COMMIT;
END$$
DELIMITER ;

# 16.当前告警数量
# 16.当前告警数量(单条告警)
# 缺点：属于多个组的设备会重复统计；告警依赖的会统计多条
DROP PROCEDURE IF EXISTS up_zbx_proc016_ck_aalert_count;
DELIMITER $$
CREATE PROCEDURE up_zbx_proc016_ck_aalert_count ( )
BEGIN
  DECLARE done INT DEFAULT false;
  DECLARE group_name VARCHAR(128);
  DECLARE host_name VARCHAR(128);
  DECLARE count_value VARCHAR(128);

  DECLARE cur CURSOR FOR
    ( SELECT g.name g_name, h.name h_name, '1' value
      FROM groups g
        JOIN hosts_groups hg ON g.groupid=hg.groupid
        JOIN hosts h ON hg.hostid=h.hostid
        JOIN 
      		(SELECT i.hostid,r.description 
      		 FROM items i JOIN functions f ON i.itemid=f.itemid
      			 JOIN triggers r ON f.triggerid=r.triggerid
      			 JOIN problem p ON r.triggerid=p.objectid
      		 WHERE (i.status=0 AND i.state=0)
      			 AND (r.value=1 AND r.type=0 AND r.status=0 AND r.state=0)
      		 GROUP BY i.hostid, r.description) t ON h.hostid=t.hostid
      WHERE h.status=0 AND h.maintenance_status=0
    );
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = true;
  DECLARE EXIT HANDLER FOR SQLSTATE '40001' INSERT INTO up_aggre_log VALUES ('ERROR', '16.当前告警数量(单条告警)：up_zbx_proc016_ck_aalert_count', sysdate(), 'Deadlock found when trying to get lock; try restarting transaction.');
  
  INSERT INTO up_aggre_log VALUES ('INFO', '16.当前告警数量(单条告警)：up_zbx_proc016_ck_aalert_count', sysdate(), 'BEGIN');
  DELETE FROM up_zbx_ck_data WHERE typeid=16 AND collect_time=DATE_FORMAT( NOW( ), '%Y-%m-%d %H' );
  COMMIT;

  OPEN cur;
  FETCH cur INTO group_name, host_name, count_value;
  WHILE(NOT done)
  DO
    select group_name, host_name, count_value;
    INSERT INTO up_zbx_ck_data (typeid, g_name, h_name, value, collect_time) VALUES (16, group_name, host_name, count_value, DATE_FORMAT( NOW( ), '%Y-%m-%d %H'));
    FETCH cur INTO group_name, host_name, count_value;
  END WHILE;
  CLOSE cur;
  COMMIT;

  INSERT INTO up_aggre_log VALUES ('INFO', '16.当前告警数量(单条告警)：up_zbx_proc016_ck_aalert_count', sysdate(), 'END');
  COMMIT;
END$$
DELIMITER ;

# 16.当前告警数量(多条告警)
DROP PROCEDURE IF EXISTS up_zbx_proc016_ck_malert_count;
DELIMITER $$
CREATE PROCEDURE up_zbx_proc016_ck_malert_count ( )
BEGIN
  DECLARE done INT DEFAULT false;
  DECLARE group_name VARCHAR(128);
  DECLARE host_name VARCHAR(128);
  DECLARE count_value VARCHAR(128);

  DECLARE cur CURSOR FOR
    (SELECT g.name g_name, h.name h_name, count(1) value
      FROM groups g
        JOIN hosts_groups hg ON g.groupid=hg.groupid
        JOIN hosts h ON hg.hostid=h.hostid
        JOIN items i ON h.hostid=i.hostid
        JOIN functions f ON i.itemid=f.itemid
        JOIN triggers r ON f.triggerid=r.triggerid
        JOIN problem p ON r.triggerid=p.objectid
      WHERE h.status=0 AND h.maintenance_status=0
        AND (i.status=0 AND i.state=0)
        AND (r.value=1 AND r.type=1 AND r.status=0 AND r.state=0)
      GROUP BY g_name, h_name);
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = true;
  DECLARE EXIT HANDLER FOR SQLSTATE '40001' INSERT INTO up_aggre_log VALUES ('ERROR', '16.当前告警数量(多条告警)：up_zbx_proc016_ck_malert_count', sysdate(), 'Deadlock found when trying to get lock; try restarting transaction.');
  INSERT INTO up_aggre_log VALUES ('INFO', '16.当前告警数量(多条告警)：up_zbx_proc016_ck_malert_count', sysdate(), 'BEGIN');

  OPEN cur;
  FETCH cur INTO group_name, host_name, count_value;
  WHILE(NOT done)
  DO
    #select group_name, host_name, count_value;
    INSERT INTO up_zbx_ck_data (typeid, g_name, h_name, value, collect_time) VALUES (16, group_name, host_name, count_value, DATE_FORMAT( NOW( ), '%Y-%m-%d %H'));
    FETCH cur INTO group_name, host_name, count_value;
  END WHILE;
  CLOSE cur;
  COMMIT;

  INSERT INTO up_aggre_log VALUES ('INFO', '16.当前告警数量(多条告警)：up_zbx_proc016_ck_malert_count', sysdate(), 'END');
  COMMIT;
END$$
DELIMITER ;

# 17.自监控无数据的proxy
DROP PROCEDURE IF EXISTS up_zbx_proc017_ck_proxy_nodata;
DELIMITER $$
CREATE PROCEDURE up_zbx_proc017_ck_proxy_nodata ( )
BEGIN
  DECLARE done INT DEFAULT false;
  DECLARE g_name VARCHAR(255);        #影响到的主机组
  DECLARE h_name VARCHAR(128);        #proxy所在主机的主机名
  DECLARE p_name VARCHAR(128);        #proxy名称
  DECLARE p_lastaccess VARCHAR(19);   #最后接收数据的时间
  DECLARE value VARCHAR(128);         #KEY’zabbix[wcache,values]‘的平均值

  DECLARE cur CURSOR FOR (
    SELECT g.name AS g_name, p.host AS p_name, h2.name AS h_name, p.lastaccess AS p_lastaccess, t.value AS value
    FROM
      groups g
      JOIN hosts_groups hg ON g.groupid = hg.groupid
      RIGHT JOIN (SELECT hostid, proxy_hostid FROM hosts WHERE status = 0 ) h1 ON hg.hostid = h1.hostid #排除停用主机     
      RIGHT JOIN (SELECT host, hostid, lastaccess FROM hosts WHERE status = 5 ) p ON h1.proxy_hostid = p.hostid
      LEFT JOIN (SELECT * FROM hosts WHERE status = 0 ) h2 ON p.host=h2.host # 关联出porxy所在的主机name
      JOIN (SELECT hostid, key_ FROM items WHERE key_='zabbix[wcache,values]') i ON h2.hostid=i.hostid
	    LEFT JOIN ( 
	      SELECT i2.itemid,i2.hostid,AVG(s.value) value
	      FROM items i2 JOIN history s ON i2.itemid=s.itemid 
	      WHERE i2.key_='zabbix[wcache,values]' AND s.clock >= (UNIX_TIMESTAMP() - 3600) 
	      GROUP BY i2.hostid, i2.itemid ) t ON i.hostid=t.hostid
    #WHERE value IS NULL
    GROUP BY p.host ,g.name);
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = true;
  DECLARE EXIT HANDLER FOR SQLSTATE '40001' INSERT INTO up_aggre_log VALUES ('ERROR', '17.自监控无数据的proxy：up_zbx_proc017_ck_proxy_nodata', sysdate(), 'Deadlock found when trying to get lock; try restarting transaction.');
  
  INSERT INTO up_aggre_log VALUES ('INFO', '17.自监控无数据的proxy：up_zbx_proc017_ck_proxy_nodata', sysdate(), 'BEGIN');
  DELETE FROM up_zbx_ck_data WHERE typeid=17 AND collect_time=DATE_FORMAT( NOW( ), '%Y-%m-%d %H' );
  COMMIT;

  #SET @i=0;
  OPEN cur;
  FETCH cur INTO g_name, h_name, p_name, p_lastaccess, value;
  WHILE(NOT done)
  DO
    #select group_name, host_name, count_value;
    #SET @i=@i+1;
    INSERT INTO up_zbx_ck_data (typeid, g_name, h_name, p_name, p_lastaccess, value, collect_time) VALUES (17, g_name, h_name, p_name, p_lastaccess, value, DATE_FORMAT( NOW( ), '%Y-%m-%d %H'));
    FETCH cur INTO g_name, h_name, p_name, p_lastaccess, value;
  END WHILE;
  CLOSE cur;
  #SELECT @i;
  COMMIT;

  INSERT INTO up_aggre_log VALUES ('INFO', '17.自监控无数据的proxy：up_zbx_proc017_ck_proxy_nodata', sysdate(), 'END');
  COMMIT;
END$$
DELIMITER ;

# 101.云视部监控项数量(总数/不支持)(排除停用维护和trap)
DROP PROCEDURE IF EXISTS up_zbx_proc101_ck_yunshibu_items;
DELIMITER $$
CREATE PROCEDURE up_zbx_proc101_ck_yunshibu_items ( )
BEGIN
  DECLARE count_day VARCHAR(128);
  DECLARE c VARCHAR(128);
  DECLARE tab_field VARCHAR(128);
  DECLARE done INT DEFAULT false;
  DECLARE cur CURSOR FOR (SELECT count(*)
    FROM
      groups g
      JOIN hosts_groups hg ON g.groupid = hg.groupid
      JOIN hosts h  ON hg.hostid = h.hostid
      LEFT JOIN items i ON h.hostid = i.hostid
    WHERE h.status=0   #排除停用设备
      AND h.maintenance_status=0 #排除维护设备
      AND i.status=0   #排除停用监控项
      AND i.type <> 17 #排除TRAP监控项
      AND i.key_ IN (
          SELECT i.key_
          FROM groups g
              JOIN hosts_groups hg ON g.groupid = hg.groupid
              JOIN hosts h ON hg.hostid = h.hostid
              JOIN items i ON h.hostid = i.hostid
          WHERE h.status = 3 AND i.status = 0)
      AND g.name IN ('行业云平台（常州）','行业云平台（淮安）','行业云平台（连云港）','行业云平台（南通）','行业云平台（苏州）','行业云平台（泰州）','行业云平台（无锡）','行业云平台（宿迁）','行业云平台（徐州）','行业云平台（盐城）','行业云平台（扬州）','行业云平台（镇江）','南京IDC云平台','南京云桌面二期-服务器-WINDOWS','南京云桌面二期-硬件服务器','业务云SDN二长节点','业务云SDN长乐路节点','业务云二长7楼KVM集群','业务云公信大数据平台（公信集成项目）','业务云公信分布式存储（公信集成项目）','业务云平台（二长6楼）','业务云平台(二长7楼)','业务云平台(长乐路3楼)','业务云平台SDN(公信集成项目)','云资源综合支撑系统（行业云版）','云资源综合支撑系统（业务云版）','桌面云')
    GROUP BY i.state);
  DECLARE CONTINUE HANDLER FOR SQLSTATE '42S21' SET @err_msg='列名重复';
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = true;
  SET count_day ='';
  INSERT INTO up_aggre_log VALUES ('INFO', '101.云视部监控项数量：up_zbx_proc101_ck_yunshibu_items', sysdate(), 'BEGIN');
  OPEN cur;
  FETCH cur INTO c;
  WHILE(NOT done)
  DO
    #select 'c=', c;
    SET count_day=CONCAT(count_day, '/', c);
    #select count_day;
    FETCH cur INTO c;
  END WHILE;
  CLOSE cur;
  SET count_day = substring(count_day, 2);
  SET tab_field=CONCAT('count_', DATE_FORMAT( NOW( ), '%Y%m%d'));
  #SET @quefield_sqlstr = CONCAT('SET \@flag = (select 1 from information_schema.columns where table_schema=\'zabbix\' and table_name=\'up_zbx_ck_sum_data\' AND COLUMN_NAME=\'', tab_field, '\')');
  SET @altertab_sqlstr = CONCAT('ALTER TABLE up_zbx_ck_sum_data ADD ', tab_field, ' VARCHAR(128)');
  #PREPARE quefield_exec FROM @quefield_sqlstr;
  #EXECUTE quefield_exec;
  #IF NOT EXISTS ( select @flag) THEN
    #ALTER TABLE up_zbx_ck_sum_data ADD count_20181110 VARCHAR(128)；
  PREPARE altertab_exec FROM @altertab_sqlstr;
  EXECUTE altertab_exec;
  #END IF;
  SET @update_sqlstr = concat('UPDATE up_zbx_ck_sum_data SET ', tab_field,'=\'', count_day, '\' WHERE typeid=101');
  PREPARE update_exec FROM @update_sqlstr;
  EXECUTE update_exec;
  INSERT INTO up_aggre_log VALUES ('INFO', '101.云视部监控项数量：up_zbx_proc101_ck_yunshibu_items', sysdate(), 'END');
  COMMIT;
END$$
DELIMITER ;



# 102.云视部泰岳模板监控项数量(总数/不支持)(排除停用维护和trap)
DROP PROCEDURE IF EXISTS up_zbx_proc102_ck_yunshibu_items;
DELIMITER $$
CREATE PROCEDURE up_zbx_proc102_ck_yunshibu_items ( )
BEGIN
  DECLARE count_day VARCHAR(128);
  DECLARE c VARCHAR(128);
  DECLARE tab_field VARCHAR(128);
  DECLARE done INT DEFAULT false;
  DECLARE cur CURSOR FOR (SELECT count(*)
    FROM
      groups g
      JOIN hosts_groups hg ON g.groupid = hg.groupid
      JOIN hosts h  ON hg.hostid = h.hostid
      LEFT JOIN items i ON h.hostid = i.hostid
    WHERE h.status=0   #排除停用设备
      AND h.maintenance_status=0 #排除维护设备
      AND i.status=0   #排除停用监控项
      AND i.type <> 17 #排除TRAP监控项
      AND i.key_ IN (
          SELECT i.key_
          FROM groups g
              JOIN hosts_groups hg ON g.groupid = hg.groupid
              JOIN hosts h ON hg.hostid = h.hostid
              JOIN items i ON h.hostid = i.hostid
          WHERE g.name = '泰岳主动监控模板组' AND h.status = 3 AND i.status = 0) #属于泰岳模板的监控项
      AND g.name IN ('行业云平台（常州）','行业云平台（淮安）','行业云平台（连云港）','行业云平台（南通）','行业云平台（苏州）','行业云平台（泰州）','行业云平台（无锡）','行业云平台（宿迁）','行业云平台（徐州）','行业云平台（盐城）','行业云平台（扬州）','行业云平台（镇江）','南京IDC云平台','南京云桌面二期-服务器-WINDOWS','南京云桌面二期-硬件服务器','业务云SDN二长节点','业务云SDN长乐路节点','业务云二长7楼KVM集群','业务云公信大数据平台（公信集成项目）','业务云公信分布式存储（公信集成项目）','业务云平台（二长6楼）','业务云平台(二长7楼)','业务云平台(长乐路3楼)','业务云平台SDN(公信集成项目)','云资源综合支撑系统（行业云版）','云资源综合支撑系统（业务云版）','桌面云')
    GROUP BY i.state);
  DECLARE CONTINUE HANDLER FOR SQLSTATE '42S21' SET @err_msg='列名重复';
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = true;
  SET count_day ='';
  INSERT INTO up_aggre_log VALUES ('INFO', '102.云视部泰岳模板监控项数量：up_zbx_proc102_ck_yunshibu_items', sysdate(), 'BEGIN');
  OPEN cur;
  FETCH cur INTO c;
  WHILE(NOT done)
  DO
    #select 'c=', c;
    SET count_day=CONCAT(count_day, '/', c);
    #select count_day;
    FETCH cur INTO c;
  END WHILE;
  CLOSE cur;
  SET count_day = SUBSTRING(count_day, 2);
  SET tab_field=CONCAT('count_', DATE_FORMAT( NOW( ), '%Y%m%d'));

  SET @altertab_sqlstr = CONCAT('ALTER TABLE up_zbx_ck_sum_data ADD ', tab_field, ' VARCHAR(128)');
  PREPARE altertab_exec FROM @altertab_sqlstr;
  EXECUTE altertab_exec;

  SET @update_sqlstr = CONCAT('UPDATE up_zbx_ck_sum_data SET ', tab_field,'=\'', count_day, '\' WHERE typeid=102');
  PREPARE update_exec FROM @update_sqlstr;
  EXECUTE update_exec;
  INSERT INTO up_aggre_log VALUES ('INFO', '102.云视部泰岳模板监控项数量：up_zbx_proc102_ck_yunshibu_items', sysdate(), 'END');
  COMMIT;
END$$
DELIMITER ;


# 999.汇总数据
DROP PROCEDURE IF EXISTS up_zbx_proc999_ck_sum;
DELIMITER $$
CREATE PROCEDURE up_zbx_proc999_ck_sum ( )
BEGIN
  DECLARE count_day VARCHAR(128);
  DECLARE c VARCHAR(128);
  DECLARE tab_field VARCHAR(128);
  DECLARE typeid VARCHAR(128);
  DECLARE sumcount VARCHAR(128);

  DECLARE done INT DEFAULT false;
  DECLARE cur CURSOR FOR SELECT d.typeid, count(1) FROM up_zbx_ck_data d WHERE d.collect_time=(SELECT max(collect_time) FROM up_zbx_ck_data) AND d.typeid<>16 GROUP BY d.typeid;
  DECLARE CONTINUE HANDLER FOR SQLSTATE '42S21' SET @err_msg='列名重复';
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = true;

  INSERT INTO up_aggre_log VALUES ('INFO', '999.zabbix自检汇总数据：up_zbx_proc999_ck_sum', sysdate(), 'BEGIN');
  SET tab_field=CONCAT('count_', DATE_FORMAT( NOW( ), '%Y%m%d'));
  SET @altertab_sqlstr = CONCAT('ALTER TABLE up_zbx_ck_sum_data ADD ', tab_field, ' VARCHAR(128)');
  PREPARE altertab_exec FROM @altertab_sqlstr;
  EXECUTE altertab_exec;

  OPEN cur;
  FETCH cur INTO typeid,sumcount;
  WHILE(NOT done)
  DO
    #select typeid,sumcount;
    SET @update_sqlstr = concat('UPDATE up_zbx_ck_sum_data SET ', tab_field, '=\'', sumcount, '\' WHERE typeid=', typeid);
    PREPARE update_exec FROM @update_sqlstr;
    EXECUTE update_exec;
    FETCH cur INTO typeid,sumcount;
  END WHILE;
  CLOSE cur;

  SET @aa = (SELECT sum(value) FROM up_zbx_ck_data d WHERE d.collect_time=(SELECT max(collect_time) FROM up_zbx_ck_data) AND d.typeid=16 GROUP BY d.typeid);
  SET @update_sqlstr = concat('UPDATE up_zbx_ck_sum_data SET ', tab_field, '=\'', @aa, '\' WHERE typeid=16');
  PREPARE update_exec FROM @update_sqlstr;
  EXECUTE update_exec;

  #SET @aa = (SELECT count(DISTINCT(p_name)) FROM up_zbx_ck_type t JOIN up_zbx_ck_data d ON t.id = d.typeid WHERE collect_time = ( SELECT max(collect_time) FROM up_zbx_ck_data WHERE typeid = 17 ) AND typeid = 17 AND value IS NULL);
  SET @aa = (select count(*) from (SELECT p_name, 1 value FROM up_zbx_ck_type t JOIN up_zbx_ck_data d ON t.id = d.typeid WHERE collect_time = ( SELECT max(collect_time) FROM up_zbx_ck_data WHERE typeid = 17 ) AND typeid = 17 AND value IS NULL GROUP BY p_name) t);
  SET @update_sqlstr = concat('UPDATE up_zbx_ck_sum_data SET ', tab_field, '=\'', @aa, '\' WHERE typeid=17');
  PREPARE update_exec FROM @update_sqlstr;
  EXECUTE update_exec;

  INSERT INTO up_aggre_log VALUES ('INFO', '999.zabbix自检汇总数据：up_zbx_proc999_ck_sum', sysdate(), 'END');
  COMMIT;
END$$
DELIMITER ;


######
select * from information_schema.processlist where state<>'';
select t.id, t.name, d.count_20181210, d.count_20181211, d.count_20181212 from up_zbx_ck_type t JOIN up_zbx_ck_sum_data d ON t.id=d.typeid;
select * from up_v_patrol_00;
select * from up_aggre_log where timeid like '2018-12-12%';
# 16. 当前告警数量
#select * from up_v_patrol_16 where g_name IN ('行业云平台（常州）','行业云平台（淮安）','行业云平台（连云港）','行业云平台（南通）','行业云平台（苏州）','行业云平台（泰州）','行业云平台（无锡）','行业云平台（宿迁）','行业云平台（徐州）','行业云平台（盐城）','行业云平台（扬州）','行业云平台（镇江）','南京IDC云平台','南京云桌面二期-服务器-WINDOWS','南京云桌面二期-硬件服务器','业务云SDN二长节点','业务云SDN长乐路节点','业务云二长7楼KVM集群','业务云公信大数据平台（公信集成项目）','业务云公信分布式存储（公信集成项目）','业务云平台（二长6楼）','业务云平台(二长7楼)','业务云平台(长乐路3楼)','业务云平台SDN(公信集成项目)','云资源综合支撑系统（行业云版）','云资源综合支撑系统（业务云版）','桌面云') ORDER BY count DESC, g_name, h_name;
# 17.
#SELECT * FROM up_zbx_ck_data WHERE typeid=17 AND collect_time=DATE_FORMAT( NOW( ), '%Y-%m-%d %H');
######



########## 创建事件定时调度存储过程汇聚数据 ##########
SET GLOBAL event_scheduler = 1;
DROP EVENT IF EXISTS up_zbx_proc_patrol;
CREATE EVENT up_zbx_proc_patrol
ON SCHEDULE EVERY 4 HOUR STARTS '2018-11-06 01:10:00'
ON COMPLETION NOT PRESERVE ENABLE COMMENT '每4小时自查数据并存入up_zbx_ck_data表中'
DO
BEGIN
  INSERT INTO up_aggre_log VALUES ('INFO', '00.ZABBIX巡检开始...', sysdate(), 'BEGIN');
  # 1.停用设备 <1秒
  CALL up_zbx_proc_ck_host_stop ( );

  # 2.超过60秒没有数据的proxy <1秒
  CALL up_zbx_proc_ck_proxystop ( );

  # 3.proxy失联导致无数据的主机 <1秒
  CALL up_zbx_proc_ck_host_proxystop ( );
  # 4.未监控的proxy <1秒
  CALL up_zbx_proc_ck_proxynomonitor ( );
  # 5.ping不通的设备  10分钟
  CALL up_zbx_proc_ck_ping_notong ( );
  # 6.没有对ping进行监控的设备(没有加载ping监控模板) 2秒
  CALL up_zbx_proc_ck_ping_notempl ( );
  # 7.ping无数据(加载了ping监控模板，但没有正常获取到数据)
  CALL up_zbx_proc_ck_ping_notdata ( );
  # 8.agent不通的设备 <1秒
  CALL up_zbx_proc_ck_agent_stop ( ) ;
  # 9.没有监控agent状态的主机(未配置Template Zabbix Agent模板) <1秒
  CALL up_zbx_proc_ck_agent_notempl ( ) ;
  
  # 10.配了agent模板没有数据的 60秒
  CALL up_zbx_proc_ck_agent_nodata ( ) ;

  # 11.SSH无法登录的设备 1秒
  CALL up_zbx_proc_ck_ssh_notong ( );
  # 12.未配置SSH连接监控的设备(没有配置监控模板) <1秒
  CALL up_zbx_proc_ck_ssh_notempl ( ) ;
  # 13.SNMP不通的设备 <1秒
  CALL up_zbx_proc_ck_snmp_notong ( ) ;
  # 14.IPMI不通的设备 <1秒
  CALL up_zbx_proc_ck_ipmi_notong ( ) ;
  # 15. 其它有问题监控项(只包含泰岳模板监控项) 秒
  CALL up_zbx_proc015_ck_itemerror ( );
  CALL up_zbx_proc015_ck_itemnull ();

  # 16.当前告警数量
  CALL up_zbx_proc016_ck_aalert_count ( );
  CALL up_zbx_proc016_ck_malert_count ( );

  # 17.自监控无数据的proxy
	CALL up_zbx_proc017_ck_proxy_nodata ( );

  # 101.云视部监控项数量(总数/不支持)(排除停用维护和trap)
  CALL up_zbx_proc101_ck_yunshibu_items ( );

  # 102.云视部泰岳模板监控项数量(总数/不支持)(排除停用维护和trap)
  CALL up_zbx_proc102_ck_yunshibu_items ( );

  # 999. 汇总数据
  CALL up_zbx_proc999_ck_sum ( );
  
  INSERT INTO up_aggre_log VALUES ('INFO', '00.ZABBIX巡检结束', sysdate(), 'END');
  COMMIT;
END

#创建事件定期删除汇总数据
DROP EVENT IF EXISTS up_delet_up_zbx_ck_data;
CREATE EVENT up_delet_up_zbx_ck_data
ON SCHEDULE EVERY 1 DAY STARTS '2018-11-07 00:05:00'
ON COMPLETION NOT PRESERVE ENABLE COMMENT '每天清除数据表up_zbx_ck_data中的过期的记录'
DO
BEGIN
  DELETE FROM up_zbx_ck_data WHERE collect_time like CONCAT(DATE_SUB(CURDATE(),INTERVAL 30 DAY), '%');
  DELETE FROM up_aggre_log WHERE timeid like CONCAT(DATE_SUB(CURDATE(),INTERVAL 30 DAY), '%');
END


########### 创建视图查看汇聚数据 #############
# 汇总数量
DROP VIEW IF EXISTS up_v_patrol_00;
CREATE VIEW up_v_patrol_00 AS
SELECT t.id, t. NAME, d.c, d.collect_time
FROM (SELECT * FROM up_zbx_ck_type WHERE id not in (16,17)) t
LEFT JOIN
  ( SELECT typeid, count(*) c, collect_time FROM up_zbx_ck_data WHERE collect_time = ( SELECT max(collect_time) FROM up_zbx_ck_data WHERE typeid = 15 ) AND typeid <> 16 GROUP BY typeid) d ON t.id = d.typeid
UNION
SELECT t.id, t. NAME, sum(d. VALUE), d.collect_time
FROM up_zbx_ck_type t JOIN up_zbx_ck_data d ON t.id = d.typeid
WHERE collect_time = ( SELECT max(collect_time) FROM up_zbx_ck_data WHERE typeid = 15 ) AND typeid = 16
UNION
SELECT t.id, t.name, count(DISTINCT(p_name)), d.collect_time
FROM up_zbx_ck_type t JOIN up_zbx_ck_data d ON t.id = d.typeid
WHERE collect_time = ( SELECT max(collect_time) FROM up_zbx_ck_data WHERE typeid = 15 ) AND typeid = 17 AND value IS NULL;

# 1.停用的设备
DROP VIEW IF EXISTS up_v_patrol_01;
CREATE VIEW up_v_patrol_01 AS
    SELECT g_name, h_name, h_description, h_maintenance_status, error, collect_time
    FROM up_zbx_ck_data d
    WHERE d.typeid = 1 AND collect_time = (select max(collect_time) from up_zbx_ck_data where typeid=1)
    ORDER BY g_name, h_name;

# 2.宕掉的proxy(超过60秒没有数据)
DROP VIEW IF EXISTS up_v_patrol_02;
CREATE VIEW up_v_patrol_02 AS
    SELECT p_name, h_name, h_description, h_maintenance_status, error , p_lastaccess, collect_time
    FROM up_zbx_ck_data d
    WHERE d.typeid=2 AND collect_time = (select max(collect_time) from up_zbx_ck_data where typeid=2)
  ORDER BY g_name, h_name;

# 3.proxy失联导致无数据的主机
DROP VIEW IF EXISTS up_v_patrol_03;
CREATE VIEW up_v_patrol_03 AS
    SELECT g_name, h_name, collect_time
    FROM up_zbx_ck_data d
    WHERE d.typeid=3 AND collect_time=(select max(collect_time) from up_zbx_ck_data where typeid=3)
    ORDER BY g_name, h_name;

# 4.未进行自监控的proxy
DROP VIEW IF EXISTS up_v_patrol_04;
CREATE VIEW up_v_patrol_04 AS
    SELECT p_name, h_name, h_description, h_maintenance_status, error , p_lastaccess, collect_time
    FROM up_zbx_ck_data d
    WHERE d.typeid=4 AND collect_time=(select max(collect_time) from up_zbx_ck_data where typeid=4)
    ORDER BY g_name, h_name;

# 5.ping不通的设备
DROP VIEW IF EXISTS up_v_patrol_05;
CREATE VIEW up_v_patrol_05 AS
    SELECT g_name, h_name, h_description, h_maintenance_status, error, collect_time
    FROM up_zbx_ck_data d
    WHERE d.typeid=5 AND collect_time=(select max(collect_time) from up_zbx_ck_data where typeid=5)
    ORDER BY g_name, h_name;

 # 6.没有对ping进行监控的设备(没有加载ping监控模板)
DROP VIEW IF EXISTS up_v_patrol_06;
CREATE VIEW up_v_patrol_06 AS
    SELECT g_name, h_name, h_description, h_maintenance_status, error, collect_time
    FROM up_zbx_ck_data d
    WHERE d.typeid=6 AND collect_time=(select max(collect_time) from up_zbx_ck_data where typeid=6)
    ORDER BY g_name, h_name;

# 7.ping无数据(加载了ping监控模板，但没有正常获取到数据)
DROP VIEW IF EXISTS up_v_patrol_07;
CREATE VIEW up_v_patrol_07 AS
    SELECT g_name, h_name, h_description, h_maintenance_status, error, collect_time
    FROM up_zbx_ck_data d
    WHERE d.typeid=7 AND collect_time=(select max(collect_time) from up_zbx_ck_data where typeid=7)
    ORDER BY g_name, h_name;

# 8.agent不通的设备 <1秒
DROP VIEW IF EXISTS up_v_patrol_08;
CREATE VIEW up_v_patrol_08 AS
    SELECT g_name, h_name, h_description, h_maintenance_status, error, collect_time
    FROM up_zbx_ck_data d
    WHERE d.typeid=8 AND collect_time=(select max(collect_time) from up_zbx_ck_data where typeid=8)
    ORDER BY g_name, h_name;

# 9.没有监控agent状态的主机(未配置Template Zabbix Agent模板) <1秒
DROP VIEW IF EXISTS up_v_patrol_09;
CREATE VIEW up_v_patrol_09 AS
    SELECT g_name, h_name, h_description, h_maintenance_status, error, collect_time
    FROM up_zbx_ck_data d
    WHERE d.typeid=9 AND collect_time=(select max(collect_time) from up_zbx_ck_data where typeid=9)
    ORDER BY g_name, h_name;

# 10.配了agent模板没有数据的 60秒
DROP VIEW IF EXISTS up_v_patrol_10;
CREATE VIEW up_v_patrol_10 AS
    SELECT g_name, h_name, h_description, h_maintenance_status, error, collect_time
    FROM up_zbx_ck_data d
    WHERE d.typeid=10 AND collect_time=(select max(collect_time) from up_zbx_ck_data where typeid=10)
    ORDER BY g_name, h_name;

# 11.SSH无法登录的设备 1秒
DROP VIEW IF EXISTS up_v_patrol_11;
CREATE VIEW up_v_patrol_11 AS
    SELECT g_name, h_name, h_description, h_maintenance_status, error, collect_time
    FROM up_zbx_ck_data d
    WHERE d.typeid=11 AND collect_time=(select max(collect_time) from up_zbx_ck_data where typeid=11)
    ORDER BY g_name, h_name;

# 12.未配置SSH连接监控的设备(没有配置监控模板) <1秒
DROP VIEW IF EXISTS up_v_patrol_12;
CREATE VIEW up_v_patrol_12 AS
    SELECT g_name, h_name, h_description, h_maintenance_status, error, collect_time
    FROM up_zbx_ck_data d
    WHERE d.typeid=12 AND collect_time=(select max(collect_time) from up_zbx_ck_data where typeid=12)
    ORDER BY g_name, h_name;

# 13.SNMP不通的设备 <1秒
DROP VIEW IF EXISTS up_v_patrol_13;
CREATE VIEW up_v_patrol_13 AS
    SELECT g_name, h_name, h_description, h_maintenance_status, error, collect_time
    FROM up_zbx_ck_data d
    WHERE d.typeid=13 AND collect_time=(select max(collect_time) from up_zbx_ck_data where typeid=13)
    ORDER BY g_name, h_name;

# 14.IPMI不通的设备 <1秒
DROP VIEW IF EXISTS up_v_patrol_14;
CREATE VIEW up_v_patrol_14 AS
    SELECT g_name, h_name, h_description, h_maintenance_status, error, collect_time
    FROM up_zbx_ck_data d
    WHERE d.typeid=14 AND collect_time=(select max(collect_time) from up_zbx_ck_data where typeid=14)
    ORDER BY g_name, h_name;

# 15. 其它有问题监控项(只包含泰岳模板监控项) 120秒
DROP VIEW IF EXISTS up_v_patrol_15;
CREATE VIEW up_v_patrol_15 AS
    SELECT g_name, h_name, h_description, h_maintenance_status, i_name, i_key, error, collect_time
    FROM up_zbx_ck_data d
    WHERE d.typeid=15 AND collect_time=(select max(collect_time) from up_zbx_ck_data where typeid=15)
    ORDER BY g_name, h_name;

# 16.当前告警数量
DROP VIEW IF EXISTS up_v_patrol_16;
CREATE VIEW up_v_patrol_16 AS
    SELECT g_name, h_name, SUM(value) count, collect_time
    FROM up_zbx_ck_data d
    WHERE d.typeid=16 AND collect_time=(select max(collect_time) from up_zbx_ck_data where typeid=16)
    GROUP BY g_name, h_name
    ORDER BY count DESC;

# 17.自监控无数据的proxy
DROP VIEW IF EXISTS up_v_patrol_17;
CREATE VIEW up_v_patrol_17 AS
  SELECT g_name, h_name, p_name, FROM_UNIXTIME(p_lastaccess,"%Y-%m-%d %H:%I:%S") p_lastacces, value, collect_time
  FROM up_zbx_ck_data d
  WHERE d.typeid=17 AND value IS NULL AND collect_time=(select max(collect_time) from up_zbx_ck_data where typeid=17)
  ORDER BY g_name, h_name;


########### 从汇聚后视图查看云视部+综调语句 #############
# 1.停用设备 <1秒
select * from up_v_patrol_01 where g_name IN ('行业云平台（常州）','行业云平台（淮安）','行业云平台（连云港）','行业云平台（南通）','行业云平台（苏州）','行业云平台（泰州）','行业云平台（无锡）','行业云平台（宿迁）','行业云平台（徐州）','行业云平台（盐城）','行业云平台（扬州）','行业云平台（镇江）','南京IDC云平台','南京云桌面二期-服务器-WINDOWS','南京云桌面二期-硬件服务器','业务云SDN二长节点','业务云SDN长乐路节点','业务云二长7楼KVM集群','业务云公信大数据平台（公信集成项目）','业务云公信分布式存储（公信集成项目）','业务云平台（二长6楼）','业务云平台(二长7楼)','业务云平台(长乐路3楼)','业务云平台SDN(公信集成项目)','云资源综合支撑系统（行业云版）','云资源综合支撑系统（业务云版）','桌面云','综调系统')
ORDER BY g_name, h_name;
# 2.超过60秒没有数据的proxy <1秒
select * from up_v_patrol_02;
# 3.proxy失联导致无数据的主机 <1秒
select * from up_v_patrol_03 where g_name IN ('行业云平台（常州）','行业云平台（淮安）','行业云平台（连云港）','行业云平台（南通）','行业云平台（苏州）','行业云平台（泰州）','行业云平台（无锡）','行业云平台（宿迁）','行业云平台（徐州）','行业云平台（盐城）','行业云平台（扬州）','行业云平台（镇江）','南京IDC云平台','南京云桌面二期-服务器-WINDOWS','南京云桌面二期-硬件服务器','业务云SDN二长节点','业务云SDN长乐路节点','业务云二长7楼KVM集群','业务云公信大数据平台（公信集成项目）','业务云公信分布式存储（公信集成项目）','业务云平台（二长6楼）','业务云平台(二长7楼)','业务云平台(长乐路3楼)','业务云平台SDN(公信集成项目)','云资源综合支撑系统（行业云版）','云资源综合支撑系统（业务云版）','桌面云','综调系统')
ORDER BY g_name, h_name;
# 4.未监控的proxy <1秒
select * from up_v_patrol_04 ORDER BY p_name, h_name;

# 5.ping不通的设备
select * from up_v_patrol_05 where g_name IN ('行业云平台（常州）','行业云平台（淮安）','行业云平台（连云港）','行业云平台（南通）','行业云平台（苏州）','行业云平台（泰州）','行业云平台（无锡）','行业云平台（宿迁）','行业云平台（徐州）','行业云平台（盐城）','行业云平台（扬州）','行业云平台（镇江）','南京IDC云平台','南京云桌面二期-服务器-WINDOWS','南京云桌面二期-硬件服务器','业务云SDN二长节点','业务云SDN长乐路节点','业务云二长7楼KVM集群','业务云公信大数据平台（公信集成项目）','业务云公信分布式存储（公信集成项目）','业务云平台（二长6楼）','业务云平台(二长7楼)','业务云平台(长乐路3楼)','业务云平台SDN(公信集成项目)','云资源综合支撑系统（行业云版）','云资源综合支撑系统（业务云版）','桌面云','综调系统')
ORDER BY g_name, h_name;

# 6.没有对ping进行监控的设备(没有加载ping监控模板) 2秒
select * from up_v_patrol_06 where g_name IN ('行业云平台（常州）','行业云平台（淮安）','行业云平台（连云港）','行业云平台（南通）','行业云平台（苏州）','行业云平台（泰州）','行业云平台（无锡）','行业云平台（宿迁）','行业云平台（徐州）','行业云平台（盐城）','行业云平台（扬州）','行业云平台（镇江）','南京IDC云平台','南京云桌面二期-服务器-WINDOWS','南京云桌面二期-硬件服务器','业务云SDN二长节点','业务云SDN长乐路节点','业务云二长7楼KVM集群','业务云公信大数据平台（公信集成项目）','业务云公信分布式存储（公信集成项目）','业务云平台（二长6楼）','业务云平台(二长7楼)','业务云平台(长乐路3楼)','业务云平台SDN(公信集成项目)','云资源综合支撑系统（行业云版）','云资源综合支撑系统（业务云版）','桌面云','综调系统')
ORDER BY g_name, h_name;

# 7.ping无数据(加载了ping监控模板，但没有正常获取到数据)
select * from up_v_patrol_07 where g_name IN ('行业云平台（常州）','行业云平台（淮安）','行业云平台（连云港）','行业云平台（南通）','行业云平台（苏州）','行业云平台（泰州）','行业云平台（无锡）','行业云平台（宿迁）','行业云平台（徐州）','行业云平台（盐城）','行业云平台（扬州）','行业云平台（镇江）','南京IDC云平台','南京云桌面二期-服务器-WINDOWS','南京云桌面二期-硬件服务器','业务云SDN二长节点','业务云SDN长乐路节点','业务云二长7楼KVM集群','业务云公信大数据平台（公信集成项目）','业务云公信分布式存储（公信集成项目）','业务云平台（二长6楼）','业务云平台(二长7楼)','业务云平台(长乐路3楼)','业务云平台SDN(公信集成项目)','云资源综合支撑系统（行业云版）','云资源综合支撑系统（业务云版）','桌面云','综调系统')
ORDER BY g_name, h_name;


# 8.agent不通的设备 <1秒
select * from up_v_patrol_08 where g_name IN ('行业云平台（常州）','行业云平台（淮安）','行业云平台（连云港）','行业云平台（南通）','行业云平台（苏州）','行业云平台（泰州）','行业云平台（无锡）','行业云平台（宿迁）','行业云平台（徐州）','行业云平台（盐城）','行业云平台（扬州）','行业云平台（镇江）','南京IDC云平台','南京云桌面二期-服务器-WINDOWS','南京云桌面二期-硬件服务器','业务云SDN二长节点','业务云SDN长乐路节点','业务云二长7楼KVM集群','业务云公信大数据平台（公信集成项目）','业务云公信分布式存储（公信集成项目）','业务云平台（二长6楼）','业务云平台(二长7楼)','业务云平台(长乐路3楼)','业务云平台SDN(公信集成项目)','云资源综合支撑系统（行业云版）','云资源综合支撑系统（业务云版）','桌面云','综调系统')
ORDER BY g_name, h_name;

# 9.没有监控agent状态的主机(未配置Template Zabbix Agent模板) <1秒
select * from up_v_patrol_09 where g_name IN ('行业云平台（常州）','行业云平台（淮安）','行业云平台（连云港）','行业云平台（南通）','行业云平台（苏州）','行业云平台（泰州）','行业云平台（无锡）','行业云平台（宿迁）','行业云平台（徐州）','行业云平台（盐城）','行业云平台（扬州）','行业云平台（镇江）','南京IDC云平台','南京云桌面二期-服务器-WINDOWS','南京云桌面二期-硬件服务器','业务云SDN二长节点','业务云SDN长乐路节点','业务云二长7楼KVM集群','业务云公信大数据平台（公信集成项目）','业务云公信分布式存储（公信集成项目）','业务云平台（二长6楼）','业务云平台(二长7楼)','业务云平台(长乐路3楼)','业务云平台SDN(公信集成项目)','云资源综合支撑系统（行业云版）','云资源综合支撑系统（业务云版）','桌面云','综调系统')
ORDER BY g_name, h_name;

# 10.配了agent模板没有数据的 60秒
select * from up_v_patrol_10 where g_name IN ('行业云平台（常州）','行业云平台（淮安）','行业云平台（连云港）','行业云平台（南通）','行业云平台（苏州）','行业云平台（泰州）','行业云平台（无锡）','行业云平台（宿迁）','行业云平台（徐州）','行业云平台（盐城）','行业云平台（扬州）','行业云平台（镇江）','南京IDC云平台','南京云桌面二期-服务器-WINDOWS','南京云桌面二期-硬件服务器','业务云SDN二长节点','业务云SDN长乐路节点','业务云二长7楼KVM集群','业务云公信大数据平台（公信集成项目）','业务云公信分布式存储（公信集成项目）','业务云平台（二长6楼）','业务云平台(二长7楼)','业务云平台(长乐路3楼)','业务云平台SDN(公信集成项目)','云资源综合支撑系统（行业云版）','云资源综合支撑系统（业务云版）','桌面云','综调系统')
ORDER BY g_name, h_name;

# 11.SSH无法登录的设备 1秒
select * from up_v_patrol_11 where g_name IN ('行业云平台（常州）','行业云平台（淮安）','行业云平台（连云港）','行业云平台（南通）','行业云平台（苏州）','行业云平台（泰州）','行业云平台（无锡）','行业云平台（宿迁）','行业云平台（徐州）','行业云平台（盐城）','行业云平台（扬州）','行业云平台（镇江）','南京IDC云平台','南京云桌面二期-服务器-WINDOWS','南京云桌面二期-硬件服务器','业务云SDN二长节点','业务云SDN长乐路节点','业务云二长7楼KVM集群','业务云公信大数据平台（公信集成项目）','业务云公信分布式存储（公信集成项目）','业务云平台（二长6楼）','业务云平台(二长7楼)','业务云平台(长乐路3楼)','业务云平台SDN(公信集成项目)','云资源综合支撑系统（行业云版）','云资源综合支撑系统（业务云版）','桌面云','综调系统')
ORDER BY g_name, h_name;

# 12.未配置SSH连接监控的设备(没有配置监控模板) <1秒
select * from up_v_patrol_12 where g_name IN ('行业云平台（常州）','行业云平台（淮安）','行业云平台（连云港）','行业云平台（南通）','行业云平台（苏州）','行业云平台（泰州）','行业云平台（无锡）','行业云平台（宿迁）','行业云平台（徐州）','行业云平台（盐城）','行业云平台（扬州）','行业云平台（镇江）','南京IDC云平台','南京云桌面二期-服务器-WINDOWS','南京云桌面二期-硬件服务器','业务云SDN二长节点','业务云SDN长乐路节点','业务云二长7楼KVM集群','业务云公信大数据平台（公信集成项目）','业务云公信分布式存储（公信集成项目）','业务云平台（二长6楼）','业务云平台(二长7楼)','业务云平台(长乐路3楼)','业务云平台SDN(公信集成项目)','云资源综合支撑系统（行业云版）','云资源综合支撑系统（业务云版）','桌面云','综调系统')
ORDER BY g_name, h_name;

# 13.SNMP不通的设备 <1秒
select * from up_v_patrol_13 where g_name IN ('行业云平台（常州）','行业云平台（淮安）','行业云平台（连云港）','行业云平台（南通）','行业云平台（苏州）','行业云平台（泰州）','行业云平台（无锡）','行业云平台（宿迁）','行业云平台（徐州）','行业云平台（盐城）','行业云平台（扬州）','行业云平台（镇江）','南京IDC云平台','南京云桌面二期-服务器-WINDOWS','南京云桌面二期-硬件服务器','业务云SDN二长节点','业务云SDN长乐路节点','业务云二长7楼KVM集群','业务云公信大数据平台（公信集成项目）','业务云公信分布式存储（公信集成项目）','业务云平台（二长6楼）','业务云平台(二长7楼)','业务云平台(长乐路3楼)','业务云平台SDN(公信集成项目)','云资源综合支撑系统（行业云版）','云资源综合支撑系统（业务云版）','桌面云','综调系统')
ORDER BY g_name, h_name;

# 14.IPMI不通的设备 <1秒
select * from up_v_patrol_14 where g_name IN ('行业云平台（常州）','行业云平台（淮安）','行业云平台（连云港）','行业云平台（南通）','行业云平台（苏州）','行业云平台（泰州）','行业云平台（无锡）','行业云平台（宿迁）','行业云平台（徐州）','行业云平台（盐城）','行业云平台（扬州）','行业云平台（镇江）','南京IDC云平台','南京云桌面二期-服务器-WINDOWS','南京云桌面二期-硬件服务器','业务云SDN二长节点','业务云SDN长乐路节点','业务云二长7楼KVM集群','业务云公信大数据平台（公信集成项目）','业务云公信分布式存储（公信集成项目）','业务云平台（二长6楼）','业务云平台(二长7楼)','业务云平台(长乐路3楼)','业务云平台SDN(公信集成项目)','云资源综合支撑系统（行业云版）','云资源综合支撑系统（业务云版）','桌面云','综调系统')
ORDER BY g_name, h_name;

# 15. 其它有问题监控项(只包含泰岳模板监控项)
select * from up_v_patrol_15 where g_name IN ('行业云平台（常州）','行业云平台（淮安）','行业云平台（连云港）','行业云平台（南通）','行业云平台（苏州）','行业云平台（泰州）','行业云平台（无锡）','行业云平台（宿迁）','行业云平台（徐州）','行业云平台（盐城）','行业云平台（扬州）','行业云平台（镇江）','南京IDC云平台','南京云桌面二期-服务器-WINDOWS','南京云桌面二期-硬件服务器','业务云SDN二长节点','业务云SDN长乐路节点','业务云二长7楼KVM集群','业务云公信大数据平台（公信集成项目）','业务云公信分布式存储（公信集成项目）','业务云平台（二长6楼）','业务云平台(二长7楼)','业务云平台(长乐路3楼)','业务云平台SDN(公信集成项目)','云资源综合支撑系统（行业云版）','云资源综合支撑系统（业务云版）','桌面云','综调系统')
ORDER BY g_name, h_name;

# 16. 当前告警数量
select * from up_v_patrol_16 where g_name IN ('行业云平台（常州）','行业云平台（淮安）','行业云平台（连云港）','行业云平台（南通）','行业云平台（苏州）','行业云平台（泰州）','行业云平台（无锡）','行业云平台（宿迁）','行业云平台（徐州）','行业云平台（盐城）','行业云平台（扬州）','行业云平台（镇江）','南京IDC云平台','南京云桌面二期-服务器-WINDOWS','南京云桌面二期-硬件服务器','业务云SDN二长节点','业务云SDN长乐路节点','业务云二长7楼KVM集群','业务云公信大数据平台（公信集成项目）','业务云公信分布式存储（公信集成项目）','业务云平台（二长6楼）','业务云平台(二长7楼)','业务云平台(长乐路3楼)','业务云平台SDN(公信集成项目)','云资源综合支撑系统（行业云版）','云资源综合支撑系统（业务云版）','桌面云')
ORDER BY count DESC, g_name, h_name;



