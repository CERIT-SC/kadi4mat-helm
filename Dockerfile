FROM python:3.13.2-bookworm

ENV PYTHON_INTERPRETER=${1:-python3}

ENV KADI_USER="kadi"
ENV KADI_GROUP="kadi"
ENV KADI_HOME="/opt/kadi"
ENV KADI_CONFIG_FILE="${KADI_HOME}/config/kadi.py"

RUN set -xe \
    && apt-get update -y \
    && apt-get install -y python3-pip

RUN apt install libmagic1 build-essential  \
libpq-dev libpcre3-dev apache2 libapache2-mod-proxy-uwsgi libapache2-mod-xsendfile -y

RUN adduser kadi --system --group --home /opt/kadi --shell /bin/bash \
&& usermod -a -G kadi www-data

RUN pip install kadi

COPY ./default-config/ /default-config/

# Apache ----------

RUN a2dissite 000-default \
    && ln -s "/etc/apache2/sites-available/kadi.conf" "/etc/apache2/sites-enabled/kadi.conf" \
    && a2enmod deflate headers http2 proxy_uwsgi socache_shmcb ssl xsendfile

# Create log and run folders
RUN mkdir /var/log/celery /run/celery && chown kadi /var/log/celery /run/celery

COPY ./docker-entrypoint.sh /docker-entrypoint.sh

RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
