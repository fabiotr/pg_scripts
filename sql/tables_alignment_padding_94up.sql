--[EXP] Alignment padding: how many bytes can be saved if columns are reordered?

-- TODO: not-yet-analyzed tables – show a warning (cannot get n_live_tup -> cannot get total bytes)
-- TODO: NULLs
-- TODO: simplify, cleanup
-- TODO: chunk_size 4 or 8
WITH recursive constants AS (
  SELECT 8 AS chunk_size
), columns AS (
  SELECT
    TRUE AS is_orig,
    table_schema,
    table_name,
    ordinal_position,
    column_name,
    udt_name,
    typalign,
    typlen,
    CASE typalign -- see https://www.postgresql.org/docs/current/static/catalog-pg-type.html
      WHEN 'c' THEN
        CASE WHEN typlen > 0 THEN typlen % chunk_size ELSE 0 END
      WHEN 's' THEN 2
      WHEN 'i' THEN 4
      WHEN 'd' THEN 8
      ELSE NULL
    END AS _shift,
    CASE typalign
      WHEN 's' THEN 1
      WHEN 'i' THEN 2
      WHEN 'd' THEN 3
      WHEN 'c' THEN
        CASE WHEN typlen > 0 THEN typlen % chunk_size ELSE 9 END
      ELSE 9
    END AS alt_order_group,
    character_maximum_length
  FROM information_schema.columns
  JOIN constants ON TRUE
  JOIN pg_type ON udt_name = typname
  WHERE table_schema NOT IN ('information_schema', 'pg_catalog')
), alt_columns AS (
  SELECT
    FALSE AS is_orig,
    table_schema,
    table_name,
    row_number() over (partition by table_schema, table_name ORDER BY alt_order_group, column_name) AS ordinal_position,
    column_name,
    udt_name,
    typalign,
    typlen,
    _shift,
    alt_order_group,
    character_maximum_length
  FROM columns
), combined_columns AS (
  SELECT *, coalesce(character_maximum_length, _shift) AS shift
  FROM columns
  UNION ALL
  SELECT *, coalesce(character_maximum_length, _shift) AS shift
  FROM alt_columns
), analyze_alignment AS (
  SELECT
    is_orig,
    table_schema,
    table_name,
    0 AS analyzed,
    (SELECT chunk_size FROM constants) AS left_in_chunk,
    '{}'::text[] COLLATE "C" AS padded_columns,
    '{}'::int[] AS pads,
    (SELECT max(ordinal_position) FROM columns c WHERE c.table_name = _.table_name AND c.table_schema = _.table_schema) AS col_cnt,
    array_agg(_.column_name::text ORDER BY ordinal_position) AS cols,
    array_agg(_.udt_name::text ORDER BY ordinal_position) AS types,
    array_agg(shift ORDER BY ordinal_position) AS shifts,
    NULL::int AS curleft,
    NULL::text COLLATE "C" AS prev_column_name,
    FALSE AS has_varlena
  FROM
    combined_columns _
  GROUP BY is_orig, table_schema, table_name
  UNION ALL
  SELECT
    is_orig,
    table_schema,
    table_name,
    analyzed + 1,
    cur_left_in_chunk,
    CASE WHEN padding_occurred > 0 THEN padded_columns || ARRAY[prev_column_name] ELSE padded_columns END,
    CASE WHEN padding_occurred > 0 THEN pads || ARRAY[padding_occurred] ELSE pads END,
    col_cnt,
    cols,
    types,
    shifts,
    cur_left_in_chunk,
    ext.column_name AS prev_column_name,
    a.has_varlena OR (ext.typlen = -1) -- see https://www.postgresql.org/docs/current/static/catalog-pg-type.html
  FROM analyze_alignment a, constants, LATERAL (
    SELECT
      shift,
      CASE WHEN left_in_chunk < shift THEN left_in_chunk ELSE 0 END AS padding_occurred,
      CASE WHEN left_in_chunk < shift THEN chunk_size - shift % chunk_size ELSE left_in_chunk - shift END AS cur_left_in_chunk,
      column_name,
      typlen
    FROM combined_columns c, constants
    WHERE
      ordinal_position = a.analyzed + 1
      AND c.is_orig = a.is_orig
      AND c.table_name = a.table_name
      AND c.table_schema = a.table_schema
  ) AS ext
  WHERE
    analyzed < col_cnt AND analyzed < 1000/*sanity*/
), result_pre AS (
  SELECT DISTINCT ON (is_orig, table_schema, table_name)
    is_orig ,
    table_schema AS schema_name,
    table_name,
    padded_columns,
    CASE WHEN curleft % chunk_size > 0 THEN pads || ARRAY[curleft] ELSE pads END AS pads,
    curleft,
    coalesce((SELECT sum(p) FROM unnest(pads) _(p)), 0) + (chunk_size + a1.curleft) % chunk_size AS padding_sum,
    n_live_tup,
    n_dead_tup,
    c.oid AS oid,
    pg_total_relation_size(c.oid) - pg_indexes_size(c.oid) - coalesce(pg_total_relation_size(reltoastrelid), 0) AS table_bytes,
    cols,
    types,
    shifts,
    analyzed,
    a1.has_varlena
  FROM analyze_alignment a1
  JOIN pg_namespace n ON n.nspname = table_schema
  JOIN pg_class c ON n.oid = c.relnamespace AND c.relname = table_name
  JOIN pg_stat_user_tables s ON s.schemaname = table_schema AND s.relname = table_name
  JOIN constants ON TRUE
  ORDER BY is_orig, table_schema, table_name, analyzed DESC
), result_both AS (
  SELECT
    *,
    padding_sum * (n_live_tup + n_dead_tup) AS padding_total_est
  FROM result_pre
), result AS (
  SELECT
    r1.schema_name,
    r1.table_name,
    r1.table_bytes,
    r1.n_live_tup,
    r1.n_dead_tup,
    r1.padding_total_est - coalesce(r2.padding_total_est, 0) AS padding_total_est,
    r1.padding_sum - coalesce(r2.padding_sum, 0) AS padding_sum,
    r1.padding_sum AS r1_padding_sum,
    r1.padding_total_est AS r1_padding_total_est,
    r2.padding_sum AS r2_padding_sum,
    r2.padding_total_est AS r2_padding_total_est,
    r1.cols,
    r1.types,
    r1.shifts,
    r2.cols AS alt_cols,
    r2.types AS alt_types,
    r2.shifts AS alt_shifts,
    r1.pads,
    r1.curleft,
    r2.pads AS alt_pads,
    r2.curleft AS alt_curleft,
    r1.padded_columns,
    r1.analyzed,
    r1.has_varlena,
    CASE
      WHEN r1.table_bytes > 0 THEN
        round(100 * (r1.padding_sum - coalesce(r2.padding_sum, 0))::numeric * (r1.n_live_tup + r1.n_dead_tup)::numeric / r1.table_bytes, 2)
      ELSE 0
    END AS wasted_percent
  FROM result_both r1
  JOIN result_both r2 ON r1.is_orig AND NOT r2.is_orig AND r1.schema_name = r2.schema_name AND r1.table_name = r2.table_name
)
SELECT
  coalesce(nullif(schema_name, 'public') || '.', '') || table_name AS "Table",
  pg_size_pretty(table_bytes) "Table Size",
  CASE WHEN has_varlena THEN 'Includes VARLENA' ELSE NULL END AS "Comment",
  CASE
    WHEN padding_total_est > 0 THEN '~' || pg_size_pretty(padding_total_est) || ' (' || wasted_percent::text || '%)'
    ELSE ''
  END AS "Wasted *",
  CASE
    WHEN padding_total_est > 0 THEN (
      WITH cols1(c) AS (
        SELECT array_to_string(array_agg(elem::text), ', ')
        FROM (SELECT * FROM unnest(alt_cols) WITH ordinality AS __(elem, i)) _
        GROUP BY (i - 1) / 3
        ORDER BY (i - 1) / 3
      )
      SELECT array_to_string(array_agg(c), e'\n') FROM cols1
    )
    ELSE NULL
  END AS "Suggested Columns Reorder"
  --case when padding_total_est > 0 then array_to_string(alt_cols, ', ') else null end as "Suggested Columns Reorder"
FROM result r1
ORDER BY table_bytes DESC
;


