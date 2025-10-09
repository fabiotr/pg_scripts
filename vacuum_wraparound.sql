\qecho
\qecho Metrics:
\qecho Until min age:      VACCUM has no effect on table age
\qecho Until table age:    VACCUM does a soft clean
\qecho Until max age:      VACCUM does an aggresive clean
\qecho Until failsafe age: VACCUM to prevent wraparound
\qecho Above failsafe age: VACCUM aggresive prevent wraparound
\qecho

\qecho Database Wraparound
\ir vacuum_wraparound_database.sql
\qecho

\qecho Tables Wraparound
\ir vacuum_wraparound_table.sql
\qecho

\qecho Tables Wraparound Multixact
\ir vacuum_wraparound_table_multixact.sql
\qecho

\qecho Tables Maintenance Commands
\ir vacuum_wraparound_table_clean.sql
