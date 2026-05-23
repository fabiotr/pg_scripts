#!/bin/bash
# Run from the root of the pg_scripts repository
# Renames files with + in sql/ and updates \ir references inside all .sql files

set -e

#cd sql/

# Step 1: Update \ir and \i references inside all .sql files BEFORE renaming
echo "Updating \\ir/\\i references..."
for f in *.sql; do
    sed -i '' \
        -e '/^\\ir /s/_+_/_plus_/g' \
        -e '/^\\ir /s/_+\.sql/_plus.sql/g' \
        -e '/^\\ir /s/\([0-9][0-9]*\)+/\1up/g' \
        -e '/^\\i /s/_+_/_plus_/g' \
        -e '/^\\i /s/_+\.sql/_plus.sql/g' \
        -e '/^\\i /s/\([0-9][0-9]*\)+/\1up/g' \
        "$f"
done

# Step 2: Rename files with + in their names
echo "Renaming files..."
for f in *+*.sql; do
    newname=$(echo "$f" | sed \
        -e 's/_+_/_plus_/g' \
        -e 's/_+\.sql/_plus.sql/g' \
        -e 's/\([0-9][0-9]*\)+/\1up/g')
    if [ "$f" != "$newname" ]; then
        echo "  $f  ->  $newname"
        git mv "$f" "$newname"
    fi
done

echo ""
echo "Done! Review with: git diff HEAD && git status"
