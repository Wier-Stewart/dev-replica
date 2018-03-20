#!/bin/bash
##
## docker run -i
##      -p 8080:80  # port fwding
##      --env-file .env     # env vars
##      -v /host/directory:/container/directory     # volume
##      -t ws-wordpress:latest      # tag
##
## Start the container:
## docker run -d -t -v ~/Desktop/Development/:/var/www/domains -p 80:80 --env-file .env  ws-wordpress:latest
##
## Get Shell access to it once running:
## docker exec -it 692e20ff49fa /bin/bash
##
## reachable at localhost:8080. bleh

#set -euo pipefail

#         name: Startup processes
setup_webserver() {
    echo "";
    echo "------------------------- Setup Webserver -----------------------------";

    DOCUMENT_ROOT="/var/www/domains/"
    mkdir -p "$DOCUMENT_ROOT"

    apachectl configtest;

    service apache2 restart;

    #          name: Config PHP to not complain about timezones
    if [ -d "/usr/local/etc/php/" ]; then
      echo "date.timezone = 'America/New_York'" >> /usr/local/etc/php/php.ini;
      echo "error_reporting = E_ALL ^ E_DEPRECATED" >> /usr/local/etc/php/php.ini;
    fi


}

add_to_hosts(){
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
    echo "------------------------- Setup Domain -----------------------------";

    cd "${DOCUMENT_ROOT}"
# mkdir -p "${DOCUMENT_ROOT}/${DOMAIN_NAME}/local"
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
        cat wp-config-local.php

#          name: Download WordPress into ./ directory
        which wp;
        wp core download  --allow-root --force --debug;
        ls -la;

#          name: Install WP
#            wp core verify-checksums --allow-root; # slooow
        wp core install --allow-root  --debug  --admin_name=admin --admin_password=admin --admin_email="";

#          name: Test Webserver for Wordpress
#            curl http://localhost/index.php;
#            curl -I http://localhost/;
#            curl http://localhost/wp-login.php;

#          name: Config Wordpress
        wp theme install  --force --allow-root ;
        export HAVE_UNDERSTRAP= $(ls ./wp-content/themes/understrap-*  1> /dev/null 2>&1);
        if [ $HAVE_UNDERSTRAP ]; then
           mv ./wp-content/themes/understrap-* ./wp-content/themes/understrap;
        fi
        wp plugin list --field=name --allow-root;
        PLUGINS=$(wp plugin install --force --allow-root || : );
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

        mkdir -p  ./wp-content/uploads;

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
            npm install --save-dev gulp-sass gulp-plumber gulp-rename gulp-autoprefixer gulp-concat gulp-cache gulp-imagemin gulp-uglify browser-sync fs-exists;
            npm install --save-dev gulp;
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
            find ./wp-content/themes/ -cmin -2;
            echo "Check that a css file was generated: ";
            ls -l ./wp-content/themes/*/style.css;
            # https://www.quora.com/What-is-the-difference-between-mtime-atime-and-ctime
}

keep_alive(){
    echo "";
    echo "------------------------- Keep Apache Alive -----------------------------";

    service apache2 stop;
    /usr/sbin/apache2ctl -D FOREGROUND
}

#          name: Permissions
#            chmod -R 775 .;
#            chmod -R 777 ./wp-content/uploads;


# bare minimum: be a better (multi-domain) MAMP.
setup_webserver;
add_to_hosts;

# if a single domain is spec'd in .env - then run the whole system (for circleCI)
if [ ! -z "$DOMAIN_NAME" ]; then
    echo "Setting up $DOMAIN_NAME : ";
    setup_domain "${DOMAIN_NAME}";
    setup_wordpress "${DOMAIN_NAME}";
    setup_node "${DOMAIN_NAME}";
    run_gulp "${DOMAIN_NAME}";
fi

# if we're not on CircleCI, then run like MAMP
if [ -z "$DOMAIN_NAME" ]; then
    keep_alive;
fi
#ls -ltar "$DOCUMENT_ROOT"

