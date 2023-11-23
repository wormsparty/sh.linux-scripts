#!/bin/sh

DOMAIN=rpi.local
APACHE_DIR=/var/www
PHP_VERSION=7.4

sudo apt-get purge apache2 mariadb-server php${PHP}-xml php${PHP}-intl php${PHP}-common php${PHP}-json ${PHP}-curl php${PHP}-mbstring php${PHP}-mysql php${PHP}-gd php${PHP}-imagick php${PHP}-zip php${PHP}-opcache libapache2-mod-php${PHP}
sudo rm -fr ${APACHE_DIR}/html/${DOMAIN}/
sudo rm -f /etc/apache2/sites-available/${DOMAIN}.conf
sudo rm -f /etc/apt/trusted.gpg.d/php.gpg
sudo rm -f /etc/apt/sources.list.d/php.list

echo "Uninstall successful!"
