#!/bin/sh
export INSTANCE_IDENTIFIER=db_name_identifier
export LOGS_DESTINATION=/mnt/logs

for filename in $( aws rds describe-db-log-files --db-instance-identifier $INSTANCE_IDENTIFIER | jq -r '.DescribeDBLogFiles[] | .LogFileName' )
do
aws rds download-db-log-file-portion --db-instance-identifier $INSTANCE_IDENTIFIER  --starting-token 0 --output text  --log-file-name $filename  >> $LOGS_DESTINATION/$filename
done
