#!/bin/sh

DOMAIN=localhost
APACHE_DIR=/var/www

sudo apt purge apache2 php libapache2-mod-php php-mysql php-common php-gd php-xml php-mbstring php-zip php-curl mariadb-server

sudo rm -f /etc/apache2/sites-available/${DOMAIN}.conf /etc/apache2/sites-enabled/${DOMAIN}.conf
sudo rm -fr ${APACHE_DIR}/html/${DOMAIN}

echo "Done!"
