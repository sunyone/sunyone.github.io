SELECT
  g.name AS gname,
  h.name AS hname,
  h.description AS h_description,
  h.error AS error,
  h.maintenance_status AS h_maintenance_status
FROM
  groups g
  JOIN hosts_groups hg ON g.groupid = hg.groupid
  JOIN HOSTS h ON hg.hostid = h.hostid
WHERE
		h. STATUS = 0
  AND h.available = 1
  AND h.hostid NOT IN (
		SELECT i.hostid, i.itemid, avg(v. VALUE) VALUE
    FROM
      items i
      JOIN history_uint v ON i.itemid = v.itemid
    WHERE
			i.key_ = 'agent.ping' AND v.clock >= (UNIX_TIMESTAMP() - 400)
    GROUP BY i.hostid, i.itemid )