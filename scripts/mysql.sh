#!/bin/bash

# Load config file
source ~/.virtue_config

echo ">>> Installing MySQL Server $MYSQL_VERISON"

mysql_package=mysql-server

if [ $MYSQL_VERISON == "5.6" ]; then
    # Add repo for MySQL 5.6
	sudo add-apt-repository -y ppa:ondrej/mysql-5.6 > /dev/null 2>&1

	# Update Again
	sudo apt-get update > /dev/null 2>&1

	# Change package
	mysql_package=mysql-server-5.6
fi

# Install MySQL without password prompt
# Set username and password to 'root'
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $MYSQL_PASS"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $MYSQL_PASS"

# Install MySQL Server
sudo apt-get install -qq $mysql_package > /dev/null 2>&1

if [ $MYSQL_REMOTE == "true" ]; then
    # enable remote access
    # setting the mysql bind-address to allow connections from everywhere
    sed -i "s/bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/my.cnf

    # adding grant privileges to mysql root user from everywhere
    # thx to http://stackoverflow.com/questions/7528967/how-to-grant-mysql-privileges-in-a-bash-script for this
    MYSQL=`which mysql`

    Q1="GRANT ALL ON *.* TO 'root'@'%' IDENTIFIED BY '$MYSQL_PASS' WITH GRANT OPTION;"
    Q2="FLUSH PRIVILEGES;"
    SQL="${Q1}${Q2}"

    $MYSQL -uroot -p$MYSQL_PASS -e "$SQL" > /dev/null 2>&1

    service mysql restart > /dev/null 2>&1
fi
