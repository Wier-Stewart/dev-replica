FROM alpine:3.7
MAINTAINER wierstewart <mark@wierstewart.com>

# Set PHP version (allow it to be overridden at build time)
ARG PHP_VER="7.1.18"

ENV WEBROOT_DIR=/var/www

RUN mkdir -p /run/nginx

RUN apk update \
    && apk --no-cache add bash nginx php7 php7-fpm \
       php7-apcu php7-bcmath php7-bz2 php7-calendar php7-ctype php7-curl php7-dba php7-dom php7-exif php7-fileinfo php7-ftp php7-gd php7-gettext php7-iconv php7-imagick php7-imap php7-json php7-mbstring php7-mcrypt php7-mysqli php7-mysqlnd php7-openssl php7-pdo php7-pdo_mysql php7-phar php7-posix php7-session php7-shmop php7-simplexml php7-snmp php7-soap php7-sockets php7-sysvmsg php7-sysvsem php7-sysvshm php7-tokenizer php7-wddx php7-xml php7-xmlreader php7-xmlwriter php7-xsl php7-zip php7-zlib \
    && mkdir -p ${WEBROOT_DIR} \
    && chown -R nginx:nginx ${WEBROOT_DIR}
#    && ln -s /usr/sbin/php-fpm7 /usr/bin/php-fpm

RUN apk update \
    && apk --no-cache add python2 py2-pip \
    && pip install --upgrade pip

RUN  pip install supervisor \
    && pip install supervisor-stdout


EXPOSE 80/tcp 443/tcp


#FROM boxedcode/alpine-nginx-php-fpm

COPY ./manifest/ /

RUN chmod +x /*.sh
RUN /bin/bash -c 'chmod -R 777 ${WEBROOT_DIR}/html/status'

# cleanup error reporting
#RUN sed -i -e "s/error_reporting =.*=/error_reporting = E_ALL/g" /usr/etc/php.ini
#RUN sed -i -e "s/display_errors =.*/display_errors = stdout/g" /usr/etc/php.ini
#RUN sed -i -e "s/html_errors = On/html_errors = Off/g" /usr/etc/php.ini
#RUN sed -i -e "s/display_errors =.*/display_errors = Off/g" /usr/etc/php.ini


############################## Config for WS

# Install Things :D
#RUN apk update \
#  && apk add ca-certificates wget update-ca-certificates

RUN apk update \
  && apk add gnupg openssh-client git sshpass lftp curl zip unzip bzip2 python mysql-client

# Install zip command, bz2 for phantom install
# RUN apk add zip unzip bzip2 python mysql-client


############################## Install Node:

RUN apk update \
  && apk add nodejs nodejs-npm apk-tools-static busybox-static make g++ file

RUN ls -l /usr/bin/node
RUN node -v

# Update to latest stable node -- nope.
#RUN npm install -g n

#RUN n stable
#RUN which node
#RUN node -v

# Add gulp globally
RUN npm install -g gulp


############################## Install DevTools, etc:



# Install AWS CLI to export artifacts to S3
RUN set -ex; \
	\
     python -V; \
     curl -sS https://bootstrap.pypa.io/get-pip.py | python -; \
     pip install awscli --upgrade --user; \
     export PATH="$HOME/.local/bin:$PATH"; \
     ~/.local/bin/aws --version;


# Install WP-CLI
RUN set -ex; \
	\
     curl -sSO https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar; \
     chmod +x wp-cli.phar; \
     mv wp-cli.phar /usr/local/bin/wp

# Install Chrome
RUN apk add chromium


##############################

RUN /bin/bash -c 'chmod -R 777 /var/www/html/status'

ENTRYPOINT ["/entrypoint-ws.sh"]
