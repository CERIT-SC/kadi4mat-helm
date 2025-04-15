#!/bin/bash

kadi db init
sh -c "sleep 30 && kadi search init" &

kadi celery worker --loglevel=INFO --logfile=/var/log/celery/celery.log &
kadi celery beat --loglevel=INFO --logfile=/var/log/celery/celerybeat.log -s /run/celery/beat-schedule &

uwsgi ${KADI_HOME}/kadi-uwsgi.ini &
/usr/sbin/apache2ctl -D FOREGROUND