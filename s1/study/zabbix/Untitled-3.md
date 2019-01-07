1. zabbix北京和月报中数量对不上，分组数量对不上，
2. 北京监控总数还差很多15（630-615(共626除去11台前置)） 
3. 前置35台，实际监控11台
4. SSM僵死
5. 11.21早统一认证无法登录，数据库报错ORA-00257
6. 统一认证数据库，大客户网管数据库监控
7. 北京zabbix扩容
8. 监控停用
9. 监控hdfs文件数量
10. 上海的蓝鲸agent都被删掉了
11. hadoop客户端安装脚本
12. hadoop客户端hosts文件更新

zabbix规范

# 监控准则

# 部署架构图-齐柏涵
图
表：功能|主机名|ip|VIP|

# server端
# 高可用
## 实现方式
server采用主备方式(keepalived)，mysql采用1主3从
## 
|应用|ip地址|部署路径|启动|停止|
|zabbix server|x.x.x.x|/xxxxx|xxx|xxxxx|
|zabbix server|x.x.x.x|/xxxxx|xxx|xxxxx|
|keepalived|x.x.x.x|/xxxxx|xxx|xxxxx|
|keepalived|x.x.x.x|/xxxxx|xxx|xxxxx|

## 短信、邮件
齐柏涵-短信、邮件网络打通
齐柏涵-短信、邮件脚本迁移调试

## 模板
1.模板名称


## 主机组
1.主机组名称
省份-节点-系统名称-模块名称
如：内蒙-
内蒙-A节点
内蒙-B节点
北京-亦庄
北京-昌平
上海-B14A
上海-B12A

## 自动注册规则
梅花镇

## 触发器规则
齐柏涵


# proxy端
部署：内蒙a、昌平及vip申请(明瑞)
王杰明瑞-利旧打通网络：内蒙b、亦庄、上海a、上海b


# agent端
梅花镇-linux agent部署步骤











