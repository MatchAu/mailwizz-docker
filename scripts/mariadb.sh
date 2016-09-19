#!/bin/bash
chown -R mysql:mysql /var/lib/mysql
mysql_install_db --user mysql > /dev/null

mysqld_safe --user mysql &
