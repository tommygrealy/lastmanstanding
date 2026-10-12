#!/bin/bash

# Copy production database to development database

# Load environment variables from .env file
set -a
source ./.env
set +a

if [ -z "$LMS_DB_PASSWORD_ROOT" ]; then
  echo "Error: environment variable LMS_DB_PASSWORD_ROOT is not set or is empty"
  echo "run 'pass mysql_root' and set LMS_DB_PASSWORD_ROOT to the result"
  exit 1
else
  echo "LMS_DB_PASSWORD_ROOT is set"
fi
mysqldump -u root -p${LMS_DB_PASSWORD_ROOT} --databases lastmanstanding --add-drop-database --complete-insert --routines --triggers --events --add-drop-table --create-options > /home/tgrealy/mydatabase_backup.sql
if [ $? -ne 0 ]; then
  echo "Error: mysqldump command for source DB failed"
  exit 1
else
  echo "mysqldump of SOURCE DB completed successfully"
fi 

#CHANGE DB NAME TO DEV
sed -i 's/lastmanstanding/lastmanstanding-dev/g' ~/mydatabase_backup.sql
if [ $? -ne 0 ]; then
  echo "Error: SED command failed"
  exit 1
else
  echo "DB export file edits completed"
fi 

mysql -u root -p${LMS_DB_PASSWORD_ROOT} < ~/mydatabase_backup.sql
if [ $? -ne 0 ]; then
  echo "Error: DB import of mydatabase_backup.sql failed"
  exit 1
else
  echo "DB import was successful"
fi
