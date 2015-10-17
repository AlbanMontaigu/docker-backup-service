# ================================================================================================================
# A docker backup service.
#
# @see http://github.com/tenstartups/backup-service-docker
# @see http://backup.github.io/backup/v4/
# @see https://github.com/tenstartups/backup
# ================================================================================================================

# Base image
FROM ruby:slim

# Maintainer
MAINTAINER alban.montaigu@gmail.com

# Set environment variables.
ENV \
    DEBIAN_FRONTEND=noninteractive \
    TERM=xterm-color \
    HOME=/home/backups \
    BACKUP_CONFIG_DIR=/etc/backups \
    BACKUP_DATA_DIR=/var/lib/backups

# Install base packages.
RUN apt-get update \
    && apt-get -y install \
        build-essential \
        curl \
        git \
        mysql-client \
        nano \
        sqlite3 \
        wget

# Add postgresql client from official source.
RUN \
    echo "deb http://apt.postgresql.org/pub/repos/apt/ wheezy-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
    && wget https://www.postgresql.org/media/keys/ACCC4CF8.asc \
    && apt-key add ACCC4CF8.asc \
    && apt-get update \
    && apt-get -y install libpq-dev postgresql-client-9.4 postgresql-contrib-9.4

# Compile redis from official source
RUN \
    cd /tmp \
    && wget http://download.redis.io/redis-stable.tar.gz \
    && tar -xzvf redis-*.tar.gz \
    && rm -f redis-*.tar.gz \
    && cd redis-* \
    && make \
    && make install \
    && cd .. \
    && rm -rf redis-*

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install and configurre backup and whenever gems.
RUN \
    cd /tmp \
    && git clone https://github.com/tenstartups/backup.git \
    && cd backup \
    && git checkout package_with_storage_id \
    && gem build backup.gemspec \
    && gem install backup --no-ri --no-rdoc

# Define working directory.
WORKDIR /home/backups

# Define mountable directories.
VOLUME ["/home/backups", "/var/log/backups"]

# Entrypoint to enable live customization
COPY docker-entrypoint.sh /docker-entrypoint.sh

# Set the entrypoint script.
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["backup"]
