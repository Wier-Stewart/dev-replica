#!/bin/bash
set -e

#service nginx stop
#service php-fpm7 stop


DOCUMENT_ROOT="/var/www/domains/"

chmod -R 777 /var/www/html/status

add_to_hosts(){
    echo "";
    echo "------------------------- Adding Hosts -----------------------------";

    cd "$DOCUMENT_ROOT";
    domainlist=$(find . -name 'local' -type d -maxdepth 2 | cut -d'/' -f2);

    for domain in $domainlist; do
        echo "127.0.0.1 local.$domain" >> /etc/hosts
    done

    cat  /etc/hosts
}

add_to_hosts;

# fix reporting
sed -i -e "s/error_reporting =.*=/error_reporting = E_ALL/g" /etc/php7/php.ini
#php-fpm.conf
sed -i -e "s/display_errors =.*/display_errors = stdout/g" /etc/php7/php.ini
#php-fpm.conf

# Disable opcache
#sed -i -e "s/zend_extension=opcache.so/;zend_extension=opcache.so/g" /etc/php.d/zend-opcache.ini



#========================

# Start Services
exec /usr/bin/supervisord --nodaemon -c /etc/supervisord.conf
