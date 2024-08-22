#!/bin/bash
ssh tgrealy@service.actionshots.ie "mysqldump lastmanstanding -uroot -pv37bRgOkM85HN6K" > ~/temp/mysql_lmsdump.sql
