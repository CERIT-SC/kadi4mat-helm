#!/bin/bash

[ ! -f "${KADI_HOME}/config/kadi.py" ] && cp /default-config/kadi.py ${KADI_HOME}/config/kadi.py
[ ! -f "${KADI_HOME}/kadi-uwsgi.ini" ] && cp /default-config/kadi-uwsgi.ini ${KADI_HOME}/kadi-uwsgi.ini
[ ! -f "/etc/apache2/sites-available/kadi.conf" ] && cp /default-config/kadi-apache.conf /etc/apache2/sites-enabled/kadi.conf

kadi db init
sh -c "sleep 30 && kadi search init" &

kadi celery worker --loglevel=INFO --logfile=/var/log/celery/celery.log &
kadi celery beat --loglevel=INFO --logfile=/var/log/celery/celerybeat.log -s /run/celery/beat-schedule &

uwsgi ${KADI_HOME}/kadi-uwsgi.ini &
/usr/sbin/apache2ctl -D FOREGROUND