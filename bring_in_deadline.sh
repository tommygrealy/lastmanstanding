#!/bin/bash

# Set MySQL connection details
DB_HOST="localhost"
DB_USER="root"
DB_PASS=$(pass mysql_root)
DB_NAME="lastmanstanding"

# Run the SQL commands
mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF
SET @gw := (
  SELECT GameWeek 
  FROM gameweekmap 
  WHERE DateFrom > NOW() 
  ORDER BY DateFrom 
  LIMIT 1
);

UPDATE gameweekmap 
SET DateFrom = NOW() 
WHERE GameWeek = @gw;
EOF
