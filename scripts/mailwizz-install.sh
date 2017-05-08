#!/bin/bash

# exit on error
set -e

while [[ -z "${MAILWIZZ_LICENSE_KEY// }" ]]; do
    read -p "[ -> ] Please enter your mailwizz purchase code (license key): " MAILWIZZ_LICENSE_KEY
done

MAILWIZZ_FILE_NAME="mailwizz-latest"
MAILWIZ_ZIP_NAME="$MAILWIZZ_FILE_NAME.zip"
HTML="/var/www/mailwizz/"

echo "Fetching MailWizz using the license key $MAILWIZZ_LICENSE_KEY: "
curl -o "mailwizz-latest.zip" -H "X-LICENSEKEY: $MAILWIZZ_LICENSE_KEY" "https://www.mailwizz.com/api/download/version/latest" >/dev/null

if [ ! -f $MAILWIZ_ZIP_NAME ]; then
    echo "Please supply valid version and purchase code!"
    exit 1
fi

echo "Unzip MailWizz..."
unzip $MAILWIZ_ZIP_NAME >/dev/null
rm $MAILWIZ_ZIP_NAME

echo "$MAILWIZZ_FILE_NAME/latest/*  => $HTML/"
mv $MAILWIZZ_FILE_NAME/latest/* $HTML/
rm -rf $MAILWIZZ_FILE_NAME

while [[ -z "${MYSQL_ROOT_PASS// }" ]]; do
    read -p "[ -> ] Please enter the desired MariaDB ROOT password: " MYSQL_ROOT_PASS
done

while [[ -z "${MAILWIZZ_DB_NAME// }" ]]; do
    read -p "[ -> ] Please enter the desired MailWizz database name: " MAILWIZZ_DB_NAME
done

while [[ -z "${MAILWIZZ_DB_USER// }" ]]; do
    read -p "[ -> ] Please enter the desired MailWizz database username: " MAILWIZZ_DB_USER
done

while [[ -z "${MAILWIZZ_DB_PASS// }" ]]; do
    read -p "[ -> ] Please enter the desired MailWizz database password: " MAILWIZZ_DB_PASS
done

echo "Please wait, setting up MariaDB..."
mysql -h localhost -u root <<EOF
USE mysql;
UPDATE user SET Password=PASSWORD('$MYSQL_ROOT_PASS') WHERE User='root';
CREATE DATABASE $MAILWIZZ_DB_NAME;
CREATE USER '$MAILWIZZ_DB_USER'@'localhost' IDENTIFIED BY '$MAILWIZZ_DB_PASS';
GRANT ALL PRIVILEGES ON $MAILWIZZ_DB_NAME.* TO '$MAILWIZZ_DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF

echo "RUN schema.sql..."
mysql -u$MAILWIZZ_DB_USER -p$MAILWIZZ_DB_PASS $MAILWIZZ_DB_NAME < $HTML/apps/common/data/install-sql/schema.sql
echo "RUN insert.sql..."
mysql -u$MAILWIZZ_DB_USER -p$MAILWIZZ_DB_PASS $MAILWIZZ_DB_NAME < $HTML/apps/common/data/install-sql/insert.sql
echo "RUN country-zone.sql..."
mysql -u$MAILWIZZ_DB_USER -p$MAILWIZZ_DB_PASS $MAILWIZZ_DB_NAME < $HTML/apps/common/data/install-sql/country-zone.sql

echo "Change directory permissions..."
DP="$HTML/apps/console/commands/shell/set-dir-perms"
chmod +x $DP && ./$DP

echo "Adding first MailWizz user and customer... "
while [[ -z "${CUSTOMER_EMAIL// }" ]]; do
    read -p "[ -> ] Please enter your email address: " CUSTOMER_EMAIL
done

while [[ -z "${CUSTOMER_FIRST_NAME// }" ]]; do
    read -p "[ -> ] Please enter your first name: " CUSTOMER_FIRST_NAME
done

while [[ -z "${CUSTOMER_LAST_NAME// }" ]]; do
    read -p "[ -> ] Please enter your last name: " CUSTOMER_LAST_NAME
done

mysql -h localhost -u$MAILWIZZ_DB_USER -p$MAILWIZZ_DB_PASS $MAILWIZZ_DB_NAME <<EOF
INSERT INTO user(\`user_id\`, \`user_uid\`, \`group_id\`, \`language_id\`, \`first_name\`, \`last_name\`, \`email\`, \`password\`, \`timezone\`, \`avatar\`, \`removable\`, \`status\`, \`date_added\`, \`last_updated\`) VALUES (NULL,'zy141276wz5ef',NULL,NULL,'$CUSTOMER_FIRST_NAME','$CUSTOMER_LAST_NAME','$CUSTOMER_EMAIL','\$P\$GCfF1NQ/w6a9I0sh/cUIIf/lkc/cOd0','UTC',NULL,'no','active',NOW(),NOW());
INSERT INTO customer(\`customer_id\`, \`customer_uid\`, \`group_id\`, \`language_id\`, \`first_name\`, \`last_name\`, \`email\`, \`password\`, \`timezone\`, \`avatar\`, \`removable\`, \`confirmation_key\`, \`oauth_uid\`, \`oauth_provider\`, \`status\`, \`date_added\`, \`last_updated\`) VALUES (NULL,'mj61610g5ea23',NULL,NULL,'$CUSTOMER_FIRST_NAME','$CUSTOMER_LAST_NAME','$CUSTOMER_EMAIL','\$P\$GCfF1NQ/w6a9I0sh/cUIIf/lkc/cOd0','UTC',NULL,'yes','02022e98ba5e8c3be026acc51955950483e9fa23',NULL,NULL,'active',NOW(),NOW());

INSERT INTO option SET category = "system.license", \`key\` = "email", value = "$CUSTOMER_EMAIL", is_serialized = 0, date_added = NOW(), last_updated  = NOW();
INSERT INTO option SET category = "system.license", \`key\` = "first_name", value = "$CUSTOMER_FIRST_NAME", is_serialized = 0, date_added = NOW(), last_updated  = NOW();
INSERT INTO option SET category = "system.license", \`key\` = "last_name", value = "$CUSTOMER_LAST_NAME", is_serialized = 0, date_added = NOW(), last_updated  = NOW();
INSERT INTO option SET category = "system.license", \`key\` = "key", value = "$MAILWIZZ_LICENSE_KEY", is_serialized = 0, date_added = NOW(), last_updated  = NOW();
INSERT INTO option SET category = "system.license", \`key\` = "purchase_code", value = "$MAILWIZZ_LICENSE_KEY", is_serialized = 0, date_added = NOW(), last_updated  = NOW();
INSERT INTO option SET category = "system.license", \`key\` = "market_place", value = "envato", is_serialized = 0, date_added = NOW(), last_updated  = NOW();

INSERT INTO option SET category = "system.common", \`key\` = "version", value = "$MAILWIZZ_VERSION", is_serialized = 0, date_added = NOW(), last_updated  = NOW();
EOF

echo "Creating main config... "
# generate random word
RNDSTR="$(pwgen -A -0 4 1)"
# uppercase first char
EMAILS_CUSTOM_HEADER_PREFIX=${RNDSTR^}
# replace
cp $HTML/apps/common/data/config/main-custom.php $HTML/apps/common/config/main-custom.php
sed -i "s/{DB_CONNECTION_STRING}/mysql:host=localhost;dbname=${MAILWIZZ_DB_NAME}/g" $HTML/apps/common/config/main-custom.php
sed -i "s/{DB_USER}/${MAILWIZZ_DB_USER}/g" $HTML/apps/common/config/main-custom.php
sed -i "s/{DB_PASS}/${MAILWIZZ_DB_PASS}/g" $HTML/apps/common/config/main-custom.php
sed -i "s/{DB_PREFIX}//g" $HTML/apps/common/config/main-custom.php
sed -i "s/{EMAILS_CUSTOM_HEADER_PREFIX}/X-${EMAILS_CUSTOM_HEADER_PREFIX}/g" $HTML/apps/common/config/main-custom.php

echo "Adding the cron jobs... "
echo "* * * * * /usr/bin/php -q $HTML/apps/console/console.php send-campaigns >/dev/null 2>&1 &" >> mwcron
echo "*/2 * * * * /usr/bin/php -q $HTML/apps/console/console.php send-transactional-emails  >/dev/null 2>&1 &" >> mwcron
echo "*/10 * * * * /usr/bin/php -q $HTML/apps/console/console.php bounce-handler >/dev/null 2>&1 &" >> mwcron
echo "*/20 * * * * /usr/bin/php -q $HTML/apps/console/console.php feedback-loop-handler >/dev/null 2>&1 &" >> mwcron
echo "*/3 * * * * /usr/bin/php -q $HTML/apps/console/console.php process-delivery-and-bounce-log >/dev/null 2>&1 &" >> mwcron
echo "0 * * * * /usr/bin/php -q $HTML/apps/console/console.php hourly >/dev/null 2>&1 &" >> mwcron
echo "0 0 * * * /usr/bin/php -q $HTML/apps/console/console.php daily >/dev/null 2>&1 &" >> mwcron
crontab mwcron
rm mwcron

echo "Removing the install folder... "
rm -rf $HTML/install

echo "DONE, you can access your mailwizz app with following data: "
echo "Backend login with the email: $CUSTOMER_EMAIL and password: mailwizz"
echo "Customer login with the email: $CUSTOMER_EMAIL and password: mailwizz"
echo "Please make sure you change these credentials after you login for the first time!"
