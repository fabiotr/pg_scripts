#!/bin/env bash

# Find psql binary location
PSQL=$(which psql)
LIST_OPTS=(-t -c)
RUN_OPTS=(-t -f)

#Run psql and execute SQL that returns the list of existing databases
function list_db_names () {
  "$PSQL" "${LIST_OPTS[@]}" "SELECT datname FROM pg_database WHERE datname !='postgres' AND datistemplate = FALSE"
}

## Iterates over the database list and runs comando.sql against each database
list_db_names | while read LINHA; do "$PSQL" "${RUN_OPTS[@]}" comando.sql "$LINHA"; done
