#!/bin/bash

# Load config file
source ~/.virtue_config

# Test if PHP is installed
php -v > /dev/null 2>&1
PHP_IS_INSTALLED=true


echo ">>> Installing Nginx Server"

public_folder="$PUBLIC"


github_url=$GIT_URL

# Add repo for latest stable nginx
sudo add-apt-repository -y ppa:nginx/stable  > /dev/null 2>&1

# Update Again
sudo apt-get update  > /dev/null 2>&1

# Install Nginx
# -qq implies -y --force-yes
sudo apt-get install -qq nginx > /dev/null 2>&1


echo ">>> Configuring Nginx"

# Set root to be part of www-data group
sudo usermod -a -G www-data $USER

# Turn off sendfile
sed -i 's/sendfile on;/sendfile off;/' /etc/nginx/nginx.conf
sed -i "s/# server_names_hash_bucket_size.*/server_names_hash_bucket_size 64;/" /etc/nginx/nginx.conf

# Nginx enabling and disabling virtual hosts
curl --silent -L $github_url/helpers/ngxen.sh > ngxen
curl --silent -L $github_url/helpers/ngxdis.sh > ngxdis
curl --silent -L $github_url/helpers/ngxcb.sh > ngxcb
sudo chmod guo+x ngxen ngxdis ngxcb
sudo mv ngxen ngxdis ngxcb /usr/local/bin

# Disable "default"
sudo ngxdis default > /dev/null 2>&1
sudo rm /etc/nginx/sites-available/default

#Add default to reject random connections
touch /etc/nginx/sites-available/default > /dev/null 2>&1
cat >> /etc/nginx/sites-available/default <<EOF
server {
        listen 80 default_server;
        server_name _;
        return 444;
}

server {
        listen 443 default_server;
        ssl on;
        ssl_certificate     $SSL/all/server.crt;
        ssl_certificate_key $SSL/all/server.key;
        server_name _;
        return 444;
}
EOF
sudo ngxen default > /dev/null 2>&1


if [[ $PHP_IS_INSTALLED -eq 0 ]]; then
    # PHP-FPM Config for Nginx
    sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php5/fpm/php.ini

    sudo service php5-fpm restart > /dev/null 2>&1
fi

sudo service nginx restart > /dev/null 2>&1