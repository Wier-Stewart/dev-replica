FROM wordpress
## docker run -i  -v  ~/Desktop/Development/domain.com/local:/var/www/html  -p 8080:80  --env-file .env -t ws-wordpress:latest 
# https://circleci.com/blog/using-docker-effectively-on-circleci/

EXPOSE 80

COPY ./docker-entrypoint.sh /

RUN service apache2 stop;

RUN a2enmod vhost_alias;

COPY ./apache-multidomain.conf /etc/apache2/sites-enabled/

ENTRYPOINT ["/docker-entrypoint.sh"]

# Install Node
RUN set -ex; \
	\
	apt-get update; \
	apt-get -y install wget gnupg2 openssh-client git sshpass lftp curl apt-transport-https ca-certificates; \
     curl --fail -ssL -o setup-nodejs https://deb.nodesource.com/setup_9.x; \
     bash setup-nodejs; \
     apt-get install -y nodejs build-essential; 


# Test out apt, install zip command, bz2 for phantom install
RUN set -ex; \
	\
     apt-get update; \
     apt-get -y install zip unzip bzip2 python mysql-client gnupg2 wget; 


# Install npm .. should already be thx to node6?
#RUN curl https://www.npmjs.com/install.sh | sh 
RUN npm -v
RUN npm install npm@latest -g
RUN npm -v


# Install Gulp, etc
#### Gulp needs local & global. sheesh
RUN npm install -g gulp


# Install AWS CLI to export artifacts to S3
RUN set -ex; \
	\
     python -V; \
     curl https://bootstrap.pypa.io/get-pip.py | python -; \
     pip install awscli --upgrade --user; \
     export PATH="$HOME/.local/bin:$PATH"; \
     ~/.local/bin/aws --version;


# Install WP-CLI
RUN set -ex; \
	\
     curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar; \
     chmod +x wp-cli.phar; \
     mv wp-cli.phar /usr/local/bin/wp

RUN { \
		echo "deb http://dl.google.com/linux/chrome/deb/ stable main"; \
	} > /etc/apt/sources.list.d/google-chrome.list

# Install Chrome
#     echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list \

RUN set -ex; \
	\
     wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub > linux_signing_key.pub ; \
     apt-key add linux_signing_key.pub ; \
     apt-get update; \
     apt-get install -y google-chrome-unstable libfontconfig1 dnsutils;

#            echo "Chrome-Path:";
#            echo $CHROME_PATH;
#            which chromium;
#            apt-get -y install libfontconfig1;


# Install backstop, et al, now that we have chrome
RUN set -ex; \
	\
    npm install backstopjs; \
    npm install --save-dev gulp-sass gulp-plumber gulp-rename gulp-autoprefixer gulp-postcss gulp-concat gulp-cache gulp-imagemin gulp-uglify browser-sync fs-exists; \
    npm install --save-dev gulp; 
 
 

# USER circleci

#CMD ["apache2-foreground"]