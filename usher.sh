#!/bin/bash
set -e;

# Set storage path and make sure we create it
STORAGE='/usr/local/bin/.usher'
mkdir -p $STORAGE

if [[ $1 == *:* ]]; then
    if [[ -z $2 ]]; then
        echo "You must specify an server name"
        exit 1
    else
      SERVER="$2"
    fi
fi

case "$1" in
  server:create)

    if [[ -z $3 ]]; then
        echo "You must specify an ssh root@ip"
        exit 1
    else
      SSH="$3"
    fi

    # Setup config files
    echo $SSH > $STORAGE/$SERVER.config

    ssh -t $SSH 'curl -s -L https://raw.githubusercontent.com/jasonagnew/virtue2/master/tools/install.sh | bash -s "${@:4}"'

    # Added
    echo "Server created"
  ;;

  server:add)

    if [[ -z $3 ]]; then
        echo "You must specify an ssh root@ip"
        exit 1
    else
      SSH="$3"
    fi

    # Setup config files
    echo $SSH > $STORAGE/$SERVER.config

    # Added
    echo "App added"
  ;;

  app:server)

    if [[ -z $3 ]]; then
        echo "You must specify an app name"
        exit 1
    else
      APP="$3"
    fi

    if [[ -z $4 ]]; then
        echo "You must specify an ssh root@ip"
        exit 1
    else
      SSH="$4"
    fi

    mkdir -p $STORAGE/$APP

    # Setup config files
    echo $SSH > $STORAGE/$APP/$SERVER.config

    echo "App server added"
  ;;

  app:*)

  # Check if name is specified
    if [[ -z $3 ]]; then
        echo "You must specify an app name"
        exit 1
    else
      APP="$3"
    fi

    # Setup config files
    SSH=$(cat $STORAGE/$SERVER.config)

    ssh -t $SSH virtue $1 "${@:3}"

    # Added
    echo "App command completed"
  ;;

   deploy)

  # Check if name is specified
    if [[ -z $2 ]]; then
        echo "You must specify an app name"
        exit 1
    else
      APP="$2"
    fi

      # Check if name is specified
    if [[ -z $3 ]]; then
        echo "You must specify an server name"
        exit 1
    else
      SERVER="$3"
    fi

    if [[ -z $4 ]]; then
        echo "You must specify a branch"
        exit 1
    else
      BRANCH="$4"
    fi

    # Setup config files
    SSH=$(cat $STORAGE/$APP/$SERVER.config)

    ssh -t $SSH virtue app:deploy $APP $BRANCH

    # Added
    echo "Deploy Ended"
  ;;

  rollback)

  # Check if name is specified
    if [[ -z $2 ]]; then
        echo "You must specify an app name"
        exit 1
    else
      APP="$2"
    fi

      # Check if name is specified
    if [[ -z $3 ]]; then
        echo "You must specify an server name"
        exit 1
    else
      SERVER="$3"
    fi

    # Setup config files
    SSH=$(cat $STORAGE/$APP/$SERVER.config)

    ssh -t $SSH virtue app:rollback $APP

    # Added
    echo "Rollback Ended"
  ;;


   env)

  # Check if name is specified
    if [[ -z $2 ]]; then
        echo "You must specify an app name"
        exit 1
    else
      APP="$2"
    fi

      # Check if name is specified
    if [[ -z $3 ]]; then
        echo "You must specify an server name"
        exit 1
    else
      SERVER="$3"
    fi

    # Setup config files
    SSH=$(cat $STORAGE/$APP/$SERVER.config)

    ssh -t $SSH virtue app:env $APP

    # Added
    echo "Env Ended"
  ;;

  server:key)
    # Setup config files
    SSH=$(cat $STORAGE/$SERVER.config)

    ssh -t $SSH virtue server:key

    # Added
    echo "Server command completed"
  ;;

  -v)
    echo "Verison 2.0"
  ;;

  update)
    echo "Updating..."
    curl -L -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/jasonagnew/virtue2/master/usher.sh > /usr/local/bin/usher
    sudo chmod a+x /usr/local/bin/usher
    echo "Update complete"
    exit 1
  ;;

  *)
    echo "Usher"
    echo "deploy        <app-name> <server> <branch>    Deploy"
    echo "rollback      <app-name> <server>             Rollback"
    echo "env           <app-name> <server>             Env"
    echo "server:create <server-name> <ssh>             Create server using Virtue"
    echo "server:add    <server-name> <ssh>             Add a Virtue server"
    echo "server:key    <server-name>                   Get server SSH Key"
    echo "app:server    <server-name> <app-name> <ssh>  Add server under App"
    echo "app:*         <server-name> <args>            Run virtue app commands"
    echo "-v                                            Check verison"
    echo "update                                        Update Virtue"
  ;;

esac
