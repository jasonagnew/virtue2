#!/bin/bash

# Load config file
source ~/.virtue_config

# Test if PHP is installed
php -v > /dev/null 2>&1
PHP_IS_INSTALLED=true


echo ">>> Installing Apache Server"

public_folder="$PUBLIC"

github_url=$GIT_URL

# Add repo for latest FULL stable Apache
# (Required to remove conflicts with PHP PPA due to partial Apache upgrade within it)
sudo add-apt-repository -y ppa:ondrej/apache2 > /dev/null 2>&1


# Update Again
sudo apt-key update > /dev/null 2>&1
sudo apt-get update > /dev/null 2>&1

# Install Apache
# -qq implies -y --force-yes
sudo apt-get install -qq apache2 apache2-mpm-event > /dev/null 2>&1

echo ">>> Configuring Apache"

# Set root to be part of www-data group
sudo usermod -a -G www-data $USER

# Apache Config
sudo a2dismod php5 mpm_prefork > /dev/null 2>&1
sudo a2enmod mpm_worker rewrite actions ssl > /dev/null 2>&1
curl --silent -L $github_url/helpers/vhost.sh > vhost
sudo chmod guo+x vhost
sudo mv vhost /usr/local/bin

# Disable default
sudo a2dissite 000-default > /dev/null 2>&1
sudo rm /etc/apache2/sites-available/000-default.conf
sudo rm /etc/apache2/sites-available/default-ssl.conf > /dev/null 2>&1

#Add default to reject random connections
touch /etc/apache2/sites-available/000-default.conf > /dev/null 2>&1
cat >> /etc/apache2/sites-available/000-default.conf <<EOF
<VirtualHost *:80>
    ErrorDocument 410 " "
    RedirectMatch 410 .
    <Location />
        Deny from all
        Allow from none
    </Location>
</VirtualHost>
<VirtualHost *:443>
    SSLEngine on
    SSLCertificateFile  $SSL/all/server.crt
    SSLCertificateKeyFile $SSL/all/server.key
    ErrorDocument 410 " "
    RedirectMatch 410 .
    <Location />
        Deny from all
        Allow from none
    </Location>
</VirtualHost>
EOF
sudo a2ensite 000-default > /dev/null 2>&1

# If PHP is installed or HHVM is installed, proxy PHP requests to it
if [[ $PHP_IS_INSTALLED -eq 0 ]]; then

    # PHP Config for Apache
    sudo a2enmod proxy_fcgi > /dev/null 2>&1
else
    # vHost script assumes ProxyPassMatch to PHP
    # If PHP is not installed, we'll comment it out
    sudo sed -i "s@ProxyPassMatch@#ProxyPassMatch@" /etc/apache2/sites-available/$1.xip.io.conf
fi

sudo service apache2 restart > /dev/null 2>&1
