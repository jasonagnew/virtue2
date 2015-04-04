#!/usr/bin/env bash

# Show the usage for NGXCB
function show_usage {
cat <<EOF

NGXCB:
Create a new Nginx Server Block (Ubuntu Server).
Assumes /etc/nginx/sites-available and /etc/nginx/sites-enabled setup used.

    -f    Force ngxcb to overwrite given server block file name
    -e    Enable the Server Block right away with NGXEN - i.e -e (without any value)
    -d    DocumentRoot - i.e. -d /vagrant/yoursite
    -h    Help - Show this menu.
    -n    The Server Block file name - default: vagrant - i.e. -n yoursite
    -s    ServerName - i.e. -s yoursite.com

EOF
exit 1
}

if [ $EUID -ne 0 ]; then
    echo "!!! Please use root: \"sudo NGXCB\""
    show_usage
fi

# Output Nginx Server Block Config
function create_server_block {

    # Default empty PHP Config
    PHP_NO_SSL=""

# Nginx Server Block config for PHP (without using SSL)
read -d '' PHP_NO_SSL <<EOF
        # pass the PHP scripts to php5-fpm
        # Note: \.php$ is susceptible to file upload attacks
        # Consider using: "location ~ ^/(index|app|app_dev|config)\.php(/|$) {"
        location ~ \.php$ {
            try_files \$uri =404;
            fastcgi_split_path_info ^(.+\.php)(/.+)$;
            # With php5-fpm:
            fastcgi_pass 127.0.0.1:9000;
            fastcgi_index index.php;
            include fastcgi_params;
            fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
            fastcgi_param HTTPS off;
        }
EOF

# Main Nginx Server Block Config
cat <<EOF
    server {
        listen 80;

        root $DocumentRoot;
        index index.html index.htm index.php app.php app_dev.php;

        # Make site accessible from ...
        server_name $ServerName;

        access_log /var/log/nginx/$ServerName-access.log;
        error_log  /var/log/nginx/$ServerName-error.log error;

        charset utf-8;

        location / {
            try_files \$uri \$uri/ /app.php?\$query_string /index.php?\$query_string;
        }

        location = /favicon.ico { log_not_found off; access_log off; }
        location = /robots.txt  { access_log off; log_not_found off; }

        error_page 404 /index.php;

        $PHP_NO_SSL

        # Deny .htaccess file access
        location ~ /\.ht {
            deny all;
        }
    }
EOF
}

function create_ssl_server_block {

    # Default empty PHP Config
    PHP_WITH_SSL=""

# Nginx Server Block config for PHP (with SSL)
read -d '' PHP_WITH_SSL <<EOF
        # pass the PHP scripts to php5-fpm
        # Note: \.php$ is susceptible to file upload attacks
        # Consider using: "location ~ ^/(index|app|app_dev|config)\.php(/|$) {"
        location ~ \.php$ {
            try_files \$uri =404;
            fastcgi_split_path_info ^(.+\.php)(/.+)$;
            # With php5-fpm:
            fastcgi_pass 127.0.0.1:9000;
            fastcgi_index index.php;
            include fastcgi_params;
            fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
            fastcgi_param HTTPS on;
        }
EOF


# Main Nginx Server Block Config
cat <<EOF
    server {
        listen 443;

        ssl on;
        ssl_certificate     $CertPath/$CertName.crt;
        ssl_certificate_key $CertPath/$CertName.key;

        root $DocumentRoot;
        index index.html index.htm index.php app.php app_dev.php;

        # Make site accessible from ...
        server_name $ServerName;

        access_log /var/log/nginx/$ServerName-ssl-access.log;
        error_log  /var/log/nginx/$ServerName-ssl-error.log error;

        charset utf-8;

        location / {
            try_files \$uri \$uri/ /app.php?\$query_string /index.php?\$query_string;
        }

        location = /favicon.ico { log_not_found off; access_log off; }
        location = /robots.txt  { access_log off; log_not_found off; }

        error_page 404 /index.php;

        $PHP_WITH_SSL

        # Deny .htaccess file access
        location ~ /\.ht {
            deny all;
        }
    }
EOF
}

# Check if there are enough arguments provided (2 arguments and there 2 values)
if [[ $# -lt 4 ]]; then
    echo "!!! Not enough arguments. Please read the below for NGXCB useage:"
    show_usage
fi

# The default for the optional argument's:
ServerBlockName="vagrant"
EnableServerBlock=0
NeedsReload=0
ForceOverwrite=0
CertPath=""
CertName=""


# Parse flags:
# - Run it in "silence"-mode by starting with a ":"
# - Single ":" after an argument means "required"
# - Double ":" after an argument means "optional"
while getopts ":hd:s:n::p::c::ef" OPTION; do
    case $OPTION in
        h)
            show_usage
            ;;
        d)
            DocumentRoot=$OPTARG
            ;;
        s)
            ServerName=$OPTARG
            ;;
        n)
            ServerBlockName=$OPTARG
            ;;
        p)
            CertPath=$OPTARG
            ;;
        c)
            CertName=$OPTARG
            ;;
        e)
            EnableServerBlock=1
            ;;
        f)
            ForceOverwrite=1
            ;;
        *)
            show_usage
            ;;
    esac
done

if [[ ! -d $DocumentRoot ]]; then
    mkdir -p $DocumentRoot
fi

if [[ $ForceOverwrite -eq 1 ]]; then
    # remove symlink from sites-enabled directory
    rm -f "/etc/nginx/sites-enabled/${ServerBlockName}" &>/dev/null
    if [[ $? -eq 0 ]]; then
        # if file has been removed, provide user with information that existing server 
        # block is being overwritten
        echo ">>> ${ServerBlockName} is enabled and will be overwritten"
        echo ">>> to enable this server block execute 'ngxen ${ServerBlockName}' or use the -e flag"
        NeedsReload=1
    fi
elif [[ -f "/etc/nginx/sites-available/${ServerBlockName}" ]]; then
    echo "!!! Nginx Server Block already exists. Aborting!"
    show_usage
fi

# Create the Server Block config
create_server_block > /etc/nginx/sites-available/${ServerBlockName}

# Add :443 handling
if [ "$CertPath" != "" ]; then
    create_ssl_server_block >> /etc/nginx/sites-available/${ServerBlockName}
fi

# Enable the Server Block and reload Nginx
if [[ $EnableServerBlock -eq 1 ]]; then
    # Enable Server Block
    ngxen -q ${ServerBlockName}

    # Reload Nginx
    NeedsReload=1
fi

[[ $NeedsReload -eq 1 ]] && service nginx reload
