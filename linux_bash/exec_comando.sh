#!/bin/env bash

# Find psql binary location
PSQL=$(which psql)
LIST_OPTS=(-X -t -A -c)
RUN_OPTS=(-X -t -f)

#Run psql and execute SQL that returns the list of existing databases
function list_db_names () {
  "$PSQL" "${LIST_OPTS[@]}" "SELECT datname FROM pg_database WHERE datname !='postgres' AND datistemplate = FALSE"
}

## Iterates over the database list and runs comando.sql against each database.
## Empty lines are skipped: psql would treat an empty dbname as "the default
## database" and run comando.sql against 'postgres', which is meant to be
## excluded. psql's stdin is /dev/null so it can't consume the list.
list_db_names | while IFS= read -r LINHA; do
  [[ -z "$LINHA" ]] && continue
  "$PSQL" "${RUN_OPTS[@]}" comando.sql "$LINHA" < /dev/null
done
