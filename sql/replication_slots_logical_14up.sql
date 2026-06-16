\if :svp_not_rds
  \if :svp_not_gcp
    SELECT 
      slot_name AS "Replication Slot",
      lpad(to_char(spill_txns::numeric    / reset_days,'FM9999G990'),7) AS "Spill TX/Day", 
      lpad(to_char(spill_count::numeric   / reset_days,'FM9999G990'),7) AS "Spill count/Day", 
      lpad(pg_size_pretty(round(spill_bytes::numeric  / reset_days)),8) AS "Spill size/Day" ,
      lpad(to_char(stream_txns::numeric   / reset_days,'FM9999G990'),7) AS "Stream TX/Day", 
      lpad(to_char(stream_count::numeric  / reset_days,'FM9999G990'),7) AS "Stream count/Day", 
      lpad(pg_size_pretty(round(stream_bytes::numeric / reset_days)),8) AS "Stream size/Day",
      lpad(pg_size_pretty(round(total_bytes::numeric  / reset_days)),8) AS "Total size/Day",
      date_trunc('second', current_timestamp - stats_reset)             AS "Age"
    FROM (SELECT *, (EXTRACT(EPOCH FROM current_timestamp - stats_reset) / (60*60*24)) AS reset_days FROM pg_stat_replication_slots) AS rs
    ORDER BY 1;
  \else
    SELECT 
      slot_name AS "Replication Slot",
      lpad(to_char(spill_txns, 'FM9999G990'),7)  AS "Spill TX", 
      lpad(to_char(spill_count,'FM9999G990'),7)  AS "Spill count", 
      lpad(pg_size_pretty(spill_bytes),8)        AS "Spill size" ,
      lpad(to_char(stream_txns,'FM9999G990'),7)  AS "Stream TX", 
      lpad(to_char(stream_count,'FM9999G990'),7) AS "Stream count", 
      lpad(pg_size_pretty(stream_bytes),8)       AS "Stream size",
      lpad(pg_size_pretty(total_bytes),8)        AS "Total size"
    FROM  pg_stat_replication_slots
    ORDER BY 1;
  \endif
\else
  SELECT 
    slot_name AS "Replication Slot",
    lpad(to_char(spill_txns,'FM9999G990'),7)   AS "Spill TX", 
    lpad(to_char(spill_count,'FM9999G990'),7)  AS "Spill count", 
    lpad(pg_size_pretty(spill_bytes),8)        AS "Spill size" ,
    lpad(to_char(stream_txns,'FM9999G990'),7)  AS "Stream TX", 
    lpad(to_char(stream_count,'FM9999G990'),7) AS "Stream count", 
    lpad(pg_size_pretty(stream_bytes),8)       AS "Stream size",
    lpad(pg_size_pretty(total_bytes),8)        AS "Total size"
  FROM  pg_stat_replication_slots
  ORDER BY 1;
