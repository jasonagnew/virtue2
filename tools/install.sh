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
fi


# Load config file
source ~/.virtue_config

# Make git directory
sudo mkdir $GIT

#PHP
bash $VIRTUE/scripts/php.sh

#Apache
bash $VIRTUE/scripts/apache.sh

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


#SSH Key
echo ">>> Generating SSH Key"
ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa > /dev/null 2>&1

echo " "
echo "All finished"
echo " "