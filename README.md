# dev-replica
Pair of Docker images for Apache2 Webserver and MySQL as a read-replica against a remote master.

### Requirements:
* Docker
* Terminal/CLI skills
* Further details for [Webserver Config](webserver/README.md)

### Setup / Config:

* `git clone https://github.com/Wier-Stewart/dev-replica.git`
* Rename `webserver.sample` to `webserver.env` and fill in the info.
* Rename `mysql_slave.sample` to `mysql_slave.env` and fill in the info.
* Edit the `volumes` line ` ~/domains/:/var/www/domains` to fit the pattern: `/local-path/on-mac/to-domains/:/varwww/domain`
* Set your `/etc/hosts` to be `127.0.0.1  local.domain.com`. If you're on a Mac, this is easier: [Gasmask](https://github.com/2ndalpha/gasmask).

#### Server Info

Once `docker-compose run` is up:
* The site `local.domain.com` should be available.
* The database should be accessible via the `localhost` server name on port 3306.

E.g., your wp-config.php file would have a line like this:
```
 define('DB_HOST', 'localhost');
```

## Docker Commands:
### To Start the Environment the First Time
```
$ docker-compose build
$ docker-compose up
```

### To Start and Stop the Environment
```
$ docker-compose up
$ docker-compose stop
```

### To Clear the Environment - will need to build after this
```
$ docker-compose stop
Stopping webserver   ... done
Stopping mysql_slave ... done

$ docker rm webserver

$ docker rm mysql_slave

$ docker volume prune
WARNING! This will remove all volumes not used by at least one container.
Are you sure you want to continue? [y/N] y
```