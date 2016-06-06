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
        PHP_NUMBER=7.0
    fi
    
    if [ $PHP_VERISON == "distributed" ]; then
        PHP_NUMBER=5.6
    fi

    if [ $PHP_VERISON == "previous" ]; then
        PHP_NUMBER=5.5
    fi

    sudo apt-get install -qq --force-yes $PHP_NUMBER-cli $PHP_NUMBER-fpm $PHP_NUMBER-mysql $PHP_NUMBER-pgsql $PHP_NUMBER-sqlite $PHP_NUMBER-curl $PHP_NUMBER-gd $PHP_NUMBER-gmp $PHP_NUMBER-mcrypt $PHP_NUMBER-xdebug $PHP_NUMBER-memcached $PHP_NUMBER-imagick $PHP_NUMBER-intl libssh2-1-dev libssh2-php > /dev/null 2>&1

    # Set PHP FPM to listen on TCP instead of Socket
    sudo sed -i "s/listen =.*/listen = 127.0.0.1:9000/" /etc/$PHP_NUMBER/fpm/pool.d/www.conf

    # Set PHP FPM allowed clients IP address
    sudo sed -i "s/;listen.allowed_clients/listen.allowed_clients/" /etc/$PHP_NUMBER/fpm/pool.d/www.conf

    # xdebug Config
    cat > $(find /etc/$PHP_NUMBER -name xdebug.ini) << EOF
zend_extension=$(find /usr/lib/$PHP_NUMBER -name xdebug.so)
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
    sudo sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/$PHP_NUMBER/fpm/php.ini
    sudo sed -i "s/display_errors = .*/display_errors = Off/" /etc/$PHP_NUMBER/fpm/php.ini

    # PHP Date Timezone
    sudo sed -i "s/;date.timezone =.*/date.timezone = ${SERVER_TIMEZONE/\//\\/}/" /etc/$PHP_NUMBER/fpm/php.ini
    sudo sed -i "s/;date.timezone =.*/date.timezone = ${SERVER_TIMEZONE/\//\\/}/" /etc/$PHP_NUMBER/cli/php.ini

    sudo service $PHP_NUMBER-fpm restart > /dev/null 2>&1
