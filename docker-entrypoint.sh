#!/bin/bash

kadi db init
sh -c "sleep 30 && kadi search init" &

KADI_UID="$(id -u kadi)"
kadi celery worker --loglevel=INFO --logfile=/var/log/celery/celery.log --uid $KADI_UID &
kadi celery beat --loglevel=INFO --logfile=/var/log/celery/celerybeat.log -s /run/celery/beat-schedule --uid $KADI_UID &

uwsgi /etc/kadi-uwsgi.ini &
/usr/sbin/apache2ctl -D FOREGROUND