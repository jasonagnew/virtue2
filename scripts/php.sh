#!/bin/bash

# Load config file
source ~/.virtue_config

  echo ">>> Installing PHP"
 
    if [ $PHP_VERISON == "latest" ]; then
        echo ">>> Adding apt repo"
        sudo add-apt-repository -y ppa:ondrej/php5-5.6 > /dev/null 2>&1
    fi
    
    if [ $PHP_VERISON == "distributed" ]; then
        sudo add-apt-repository -y ppa:ondrej/php5 > /dev/null 2>&1
    fi

    if [ $PHP_VERISON == "previous" ]; then
        sudo add-apt-repository -y ppa:ondrej/php5-oldstable > /dev/null 2>&1
    fi

    echo ">>> Installing PHP"

    sudo apt-key update > /dev/null 2>&1
    sudo apt-get update > /dev/null 2>&1

    # Install PHP
    # -qq implies -y --force-yes
    echo ">>> Running apt install"
    sudo apt-get install -qq --force-yes php5-cli php5-fpm php5-mysql php5-pgsql php5-sqlite php5-curl php5-gd php5-gmp php5-mcrypt php5-xdebug php5-memcached php5-imagick php5-intl libssh2-1-dev libssh2-php > /dev/null 2>&1

    # Set PHP FPM to listen on TCP instead of Socket
    echo ">>> Running php fpm tcp"
    sudo sed -i "s/listen =.*/listen = 127.0.0.1:9000/" /etc/php5/fpm/pool.d/www.conf

    # Set PHP FPM allowed clients IP address
    echo ">>> Running php fpm ip"
    sudo sed -i "s/;listen.allowed_clients/listen.allowed_clients/" /etc/php5/fpm/pool.d/www.conf

    # xdebug Config
    echo ">>> Xdebug"
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
    echo ">>> PHP Errors"
    sudo sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php5/fpm/php.ini
    sudo sed -i "s/display_errors = .*/display_errors = Off/" /etc/php5/fpm/php.ini

    # PHP Date Timezone
    echo ">>> PHP Timezone"
    sudo sed -i "s/;date.timezone =.*/date.timezone = ${SERVER_TIMEZONE/\//\\/}/" /etc/php5/fpm/php.ini
    sudo sed -i "s/;date.timezone =.*/date.timezone = ${SERVER_TIMEZONE/\//\\/}/" /etc/php5/cli/php.ini

    echo ">>> PHP fpm restart"
    sudo service php5-fpm restart > /dev/null 2>&1

    echo ">>> PHP done"
