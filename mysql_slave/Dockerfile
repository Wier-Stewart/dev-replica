FROM ubuntu:16.04
MAINTAINER Mark Wallace "mark@wierstewart.com"
## Sourced from: github.com/Martin91/mysql-replication.git

ENV DEBIAN_FRONTEND=noninteractive

RUN mv /etc/apt/sources.list /etc/apt/sources.list.bak
ADD ./sources.list /etc/apt/sources.list
RUN apt-get -y update && apt-get install -y debconf-utils

RUN { \
        echo mysql-server mysql-server/root-pass password root; \
        echo mysql-server mysql-server/root_password_again password root; \
        echo mysql-server-5.7 mysql-server/root-pass password root; \
        echo mysql-server-5.7 mysql-server/root_password_again password root; \
    } | debconf-set-selections

RUN apt-get install --reinstall tzdata

RUN apt-get update && apt-get install -y mysql-server-5.7

ADD ./start_mysql_server.sh /usr/local/bin/start_mysql_server.sh
RUN chmod +x /usr/local/bin/start_mysql_server.sh

EXPOSE 3306

CMD ["/usr/local/bin/start_mysql_server.sh"]
