FROM alterway/php:7.1-fpm

# update
RUN apt-get update && apt-get install -y bash zip unzip pwgen cron

# remove php since we will add ours
RUN apt-get -y purge php.*

# install imap
RUN apt-get update && apt-get install -y libc-client-dev libkrb5-dev && rm -r /var/lib/apt/lists/*
RUN apt-get update \
    && docker-php-ext-configure imap --with-imap-ssl --with-kerberos \
    && docker-php-ext-install imap

# copy the setup
COPY ./php-fpm/mailwizz-install.sh /root/mailwizz-install.sh

# make it executable
RUN chmod +x /root/mailwizz-install.sh

# Clean up, try to reduce image size (much as you can on Debian..)
RUN apt-get autoremove -y \
    && apt-get clean all \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /usr/share/doc /usr/share/man /usr/share/locale

# cronjobs
RUN /etc/init.d/cron start && update-rc.d cron defaults
