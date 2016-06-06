#!/bin/bash

# Load config file
source ~/.virtue_config

  echo ">>> Installing PHP"

    sudo LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php > /dev/null 2>&1

    sudo apt-key update > /dev/null 2>&1
    sudo apt-get update > /dev/null 2>&1
    
    # Install PHP
    # -qq implies -y --force-yes
    if [ $PHP_VERISON == "latest" ]; then
        sudo apt-get install -qq --force-yes php7.0-cli php7.0-fpm php7.0-mysql php7.0-pgsql php7.0-sqlite php7.0-curl php7.0-gd php7.0-gmp php7.0-mcrypt php7.0-xdebug php7.0-memcached php7.0-imagick php7.0-intl libssh2-1-dev libssh2-php > /dev/null 2>&1
    fi
    
    if [ $PHP_VERISON == "distributed" ]; then
        sudo apt-get install -qq --force-yes php5.6-cli php5.6-fpm php5.6-mysql php5.6-pgsql php5.6-sqlite php5.6-curl php5.6-gd php5.6-gmp php5.6-mcrypt php5.6-xdebug php5.6-memcached php5.6-imagick php5.6-intl libssh2-1-dev libssh2-php > /dev/null 2>&1
    fi

    if [ $PHP_VERISON == "previous" ]; then
        sudo apt-get install -qq --force-yes php5.5-cli php5.5-fpm php5.5-mysql php5.5-pgsql php5.5-sqlite php5.5-curl php5.5-gd php5.5-gmp php5.5-mcrypt php5.5-xdebug php5.5-memcached php5.5-imagick php5.5-intl libssh2-1-dev libssh2-php > /dev/null 2>&1
    fi

    # Set PHP FPM to listen on TCP instead of Socket
    sudo sed -i "s/listen =.*/listen = 127.0.0.1:9000/" /etc/php5/fpm/pool.d/www.conf

    # Set PHP FPM allowed clients IP address
    sudo sed -i "s/;listen.allowed_clients/listen.allowed_clients/" /etc/php5/fpm/pool.d/www.conf

    # xdebug Config
    cat > $(find /etc/php5 -name xdebug.ini) << EOF
zend_extension=$(find /usr/lib/php5 -name xdebug.so)
xdebug.remote_enable = 1
xdebug.remote_connect_back = 1
xdebug.remote_port = 9000
xdebug.scream=0
xdebug.cli_color=1
xdebug.show_local_vars=1

; var_dump display
xdebug.var_display_max_depth = 5
xdebug.var_display_max_children = 256
xdebug.var_display_max_data = 1024
EOF

    # PHP Error Reporting Config
    sudo sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php5/fpm/php.ini
    sudo sed -i "s/display_errors = .*/display_errors = Off/" /etc/php5/fpm/php.ini

    # PHP Date Timezone
    sudo sed -i "s/;date.timezone =.*/date.timezone = ${SERVER_TIMEZONE/\//\\/}/" /etc/php5/fpm/php.ini
    sudo sed -i "s/;date.timezone =.*/date.timezone = ${SERVER_TIMEZONE/\//\\/}/" /etc/php5/cli/php.ini

    sudo service php5-fpm restart > /dev/null 2>&1
