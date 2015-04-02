#!/bin/bash
set -e;

RED_BG='\e[41m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

function set_env() {
  sed -i -e "/$1=/ s/=.*/=$2/" $3
}

# Check if name is specified
if [[ $1 == app:* ]]; then
    if [[ -z $2 ]]; then
        echo "You must specify an app name"
        exit 1
    else
      APP="$2"
    fi
fi

# Check for config file
if [ ! -f ~/.virtue_config ]; then
    echo "Sorry your config file is missing: ~/.virtue_config"
    exit 1;
fi

# Load config file
source ~/.virtue_config

case "$1" in

  app:create)
    # Check Args
    if [[ -z $3 ]]; then
        echo "You must specify a domain"
        exit 1
    else
      DOMAIN="$3"
    fi

    if [[ -z $4 ]]; then
        echo "You must specify a git remote"
        exit 1
    else
      REMOTE="$4"
    fi

    # Setup Folders
    sudo mkdir -p $PUBLIC/$APP/$CURRENT
    sudo mkdir -p $PUBLIC/$APP/$RELEASES
    sudo mkdir -p $PUBLIC/$APP/$CONFIG
    sudo mkdir -p $PUBLIC/$APP/$STORAGE

    # Setup config files
    echo $REMOTE > $PUBLIC/$APP/$CONFIG/$SITE_REMOTE
    echo $DOMAIN > $PUBLIC/$APP/$CONFIG/$SITE_DOMAINS

    # Setup domain
    sudo vhost -s $DOMAIN -d $PUBLIC/$APP/$CURRENT/$ROOT

    # Setup MySQL Database
    mysql -u $MYSQL_USER -p$MYSQL_PASS -e "CREATE DATABASE ${APP//-/_}"

    # Write an .env file
    echo -e "DB_NAME=${APP//-/_}\nDB_USER=$MYSQL_USER\nDB_PASSWORD=$MYSQL_PASS\nDB_HOST=localhost" > $PUBLIC/$APP/$STORAGE/.env

    # Let people know where done
    echo "App created"
  ;;

  app:delete)

    if [ -d "$PUBLIC/$APP" ]; then
        # For each domain
        while read APP_DOMAIN; do
            # Diable & Remove domain
            sudo a2dissite $APP_DOMAIN
            service apache2 reload
            sudo rm -rf /etc/apache2/sites-available/$APP_DOMAIN.conf
        done <$PUBLIC/$APP/$CONFIG/$SITE_DOMAINS

        # Remove Folders
        sudo rm -rf $PUBLIC/$APP
        sudo rm -rf $SSL/$APP

        # Drop MySQL Database
        mysql -u $MYSQL_USER -p$MYSQL_PASS -e "DROP DATABASE ${APP//-/_}"

        # Let people know where done
        echo "App deleted"
    else
        echo "No app named $APP"
    fi
  ;;

  app:link)
    # Check Args
    if [[ -z $3 ]]; then
        echo "You must specify a domain"
        exit 1
    else
      DOMAIN="$3"
    fi

    # Add domain to config
    echo $DOMAIN >> $PUBLIC/$APP/$CONFIG/$SITE_DOMAINS

    # Setup domain
    sudo vhost -s $DOMAIN -d $PUBLIC/$APP/$CURRENT/$ROOT

    # Let people know where done
    echo "Domain linked"
  ;;

  app:unlink)
    # Check Args
    if [[ -z $3 ]]; then
        echo "You must specify a domain"
        exit 1
    else
      DOMAIN="$3"
    fi

    #Remove from config
    sed -i '/$DOMAIN/d' $PUBLIC/$APP/$CONFIG/$SITE_DOMAINS

    # Diable & Remove domain
    sudo a2dissite $DOMAIN
    service apache2 reload
    sudo rm -rf /etc/apache2/sites-available/$DOMAIN.conf
    sudo rm -rf $SSL/$APP/$DOMAIN

    # Let people know where done
    echo "Domain unlinked"
  ;;

  app:git)
    # Check Args
    if [[ -z $3 ]]; then
        echo "You must specify a git remote"
        exit 1
    else
      REMOTE="$3"
    fi

    # Add remote to config
    echo $REMOTE > $PUBLIC/$APP/$CONFIG/$SITE_REMOTE

    # Let people know where done
    echo "Remote changed"
  ;;

  app:deploy)
    # Check Args
    if [[ -z $3 ]]; then
        echo "You must specify a branch"
        exit 1
    else
      BRANCH="$3"
    fi

    echo ""
    echo -e "${GREEN}>>> Starting Deploy${NC}"

    # Create timestamp
    TIMESTAMP=$(date +%s)
    # Get git remote
    REMOTE=$(cat $PUBLIC/$APP/$CONFIG/$SITE_REMOTE)

    echo -e "${YELLOW}>>> Cloning Repo${NC}"
    # Git clone into timestamp folder
    git clone -b $BRANCH --depth=1 $REMOTE $PUBLIC/$APP/$RELEASES/$TIMESTAMP

     #Lets jump into realease
     cd $PUBLIC/$APP/$RELEASES/$TIMESTAMP

    # Check for deploy file
    set +e;
    if [ -f deploy.json ]; then
    (
        echo -e "${YELLOW}>>> Running deploy.json${NC}"
        #Fecth config
        COMMANDS=$(jq -r '.commands | keys | .[]' deploy.json)
        STORAGE_DIRS=$(jq -r '.storage | keys | .[]' deploy.json)
        PERMISSIONS_DIRS=$(jq -r '.permissions | keys | .[]' deploy.json)

        # Loop commands
        for INDEX in ${COMMANDS[@]}
        do
          COM=$(jq -r --arg var $INDEX '.commands | .[$var | tonumber]' deploy.json)
          echo -e "${YELLOW}>>> Running Command: $COM ${NC}"
          eval $COM
        done

        # Loop storage directories
        for DIR in ${STORAGE_DIRS[@]}
        do
            # Fetch premissons
            PERMISSION=$(jq -r --arg var $DIR '.storage[$var]' deploy.json)

            echo -e "${YELLOW}>>> Setting Storage Directory: ${DIR} ${NC}"

            # Remove current release folder
            rm -rf $PUBLIC/$APP/$RELEASES/$TIMESTAMP/$DIR

            # Make sure the folder exists in APP/STORAGE directory
            mkdir -p $PUBLIC/$APP/$STORAGE/$DIR

            # Set permissions
            chmod -R $PERMISSION $PUBLIC/$APP/$STORAGE/$DIR

            # Setup link
            ln -nfs $PUBLIC/$APP/$STORAGE/$DIR $PUBLIC/$APP/$RELEASES/$TIMESTAMP/$DIR
        done

        # Loop file premissions
        for DIR in ${PERMISSIONS_DIRS[@]}
        do
            # Fetch premissons
            PERMISSION=$(jq -r --arg var $DIR '.permissions[$var]' deploy.json)

            echo -e "${YELLOW}>>> Setting Permission: ${DIR} ${NC}"

            # Set permissions
            chmod -R $PERMISSION $PUBLIC/$APP/$RELEASES/$TIMESTAMP/$DIR
        done
    )
    if [ $? -ne 0 ]; then
        rm -rf $PUBLIC/$APP/$RELEASES/$TIMESTAMP
        echo ""
        echo -e "${RED_BG}>>> Deploy Failed${NC}"
        echo ""
        exit 1
    fi
  fi
  set -e;

    echo -e "${YELLOW}>>> Setting Release Live ${NC}"

    # Set release live
    rm -rf $PUBLIC/$APP/$CURRENT
    ln -nfs $PUBLIC/$APP/$STORAGE/.env $PUBLIC/$APP/$RELEASES/$TIMESTAMP/.env
    ln -nfs $PUBLIC/$APP/$RELEASES/$TIMESTAMP $PUBLIC/$APP/$CURRENT
    sudo service php5-fpm reload

    # Clear out older realeases
    ls -dt $PUBLIC/$APP/$RELEASES/* | tail -n +6 | xargs -d '\n' rm -rf;

    # Let people know where done
    echo ""
    echo -e "${GREEN}>>> Deploy Successful${NC}"
    echo ""
  ;;

  app:rollback)

    # Reset symblinks back previous realase
    PREVIOUS=$(ls -dt $PUBLIC/$APP/$RELEASES/* | tail -n +2 | head -1)

    cd $PREVIOUS
    STORAGE_DIRS=$(jq -r '.storage | keys | .[]' deploy.json)

    # Loop storage directories
    for DIR in ${STORAGE_DIRS[@]}
    do
        # Fetch premissons
        PERMISSION=$(jq -r --arg var $DIR '.storage[$var]' deploy.json)

        # Remove current release folder
        rm -rf $PREVIOUS/$DIR

        # Make sure the folder exists in APP/STORAGE directory
        mkdir -p $PUBLIC/$APP/$STORAGE/$DIR

        # Set permissions
        chmod -R $PERMISSION $PUBLIC/$APP/$STORAGE/$DIR

        # Setup link
        ln -nfs $PREVIOUS/$DIR $PUBLIC/$APP/$STORAGE/$DIR
    done

    rm -rf $PUBLIC/$APP/$CURRENT
    ln -nfs $PREVIOUS $PUBLIC/$APP/$CURRENT
    sudo service php5-fpm reload

    # Clear latest realease
    ls -dt $PUBLIC/$APP/$RELEASES/* | head -1 | xargs -d '\n' rm -rf;

    # Let people know where done
    echo "Rollback completed"
  ;;

  app:ssl)
    # Check Args
    if [[ -z $3 ]]; then
        echo "You must specify a domain"
        exit 1
    else
      DOMAIN="$3"
    fi

    sudo mkdir -p $SSL/$APP/$DOMAIN

    if [ $4 = "self-sign" ]; then
    openssl genrsa -out $SSL/$APP/$DOMAIN/server.key 1024
    touch $SSL/$APP/$DOMAIN/openssl.cnf
    cat >> $SSL/$APP/$DOMAIN/openssl.cnf <<EOF
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

    openssl req -config $SSL/$APP/$DOMAIN/openssl.cnf -new -key $SSL/$APP/$DOMAIN/server.key -out $SSL/$APP/$DOMAIN/server.csr
    openssl x509 -req -days 1024 -in $SSL/$APP/$DOMAIN/server.csr -signkey $SSL/$APP/$DOMAIN/server.key -out $SSL/$APP/$DOMAIN/server.crt

    else
        # Check Args
        if [[ -z $4 ]]; then
            echo "You must specify path to SSL- CRT & KEY"
            exit 1
        else
          PATH="$4"
        fi

         # Check Args
        if [[ -z $5 ]]; then
            echo "You must specify path to name for CRT & KEY"
            exit 1
        else
          NAME="$5"
        fi

        mv $PATH/$NAME.crt $SSL/$APP/$DOMAIN/server.crt
        mv $PATH/$NAME.key $SSL/$APP/$DOMAIN/server.key
    fi

    sudo vhost -s $DOMAIN -d $PUBLIC/$APP/$CURRENT/$ROOT -p $SSL/$APP/$DOMAIN -c server

    echo "SSL Added"

  ;;

  app:env)
    nano $PUBLIC/$APP/$STORAGE/.env
  ;;

  server:key)
    cat ~/.ssh/id_rsa.pub
  ;;

  -v)
    echo "Verison 2.0"
  ;;

  update)
    echo "Updating..."
    curl -L -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/jasonagnew/virtue2/master/virtue.sh > /usr/local/bin/virtue
    sudo chmod a+x /usr/local/bin/virtue
    echo "Update complete"
    exit 1
  ;;

  *)
    echo "Virtue"
    echo "app:create   <app-name> <domain> <git-remote>  Create app"
    echo "app:delete   <app-name>                        Delete app"
    echo "app:link     <app-name> <domain>               Link domain to app"
    echo "app:unlink   <app-name> <domain>               Unlink domain to app"
    echo "app:git      <app-name> <git-remote>           Set new git-remote"
    echo "app:deploy   <app-name> <branch>               Deploy branch"
    echo "app:rollback <app-name>                        Rollback deployment"
    echo "app:ssl      <app-name> <domain> <path>        Add SSL"
    echo "app:env      <app-name>                        Edit .env"
    echo "server:key                                     Get SSH Key"
    echo "-v                                             Check verison"
    echo "update                                         Update Virtue"
  ;;

esac
