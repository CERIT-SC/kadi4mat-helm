FROM python:3.13.2-bookworm

# Set python package paths so that configs can use version-independent paths.
ENV PIP_TARGET="/usr/local/lib/python/site-packages"
ENV PYTHONPATH="${PIP_TARGET}"
ENV PATH="${PATH}:${PIP_TARGET}/bin"

# Set kadi variables
ENV KADI_USER="kadi"
ENV KADI_GROUP="kadi"
ENV KADI_HOME="/opt/kadi"
ENV KADI_CONFIG_FILE="${KADI_HOME}/config/kadi.py"

# Update and install required modules
RUN apt-get update -y && \
    apt-get install -y python3-pip libmagic1 build-essential libpq-dev \
        libpcre3-dev apache2 libapache2-mod-proxy-uwsgi libapache2-mod-xsendfile -y && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Create kadi user
RUN adduser kadi --system --group --home /opt/kadi --shell /bin/bash

# Install kadi package
RUN pip install kadi

COPY ./default-config/ /default-config/

# Change ownership of necessary directories to non-root user
RUN mkdir -p /opt/kadi/config /opt/kadi/storage /opt/kadi/uploads \
        /var/run/apache2 /var/lock/apache2 /var/log/apache2 /etc/apache2/sites-enabled/ \
        /var/log/celery /run/celery && \
    chown -R kadi:kadi /default-config/ /opt/kadi \
        /var/run/apache2 /var/lock/apache2 /var/log/apache2 /etc/apache2/sites-enabled/ \
        /var/log/celery /run/celery

# Enable site configuration and required Apache modules
RUN a2dissite 000-default && \
    a2enmod deflate headers http2 proxy_uwsgi socache_shmcb ssl xsendfile

RUN sed -i 's/Listen 80/Listen 8080/g' /etc/apache2/ports.conf && \
    sed -i 's/www-data/kadi/g' /etc/apache2/envvars

# Copy entrypoint script
COPY ./docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Switch to non-root user
USER kadi

ENTRYPOINT ["/docker-entrypoint.sh"]
