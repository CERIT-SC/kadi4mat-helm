FROM python:3.13.2-bookworm

ENV PYTHON_INTERPRETER=${1:-python3}

ENV KADI_USER="kadi"
ENV KADI_GROUP="kadi"
ENV KADI_HOME="/opt/kadi"
ENV KADI_CONFIG_FILE="${KADI_HOME}/config/kadi.py"

# TODO: fix to generate kadi config with this in mind
ENV SERVER_NAME = "127.0.0.1"

ENV APACHE_CONFIG_FILE="/etc/apache2/sites-available/kadi.conf"
ENV CERT_FILE="/etc/ssl/certs/kadi.crt"
ENV KEY_FILE="/etc/ssl/private/kadi.key"

RUN set -xe \
    && apt-get update -y \
    && apt-get install -y python3-pip

RUN apt install libmagic1 build-essential  \
libpq-dev libpcre3-dev apache2 libapache2-mod-proxy-uwsgi libapache2-mod-xsendfile -y

RUN adduser kadi --system --group --home /opt/kadi --shell /bin/bash \
&& usermod -a -G kadi www-data


RUN pip install kadi

# Kadi config --------

# TODO change to generating during build from args
COPY kadi.py /tmp/kadi.py
RUN KADI_CONFIG_FILE=${KADI_HOME}/config/kadi.py && mkdir ${KADI_HOME}/config \
&& mv /tmp/kadi.py ${KADI_HOME}/config/kadi.py && chown kadi ${KADI_HOME}/config/kadi.py

# uWSGI -------------
ENV UWSGI_CONFIG_FILE="/etc/kadi-uwsgi.ini"

RUN kadi utils uwsgi --default --out ${KADI_HOME}/kadi-uwsgi.ini \
  && mv ${KADI_HOME}/kadi-uwsgi.ini /etc/ \
  && chown root:root ${UWSGI_CONFIG_FILE}

# Apache ----------
RUN openssl req -x509 -nodes -days 365 -newkey rsa:4096 -keyout ${KEY_FILE} -out ${CERT_FILE} \
-subj "/CN=${SERVER_NAME}" -addext "subjectAltName=DNS:${SERVER_NAME}"

RUN yes y | kadi utils apache --default --out ${KADI_HOME}/kadi.conf \
    && mv ${KADI_HOME}/kadi.conf /etc/apache2/sites-available/ \
    && chown root:root ${APACHE_CONFIG_FILE}

RUN a2dissite 000-default \
    && a2ensite kadi \
    && a2enmod deflate headers http2 proxy_uwsgi socache_shmcb ssl xsendfile

# Create log and run folders
RUN mkdir /var/log/uwsgi && chown kadi /var/log/uwsgi \
&& mkdir /var/log/celery /run/celery && chown kadi /var/log/celery /run/celery 

# Set logrotate for uwsgi an celery
RUN echo -e "/var/log/uwsgi/*.log {\n  copytruncate\n  compress\n  delaycompress\n  missingok\n  notifempty\n  rotate 10\n  weekly\n}" > /etc/logrotate.d/uwsgi \
&& echo -e "/var/log/celery/*.log {\n  copytruncate\n  compress\n  delaycompress\n  missingok\n  notifempty\n  rotate 10\n  weekly\n}" > /etc/logrotate.d/celery

COPY ./docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]