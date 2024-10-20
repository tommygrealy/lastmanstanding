#!/bin/bash
if [ -z "$MYSQL_LMS_PASS" ]; then
  echo "Error: environment variable MYSQL_LMS_PASS is not set or is empty"
  exit 1
else
  echo "MYSQL_LMS_PASS is set"
fi
mysqldump -u root -p${MYSQL_LMS_PASS} --databases lastmanstanding --add-drop-database --complete-insert --routines --triggers --events --add-drop-table --create-options > /home/tgrealy/mydatabase_backup.sql
if [ $? -ne 0 ]; then
  echo "Error: mysqldump command for source DB failed"
  exit 1
else
  echo "mysqldump of SOURCE DB completed successfully"
fi 

CHANGE DB NAME TO DEV
sed -i 's/lastmanstanding/lastmanstanding-dev/g' ~/mydatabase_backup.sql
if [ $? -ne 0 ]; then
  echo "Error: SED command failed"
  exit 1
else
  echo "DB export file edits completed"
fi 

mysql -u root -p${MYSQL_LMS_PASS} < ~/mydatabase_backup.sql
if [ $? -ne 0 ]; then
  echo "Error: DB import of mydatabase_backup.sql failed"
  exit 1
else
  echo "DB import was successful"
fi
