\qecho
\qecho Metrics:
\qecho Until min age:      VACCUM has no effect on table age
\qecho Until table age:    VACCUM does a soft clean
\qecho Until max age:      VACCUM does an aggresive clean
\qecho Until failsafe age: VACCUM to prevent wraparound
\qecho Above failsafe age: VACCUM aggresive prevent wraparound
\qecho

\qecho Database Wraparound
\i vacuum_wraparound_database.sql
\qecho

\qecho Tables Wraparound
\i vacuum_wraparound_table.sql
\qecho

\qecho Tables Wraparound Multixact
\i vacuum_wraparound_table_multixact.sql
\qecho

\qecho Tables Maintenance Commands
\i vacuum_wraparound_table_clean.sql
