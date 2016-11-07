# mailwizz

FROM centos:7
MAINTAINER Serban Cristian "support@mailwizz.com"

# update packages
RUN yum update -y

# EPEL and PHP 7
RUN rpm -Uvh http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-8.noarch.rpm
RUN rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm

# install common packages
RUN yum install -y nmap hostname nano curl unzip cronie pwgen

# Supervisor
RUN yum install -y supervisor
ADD conf/supervisord.conf /etc/supervisord.conf

# Nginx repo
ADD repos/nginx.repo /etc/yum.repos.d/

# Nginx and PHP extensions
RUN yum --enablerepo=remi,remi-php70 install -y nginx php-fpm php-common
RUN yum --enablerepo=remi,remi-php70 install -y php-opcache php-pecl-apcu php-cli \
    php-pear php-pdo php-mysqlnd php-pecl-redis php-pecl-memcache \
    php-pecl-memcached php-gd php-mbstring php-mcrypt php-xml php-imap php-zip

# Add some php directives
RUN echo "request_terminate_timeout = 300" >> /etc/php-fpm.d/www.conf
RUN echo "php_admin_value[memory_limit] = 256M" >> /etc/php-fpm.d/www.conf
RUN echo "php_admin_value[upload_max_filesize] = 100M" >> /etc/php-fpm.d/www.conf
RUN echo "php_admin_value[post_max_size] = 8M" >> /etc/php-fpm.d/www.conf

# Nginx setup
RUN mkdir -p /srv/www/mailwizz/public_html
RUN mkdir /srv/www/mailwizz/logs
RUN chown -R apache:apache /srv/www/mailwizz
RUN mkdir /etc/nginx/sites-available
RUN mkdir /etc/nginx/sites-enabled
RUN rm /etc/nginx/nginx.conf
ADD conf/nginx.conf /etc/nginx/
ADD conf/nginx-mailwizz.conf /etc/nginx/sites-available/mailwizz
RUN ln -s /etc/nginx/sites-available/mailwizz /etc/nginx/sites-enabled/mailwizz
RUN echo "<?php phpinfo();?>" >> /srv/www/mailwizz/public_html/index.php
RUN mkdir -p /srv/www/mailwizz/public_html
VOLUME /srv/www/mailwizz/public_html
EXPOSE 80 443

# Mariadb
ADD repos/mariadb.repo /etc/yum.repos.d/mariadb.repo
ADD conf/mariadb.cnf /etc/my.cnf.d/server.cnf
RUN yum install -y MariaDB-server
VOLUME /var/lib/mysql
EXPOSE 3306

# Scripts
ADD scripts/mariadb.sh /root/mailwizz/scripts/mariadb.sh
ADD scripts/setup.sh /root/mailwizz/scripts/setup.sh
ADD scripts/start.sh /root/mailwizz/scripts/start.sh

RUN chmod +x /root/mailwizz/scripts/mariadb.sh
RUN chmod +x /root/mailwizz/scripts/setup.sh
RUN chmod +x /root/mailwizz/scripts/start.sh

CMD ["/root/mailwizz/scripts/start.sh"]
