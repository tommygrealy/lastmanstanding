#!/bin/bash
now=$(date +"%Y-%m-%d %H:%M:%S")
export LMS_PASS=$(pass lms)
export RUN_ENVIRON=PROD
export logfile=/home/tgrealy/next_round_cronjob.txt
echo "${now} next round setup triggered by cron" > $logfile
cd /home/tgrealy/workspace/lastmanstanding/py/
source venv/bin/activate
python setupNextRound.py --round $1 >> $logfile
python placeDynamite.py --round $1 >> $logfile
deactivate
