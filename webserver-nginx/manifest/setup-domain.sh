#!/bin/bash
set -e

COMMAND=$1
DOMAIN_NAME=$2
DB_NAME=$3

if [[ $# -lt 3 ]] ; then
    echo 'To use this command: setup-domain.sh initialize domain.com'
    echo 'Alternate, if already initialized: setup-domain.sh add domain.com'
    echo "You only provided: $1 $2 $3"
    exit 0
fi

DOCUMENT_ROOT="/var/www/domains/"


add_all_to_hosts(){
    echo "";
    echo "------------------------- Adding Hosts -----------------------------";

    cd "$DOCUMENT_ROOT";
    domainlist=$(find . -name 'local' -type d -maxdepth 2 | cut -d'/' -f2);

    for fn in $domainlist; do
        echo "127.0.0.1 local.$fn" >> /etc/hosts
    done

    cat  /etc/hosts

}


#      - checkout: -v ~/Desktop/Development/domain.com/local:/var/www/html

setup_domain() {
    echo "";
    echo "------------------------- Setup Domain --------------------------------";

if [ -d "${DOCUMENT_ROOT}/${DOMAIN_NAME}/local" ]; then
echo "";
else
echo "Please checkout the git repo for ${DOMAIN_NAME} first."
exit 0;
fi

#    cd "${DOCUMENT_ROOT}"
#    mkdir -p "${DOCUMENT_ROOT}/${DOMAIN_NAME}/local"
# local/dev/preview ?
# cp -r /var/www/html/node_modules to ${DOCUMENT_ROOT}/${DOMAIN_NAME}/local  ??

}

setup_wordpress() {
        echo "";
        echo "------------------------- Setup Wordpress -----------------------------";

        cd "${DOCUMENT_ROOT}/${DOMAIN_NAME}/local";
#          name: Setup a local wp-config for db vars
        echo "<?php " > wp-config-local.php
        echo " define('DB_HOST', '$DB_HOST');" >> wp-config-local.php;
        echo " define('DB_NAME', '$DB_NAME');" >> wp-config-local.php;
        echo " define('DB_USER', '$DB_USER');" >> wp-config-local.php;
        echo " define('DB_PASSWORD', '$DB_PASSWORD');" >> wp-config-local.php;
#        cat wp-config-local.php

#          name: Download WordPress into ./ directory
        which wp;
        wp core download  --allow-root --force --debug;
        ls -la;

        mkdir -p  ./wp-content/uploads;


#          name: Test Webserver for Wordpress
#            curl http://localhost/index.php;
#            curl -I http://localhost/;
#            curl http://localhost/wp-login.php;
}

add_plugins(){
        echo "";
        echo "------------------------- Add Wordpress Plugins -----------------------------";

        cd "${DOCUMENT_ROOT}/${DOMAIN_NAME}/local";
        echo "";
        echo "Existing Plugins.."
        wp plugin list --field=name --allow-root;
        echo "";
        echo "Installing Plugins.."
        wp plugin install --force --allow-root
        #PLUGINS=$(  || : );
}

init_wordpress() {
        echo "";
        echo "------------------------- Initialize Wordpress  -----------------------------";

        cd "${DOCUMENT_ROOT}/${DOMAIN_NAME}/local";

#          name: Install WP
#            wp core verify-checksums --allow-root; # slooow
        wp core install --allow-root  --debug  --admin_name=admin --admin_password=admin --admin_email="";

        wp theme install  --force --allow-root ;
        export HAVE_UNDERSTRAP= $(ls ./wp-content/themes/understrap-*  1> /dev/null 2>&1);
        if [ $HAVE_UNDERSTRAP ]; then
           mv ./wp-content/themes/understrap-* ./wp-content/themes/understrap;
        fi

        add_plugins "${DOMAIN_NAME}";

        echo "";
        echo "------------------------- Plugins -----------------------------";
        echo " $PLUGINS  ";
        wp plugin activate advanced-custom-fields-pro --allow-root;
        wp plugin activate wordpress-seo  --allow-root;
        echo "";
        echo "------------------------- Config -----------------------------";
        wp option update timezone_string America/New_York  --allow-root;
        wp option update blogdescription ""  --allow-root;
        wp option update default_pingback_flag 0  --allow-root;
        wp option update default_ping_status 0  --allow-root;
        wp option update default_comment_status 0  --allow-root;
        wp option update comment_registration 1  --allow-root;
        wp rewrite structure '/%category%/%postname%/'  --allow-root;
        wp rewrite flush --hard  --allow-root;

#      name: Dump WP DB
        mkdir -p ./wp-content/backup-db;
        wp db export ./wp-content/backup-db/$(echo ${DOMAIN_NAME} | cut -d'.' -f1).sql --allow-root ;
}


#### Node Modules:

setup_node() {
            echo "";
            echo "------------------------- Node.js -----------------------------";

            cd "${DOCUMENT_ROOT}/${DOMAIN_NAME}/local";
#          name: Node Packages
            node -v;
            npm -v;
            npm install backstopjs;
            npm --unsafe-perm install node-sass; # https://github.com/sass/node-sass/issues/2006
            npm install -g  --unsafe-perm  gulp-sass gulp-plumber gulp-rename gulp-autoprefixer gulp-concat gulp-cache gulp-imagemin gulp-uglify browser-sync fs-exists ajv gulp;
            npm install  --unsafe-perm ;
            npm rebuild node-sass --unsafe-perm  --force;
            npm up --dev;
#            npm install -g npm@latest;
}

run_gulp() {
            echo "";
            echo "------------------------- Gulp -----------------------------";

            cd "${DOCUMENT_ROOT}/${DOMAIN_NAME}/local";
#          name: Run Gulp
            gulp styles;
            gulp scripts;
            echo "Gulp'd files: (edited in last 2 minutes)"
            find ./wp-content/themes/ -mmin -2;
            echo "Check that a css file was generated: ";
            ls -l ./wp-content/themes/*/style.css;
            # https://www.quora.com/What-is-the-difference-between-mtime-atime-and-ctime
}


# bare minimum: be a better (multi-domain) MAMP.
#setup_webserver;
#add_to_hosts;

# if a single domain is spec'd in .env - then run the whole system (for circleCI)
if [ ! -z "$DOMAIN_NAME" ]; then

    echo "127.0.0.1 local.$DOMAIN_NAME" >> /etc/hosts

    echo "Setting up $DOMAIN_NAME : ";
    setup_domain "${DOMAIN_NAME}";
    setup_wordpress "${DOMAIN_NAME}";

    if [ "$COMMAND" == 'initialize' ]; then
        init_wordpress "${DOMAIN_NAME}";
    else
        add_plugins "${DOMAIN_NAME}";
    fi

    setup_node "${DOMAIN_NAME}";
    run_gulp "${DOMAIN_NAME}";

    echo "Domain addition completed";
fi