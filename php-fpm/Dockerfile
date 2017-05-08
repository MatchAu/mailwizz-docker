FROM alterway/php:7.1-fpm

# update
RUN apt-get update && apt-get install -y bash zip unzip pwgen cron

# copy the setup
COPY ./php-fpm/mailwizz-install.sh /root/mailwizz-install.sh

# make it executable
RUN chmod +x /root/mailwizz-install.sh

# Clean up, try to reduce image size (much as you can on Debian..)
RUN apt-get autoremove -y \
    && apt-get clean all \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /usr/share/doc /usr/share/man /usr/share/locale
