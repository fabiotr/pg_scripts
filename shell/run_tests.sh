#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

CONTAINER_NAME="pg_scripts_test"
DB_USER="postgres"
DB_NAME="testdb"

echo "Checking for Docker container..."
if [ ! "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
    echo "Container $CONTAINER_NAME is not running."
    echo "Please start it with: docker compose up -d"
    exit 1
fi

echo "Running tests against $CONTAINER_NAME..."

SUCCESS_COUNT=0
FAIL_COUNT=0

# List scripts inside the container to ensure we rely on the mounted volume
FILES=$(docker exec $CONTAINER_NAME find /sql -name "*.sql" | sort)

for FILE in $FILES; do
    FILE_NAME=$(basename "$FILE")
    
    # Run psql inside the container
    # -v ON_ERROR_STOP=1 ensures psql returns an error code if the SQL fails
    OUTPUT=$(docker exec $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME -f "$FILE" -v ON_ERROR_STOP=1 2>&1)
    EXIT_CODE=$?

    if [ $EXIT_CODE -eq 0 ]; then
        echo -e "${GREEN}[PASS]${NC} $FILE_NAME"
        ((SUCCESS_COUNT++))
    else
        echo -e "${RED}[FAIL]${NC} $FILE_NAME"
        echo "---------------------------------------------------"
        echo "$OUTPUT"
        echo "---------------------------------------------------"
        ((FAIL_COUNT++))
    fi
done

echo ""
echo -e "Results: ${GREEN}$SUCCESS_COUNT Passed${NC}, ${RED}$FAIL_COUNT Failed${NC}"