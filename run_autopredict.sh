#!/bin/bash
now=$(date +"%Y-%m-%d %H:%M:%S")
export LMS_PASS=$(pass lms)
export RUN_ENVIRON=PROD
echo "${now} autopick triggered by cron" > /home/tgrealy/autopick_cronjob.txt
cd /home/tgrealy/workspace/lastmanstanding/py
source venv/bin/activate
python runAutoPicks.py >> /home/tgrealy/autopick_cronjob.txt
deactivate