#!/usr/bin/env bash
set -euo pipefail

##
## Configure as variáveis abaixo ou exporte-as antes de chamar o script:
##   export INSTANCE_IDENTIFIER=meu-banco
##   export LOGS_DESTINATION=/mnt/logs
##

# Valida variáveis obrigatórias — aborta com mensagem clara se não definidas
: "${INSTANCE_IDENTIFIER:?Defina a variável INSTANCE_IDENTIFIER antes de executar}"
: "${LOGS_DESTINATION:?Defina a variável LOGS_DESTINATION antes de executar}"

mkdir -p "$LOGS_DESTINATION"

while IFS= read -r filename; do
    # Impede path traversal (ex: ../../etc/cron.d/evil)
    if [[ "$filename" == *..* ]]; then
        echo "AVISO: nome de arquivo suspeito ignorado: $filename" >&2
        continue
    fi

    dest="$LOGS_DESTINATION/$filename"
    mkdir -p "$(dirname "$dest")"

    echo "Baixando: $filename"

    marker="0"
    while true; do
        response=$(aws rds download-db-log-file-portion \
            --db-instance-identifier "$INSTANCE_IDENTIFIER" \
            --log-file-name "$filename" \
            --starting-token "$marker" \
            --output json)

        # Grava apenas o conteúdo do log, sem metadata JSON
        printf '%s' "$(jq -r '.LogFileData // ""' <<< "$response")" >> "$dest"

        # Verifica se há mais páginas
        marker=$(jq -r '.Marker // empty' <<< "$response")
        [[ -z "$marker" || "$marker" == "0" ]] && break
    done

done < <(aws rds describe-db-log-files \
    --db-instance-identifier "$INSTANCE_IDENTIFIER" \
    | jq -r '.DescribeDBLogFiles[].LogFileName')
