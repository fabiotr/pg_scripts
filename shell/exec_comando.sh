#!/bin/env bash

# Find psql binary location
PSQL=$(which psql)
PSQL_OPTS=(-t -c)

#Run psql and execute SQL that returns the list of existing databases
function list_db_names () {
  "$PSQL" "$PSQL_OPTS" "SELECT datname FROM pg_database WHERE datname !='postgres' AND datistemplate = FALSE"
}

## Iterates over the database list and runs comando.sql against each database
PSQL_OPTS=(-t -f)
list_db_names | while read LINHA; do "$PSQL" "$PSQL_OPTS" comando.sql "$LINHA"; done
