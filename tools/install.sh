#!/bin/bash
set -e;

echo " "
echo "********************************"
echo "* Welcome to Virtue"
echo "********************************"
echo " "

function set_config () {
  sed -i -e "/$1=/ s/=.*/=$2/" ~/.virtue_config
}

# Install Base Pacckages
echo ">>> Installing Trusty Base Packages"
bash << +END
sudo apt-get update > /dev/null 2>&1
sudo apt-get install -qq curl unzip git-core ack-grep jq > /dev/null 2>&1
exit 0
+END


echo ">>> Starting install"

# Install Virtue
VIRTUE=~/.virtue

if [ -d "$VIRTUE" ]; then
  echo "You already have Virtue installed. You'll need to remove $VIRTUE if you want to install"
  exit
fi

echo ">>> Cloning Virtue..."
hash git >/dev/null 2>&1 && /usr/bin/env git clone --q https://github.com/jasonagnew/virtue2.git $VIRTUE || {
  echo "git not installed"
  exit
}

echo ">>> Looking for an existing Virtue config..."
if [ -f ~/.virtue_config ] || [ -h ~/.virtue_config ]; then
  echo "Found ~/.virtue_config. Backing up to ~/.virtue_config.pre-virtue";
  mv ~/.virtue_config ~/.virtue_config.pre-virtue;
fi

echo ">>> Using the Virtue template file and adding it to ~/.virtue_config"
cp $VIRTUE/templates/virtue_config.template ~/.virtue_config
sed -i -e "/^VIRTUE=/ c\\
VIRTUE=$VIRTUE
" ~/.virtue_config

echo ">>> Copying your current PATH and adding it to the end of ~/.virtue_config for you."
sed -i -e "/export PATH=/ c\\
export PATH=\"$PATH\"
" ~/.virtue_config

echo ">>> Copying to bin directory"
sudo cp $VIRTUE/virtue.sh /usr/local/bin/virtue
sudo chmod a+x /usr/local/bin/virtue


if [[ -n "$1" ]]; then
    set_config "MYSQL_USER" $1
fi

if [[ -n "$2" ]]; then
    set_config "MYSQL_PASS" $2
fi

if [[ -n "$3" ]]; then
    set_config "MYSQL_REMOTE" $3
fi

if [[ -n "$4" ]]; then
    set_config "PHP_VERISON" $4

    if [ $4 == "latest" ]; then
        set_config "PHP_NUMBER" "php7.0"
    fi

    if [ $4== "distributed" ]; then
        set_config "PHP_NUMBER" "php5.6"
    fi

    if [ $4 == "previous" ]; then
        set_config "PHP_NUMBER" "php5.5"
    fi
fi

if [[ -n "$5" ]]; then
    set_config "HTTP_SERVER" $5
fi

if [[ -n "$6" ]]; then
    set_config "USER" $6
fi

if [[ -n "$7" ]]; then
    set_config "SSH_PORT" $7
fi

if [[ -n "$8" ]]; then
    set_config "CALLBACK_URL" $8
fi




# Load config file
source ~/.virtue_config

# Make git directory
sudo mkdir $GIT

#PHP
bash $VIRTUE/scripts/php.sh

#Self Sign - used to reject random connections
echo ">>> Installing Self Sign SSL - Used to reject 443 connections"
sudo mkdir -p $SSL/all
openssl genrsa -out $SSL/all/server.key 2048 > /dev/null 2>&1
touch $SSL/all/openssl.cnf > /dev/null 2>&1
cat >> $SSL/all/openssl.cnf <<EOF
[ req ]
prompt = no
distinguished_name = req_distinguished_name
[ req_distinguished_name ]
C = GB
ST = Test State
L = Test Locality
O = Org Name
OU = Org Unit Name
CN = Common Name
emailAddress = test@email.com
EOF
openssl req -config $SSL/all/openssl.cnf -new -key $SSL/all/server.key -out $SSL/all/server.csr > /dev/null 2>&1
openssl x509 -req -days 2048 -in $SSL/all/server.csr -signkey $SSL/all/server.key -out $SSL/all/server.crt > /dev/null 2>&1


if [ $HTTP_SERVER = "apache" ]; then
    #Apache
    bash $VIRTUE/scripts/apache.sh
else
    #Nginc
    bash $VIRTUE/scripts/nginx.sh
fi

#MySQL
bash $VIRTUE/scripts/mysql.sh

#Composer
echo ">>> Installing Composer"
curl -sS https://getcomposer.org/installer | php > /dev/null 2>&1
sudo mv composer.phar /usr/local/bin/composer > /dev/null 2>&1

#Node
echo ">>> Installing NodeJS & Ruby"
bash << +END
sudo apt-get -qq install nodejs nodejs-legacy ruby-full  > /dev/null 2>&1
exit 0
+END

#Node
echo ">>> Installing NPM"
bash << +END
curl -s -L https://npmjs.com/install.sh | sh > /dev/null 2>&1
exit 0
+END


echo ">>> Installing Gulp, Grunt, Bower, Yeoman, Browserify, Webpack"
bash << +END
npm install -g gulp grunt-cli bower yo browserify webpack > /dev/null 2>&1
exit 0
+END

echo ">>> Installing SASS"
bash << +END
sudo gem install sass > /dev/null 2>&1
exit 0
+END

echo ">>> Installing Supervisor"
bash << +END
sudo apt-get -qq install supervisor > /dev/null 2>&1
exit 0
+END

echo ">>> Installing Beanstalk"
bash << +END
sudo apt-get -qq install beanstalkd > /dev/null 2>&1
exit 0
+END

echo ">>> Configuring Beanstalk"
echo "START=yes" >> /etc/default/beanstalkd

#SSH Key
echo ">>> Generating SSH Key"
ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa > /dev/null 2>&1

#Fail2Ban
echo ">>> Installing Fail2Ban"
bash << +END
sudo apt-get -qq install fail2ban > /dev/null 2>&1

touch /etc/fail2ban/jail.local > /dev/null 2>&1
cat >> /etc/fail2ban/jail.local <<EOF
[ssh]
port=$SSH_PORT
EOF

sudo service fail2ban restart > /dev/null 2>&1
exit 0
+END

#ufw
echo ">>> Installing ufw"
bash << +END
sudo apt-get -qq install ufw > /dev/null 2>&1
sudo ufw default deny incoming > /dev/null 2>&1
sudo ufw default allow outgoing > /dev/null 2>&1

if [ $SSH_PORT = "22" ]; then
    sudo ufw allow 22 > /dev/null 2>&1
else
    sudo ufw allow 22 > /dev/null 2>&1
    sudo ufw allow $SSH_PORT > /dev/null 2>&1
fi

sudo ufw allow 22 > /dev/null 2>&1
sudo ufw allow 80 > /dev/null 2>&1
sudo ufw allow 443 > /dev/null 2>&1
echo "Y" | sudo ufw enable > /dev/null 2>&1
exit 0
+END

echo ">>> Calling Callback URL"
bash << +END
curl $CALLBACK_URL > /dev/null 2>&1
exit 0
+END

echo " "
echo "All finished"
echo " "
