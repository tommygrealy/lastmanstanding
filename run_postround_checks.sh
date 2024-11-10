#!/bin/bash
now=$(date +"%Y-%m-%d %H:%M:%S")
export LMS_PASS=$(pass lms)
export RUN_ENVIRON=PROD
export logfile=/home/tgrealy/postround_cronjob.txt
echo "${now} post round checks triggered by cron" > $logfile
cd /home/tgrealy/workspace/lastmanstanding/py/
source venv/bin/activate
python runPostRoundResultCheck.py >> $logfile
deactivate