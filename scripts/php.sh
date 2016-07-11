#!/bin/bash

# Load config file
source ~/.virtue_config

  echo ">>> Installing PHP"

    sudo LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php > /dev/null 2>&1

    sudo apt-key update > /dev/null 2>&1
    sudo apt-get update > /dev/null 2>&1
    
    # Install PHP
    # -qq implies -y --force-yes
    sudo apt-get install -qq --force-yes php7.0-cli php7.0-fpm php7.0-mysql php7.0-pgsql php7.0-sqlite php7.0-curl php7.0-gd php7.0-gmp php7.0-mcrypt php7.0-xdebug php7.0-memcached php7.0-imagick php7.0-intl > /dev/null 2>&1

    sudo apt-get install -qq --force-yes libssh2-1-dev php-ssh2 > /dev/null 2>&1

    # Set PHP FPM to listen on TCP instead of Socket
    sudo sed -i "s/listen =.*/listen = 127.0.0.1:9000/" /etc/php/7.0/fpm/pool.d/www.conf

    # Set PHP FPM allowed clients IP address
    sudo sed -i "s/;listen.allowed_clients/listen.allowed_clients/" /etc/php/7.0/fpm/pool.d/www.conf

    # xdebug Config
    cat > $(find /etc/php/7.0 -name xdebug.ini) << EOF
zend_extension=$(find /usr/lib/php/7.0 -name xdebug.so)
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
    sudo sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.0/fpm/php.ini
    sudo sed -i "s/display_errors = .*/display_errors = Off/" /etc/php/7.0/fpm/php.ini

    # PHP Date Timezone
    sudo sed -i "s/;date.timezone =.*/date.timezone = ${SERVER_TIMEZONE/\//\\/}/" /etc/php/7.0/fpm/php.ini
    sudo sed -i "s/;date.timezone =.*/date.timezone = ${SERVER_TIMEZONE/\//\\/}/" /etc/php/7.0/cli/php.ini

    sudo service php7.0-fpm restart > /dev/null 2>&1
