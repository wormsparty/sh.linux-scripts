#!/bin/sh

# See: https://linux.how2shout.com/step-by-step-guide-installing-nextcloud-on-debian-12/

DOMAIN=localhost
APACHE_DIR=/var/www
DB_USERNAME=nextcloud
DB_PASSWORD=P@ssw0rd
DB_NAME=nextcloud

sudo apt install apache2 php libapache2-mod-php php-mysql php-common php-gd php-xml php-mbstring php-zip php-curl mariadb-server

cat << EOT | sudo tee /etc/apache2/sites-available/${DOMAIN}.conf
<VirtualHost *:80>
    ServerAdmin admin@${DOMAIN}
    DocumentRoot /var/www/html/${DOMAIN}/
    ServerName ${DOMAIN}

    <Directory /var/www/html/${DOMAIN}/>
        Options +FollowSymlinks
        AllowOverride All
        Require all granted
        <IfModule mod_dav.c>
            Dav off
        </IfModule>
        SetEnv HOME /var/www/html/${DOMAIN}
        SetEnv HTTP_HOME /var/www/html/${DOMAIN}
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOT

sudo ln -s /etc/apache2/sites-available/${DOMAIN}.conf /etc/apache2/sites-enabled/
sudo a2enmod headers rewrite env dir mime
sudo systemctl restart apache2 --no-page -l

sudo mysql_secure_installation

echo "DROP DATABASE ${DB_NAME};" | sudo mysql 

cat << EOT | sudo mysql
CREATE DATABASE ${DB_NAME};
GRANT ALL ON ${DB_NAME}.* TO ${DB_USERNAME}@localhost IDENTIFIED BY '${DB_PASSWORD}';
FLUSH PRIVILEGES;
\q;
EOT

mkdir -p ${APACHE_DIR}/html/${DOMAIN}
cd ${APACHE_DIR}/html/${DOMAIN}

if [ ! -f latest.tar.bz2 ]; then
	sudo wget https://download.nextcloud.com/server/releases/latest.tar.bz2
fi

if [ ! -f index.html ]; then
	sudo tar xvf latest.tar.bz2 --strip-components 1
fi

sudo mkdir -p ${APACHE_DIR}/html/${DOMAIN}/data
sudo chown -R www-data:www-data ${APACHE_DIR}/html/${DOMAIN}/
sudo chmod -R 755 ${APACHE_DIR}/html/${DOMAIN}/

open http://${DOMAIN}
