#!/bin/bash

kadi db init
kadi search init
service apache2 start
uwsgi /etc/kadi-uwsgi.ini