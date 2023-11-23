#!/bin/sh

DOMAIN=localhost
PORT=80
APACHE_DIR=/var/www
PHP=7.4
DB_USERNAME=owncloud
DB_PASSWORD=P@ssw0rd
DB_NAME=owncloud

sudo apt-get install apache2
sudo a2enmod rewrite headers unique_id
sudo systemctl restart apache2
sudo mkdir -p ${APACHE_DIR}/html/${DOMAIN}/
sudo chown -R www-data ${APACHE_DIR}/html/${DOMAIN}/
sudo mkdir -p ${APACHE_DIR}/logs

cat << EOT | sudo tee /etc/apache2/sites-available/${DOMAIN}.conf
<VirtualHost *:${PORT}>

ServerAdmin admin@${DOMAIN}
ServerName ${DOMAIN}
ServerAlias www.${DOMAIN}
DocumentRoot /var/www/html/${DOMAIN}

ErrorLog ${APACHE_DIR}/logs/${DOMAIN}_error.log
CustomLog ${APACHE_DIR}/logs/${DOMAIN}_access.log combined

<Directory ${APACHE_DIR}/html/${DOMAIN}/>
  Options +FollowSymlinks
  AllowOverride All
</Directory>
 <IfModule mod_dav.c>
  Dav off
 </IfModule>

</VirtualHost>
EOT

sudo a2ensite ${DOMAIN}
sudo a2dismod mpm_event
sudo a2enmod mpm_prefork

sudo apt-get install apt-transport-https lsb-release ca-certificates wget

if [ ! -f /etc/apt/trusted.gpg.d/php.gpg ]; then
	sudo wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
fi

if [ ! -f /etc/apt/sources.list.d/php.list ]; then
	echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php.list
	sudo apt-get update
fi

sudo apt-get install php${PHP}-xml php${PHP}-intl php${PHP}-common php${PHP}-json ${PHP}-curl php${PHP}-mbstring php${PHP}-mysql php${PHP}-gd php${PHP}-imagick php${PHP}-zip php${PHP}-opcache libapache2-mod-php${PHP}

sudo a2enmod php${PHP}
sudo systemctl restart apache2

sudo apt-get install mariadb-server

cat << EOT | sudo mysql
	CREATE DATABASE ${DB_NAME};
	GRANT ALL on owncloud.* to ${DB_USERNAME}@localhost identified by '${DB_PASSWORD}';
	FLUSH PRIVILEGES;
	\q
EOT

cd ${APACHE_DIR}/html/${DOMAIN}

if [ ! -f owncloud-latest.tar.bz2 ]; then
	sudo wget https://download.owncloud.com/server/stable/owncloud-latest.tar.bz2
fi

if [ ! -f index.html ]; then
	sudo tar xvf owncloud-latest.tar.bz2 --strip-components 1
	sudo chown -R www-data ${APACHE_DIR}/html/${DOMAIN}
fi


if [ "$PORT" != "80" ]; then
	echo "WARNING: Non-standard port used! Please edit /etc/apache2/ports.conf to contain your port!"
fi

open http://${DOMAIN}:${PORT}
