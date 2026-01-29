#!/bin/bash

# Onde está meu PSQL
PSQL=$(which psql)
PSQL_OPTS=" -t -c "

#Executa SQL e retorna  lista dos bancos de dados existentes
function list_db_names () {
  $PSQL $PSQL_OPTS "SELECT datname from pg_database WHERE datname NOT IN ('postgres', 'template0', 'template1')"
}



## Itera sobre a lista em databases.sql e executa o script em comando.sql para cada base
list_db_names | while read LINHA; do psql -t -f comando.sql "$LINHA"; done