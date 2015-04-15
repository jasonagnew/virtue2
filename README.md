# Virtue

Virute is super simple server setup. It offers a zero downtime deployment system with support for Composer, NPM etc. and with one command you can create an app with git deployment, domain & MySQL database.

**Note**: The server setup is heavy based on the awesome [Vaprobash](https://github.com/fideloper/Vaprobash)

## Requirements

Ubuntu Trusty v14 x64. It's designed for and is probably best to use a fresh VM. The installer will install everything it needs.

Please ensure you have set up your ssh keys, like so:

    $ cat ~/.ssh/id_rsa.pub | ssh [user]@[ip-address] "cat >> ~/.ssh/authorized_keys"

If you plan to use the server ssh on non-standard port (not 22) then on your local machine set this port for git:

    $ nano ~/.ssh/config

Add:

    Host [ip-address]
      Port [port]


## Installing

You can install Virtue directly on your server like so:

    $ curl -s -L https://raw.githubusercontent.com/jasonagnew/virtue2/master/tools/install.sh | bash -s [mysql-user] [mysql-password] [mysql-remote] [php-verson] [http-server] [server-user]

Please complete the variables in the brackets, examples below. The install may take around 5 minutes.

### Options

    [mysql-remote]     true|false
    [php-verson]       latest|previous|distributed  (5.6|5.5|5.4)
    [http-server]      apache|nginx

### Example

    $ curl -s -L https://raw.githubusercontent.com/jasonagnew/virtue2/master/tools/install.sh | bash -s root pass1234 true latest apache root

## Introducing Usher

Usher is Virtue's counterpart. It acts as management tool for your Mac or Linux system. You can built servers, deploy apps etc. from your local terminal. To install open your terminal and run:

    $ curl -s -L https://raw.githubusercontent.com/jasonagnew/virtue2/master/usher.sh?sd > /usr/local/bin/usher && sudo chmod a+x /usr/local/bin/usher

Lets build our first server, you can see the different options above.

    $ usher server:create [server-name] [ssh] [mysql-user] [mysql-password] [mysql-remote] [php-verson] [http-server]

Please complete the variables in the brackets, examples below. The install may take around 5 minutes.

    $ usher server:create my-server root@123.123.123.123 root pass1234 true latest apache root

You can also add a Virtue server to Usher after its been created directly by:

    $ usher server:add [server-name] [ssh]

### Create an App

Let's start by creating your app:

    $ usher app:create [server-name] [app-name] [domain] [git-remote]

Example below:

    $ usher app:create my-server my-app app.com git@github.com:user/repo.git

### Deploying an App

You can deploy your app like so:

    $ usher app:deploy [server-name] [app-name] [branch]

Example below:

    $ usher app:deploy my-server my-app master

**Note**: Please make sure your Server has access to the repo, to find out the servers SSH key see below

    $ usher server:key [server-name]

It's important to understand how Virtue deploys sites. Each deploy in pulled into a `{app}/releases/{timestamp}` and once everything is ready it's symbolic linked to `{app}/current`. This is great for allowing zero downtime between deploys however it poses a problem with persistent storage.

To handle persistent storage, folder permissions and any commands like `composer install` or `npm install`. Your app needs a `deploy.json`, see example:

    {
      "commands": [
        "composer install",
        "npm install",
        "gulp build"
      ],
      "storage": {
        "public/content/uploads": 775,
        "public/content/plugins": 775
      },
      "permissions": {
        "public/.htaccess": 644
      }
    }

If a command like `composer install` fails then release will not be set live.

### Rolling back a deploy

If you make mistake an deploy bad code you can rollback to previous release by:

    $ usher app:rollback [server-name] [app-name]

### Shortcuts for Deploy, Rollback & Setting .env

As you'll deploy and rollback more often than most commands they have shortcut along with syntax, to explain this better here are some examples:

    $ usher deploy my-app live master
    $ usher deploy my-app dev develop

    $ usher rollback my-app dev

To add these app based servers like `live` and `dev` you run:

    $ usher app:server [server-name] [app-name] [ssh]

Example below:

    $ usher app:server live my-app root@123.123.123.123

Or:

    $ usher app:server dev my-app root@111.111.111.111

#### Editing .env

You can easily edit an app's .env file

    $ usher env my-app live

### Link/Unlink a domain

You can link any domain to an app:

    $ usher app:link [server-name] [app-name] [domain]

Or if you need to unlink a domain:

    $ usher app:unlink [server-name] [app-name] [domain]

### Updating Git remote

You can update the git remote for an app:

    $ usher app:git [server-name] [app-name] [git-remote]

### Deleting an app

You can delete an app:

    $ usher app:delete [server-name] [app-name]

### Adding SSL to your app:

You can add either add certs or generate self-signed:

    $ usher app:ssl [server-name] [app-name] [domain] [path]

For self-signed:

    $ usher app:ssl my-server my-app app.com self-sign

Or provide path to certs on the server

    $ usher app:ssl my-server my-app app.com  my/path/on/server/to/certs

## License

MIT
