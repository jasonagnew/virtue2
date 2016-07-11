#!/bin/bash

# Load config file
source ~/.virtue_config

  echo ">>> Installing PHP"

    sudo LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php > /dev/null 2>&1

    sudo apt-key update > /dev/null 2>&1
    sudo apt-get update > /dev/null 2>&1
    
    # Install PHP
    # -qq implies -y --force-yes


    sudo apt-get install -qq --force-yes php$PHP_NUMBER-cli php$PHP_NUMBER-fpm php$PHP_NUMBER-mysql php$PHP_NUMBER-pgsql php$PHP_NUMBER-sqlite php$PHP_NUMBER-curl php$PHP_NUMBER-gd php$PHP_NUMBER-gmp php$PHP_NUMBER-mcrypt php$PHP_NUMBER-xdebug php$PHP_NUMBER-memcached php$PHP_NUMBER-imagick php$PHP_NUMBER-intl libssh2-1-dev php-ssh2 > /dev/null 2>&1

    # Set PHP FPM to listen on TCP instead of Socket
    sudo sed -i "s/listen =.*/listen = 127.0.0.1:9000/" /etc/php/$PHP_NUMBER/fpm/pool.d/www.conf

    # Set PHP FPM allowed clients IP address
    sudo sed -i "s/;listen.allowed_clients/listen.allowed_clients/" /etc/php/$PHP_NUMBER/fpm/pool.d/www.conf

    # xdebug Config
    cat > $(find /etc/php/$PHP_NUMBER -name xdebug.ini) << EOF
zend_extension=$(find /usr/lib/php/$PHP_NUMBER -name xdebug.so)
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
    sudo sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/$PHP_NUMBER/fpm/php.ini
    sudo sed -i "s/display_errors = .*/display_errors = Off/" /etc/php/$PHP_NUMBER/fpm/php.ini

    # PHP Date Timezone
    sudo sed -i "s/;date.timezone =.*/date.timezone = ${SERVER_TIMEZONE/\//\\/}/" /etc/php/$PHP_NUMBER/fpm/php.ini
    sudo sed -i "s/;date.timezone =.*/date.timezone = ${SERVER_TIMEZONE/\//\\/}/" /etc/php/$PHP_NUMBER/cli/php.ini

    sudo service php$PHP_NUMBER-fpm restart > /dev/null 2>&1
