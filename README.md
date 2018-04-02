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
* Edit `docker-compose.yml` file: set the `volumes` line that looks like this ` ~/domains/:/var/www/domains` to fit the pattern: `/local-path/on-mac/to-domains/:/var/www/domains`
* Set your `/etc/hosts` to be `127.0.0.1  local.domain.com`. If you're on a Mac, this is easier: [Gasmask](https://github.com/2ndalpha/gasmask).

#### Server Info

Once `docker-compose run` is up:
* The site `local.domain.com` should be available.
* The database should be accessible via `127.0.0.1` (not `localhost` oddly) on port 3306 from your Mac.
* The database will be accessible via `mysql_slave` from the webserver

E.g., your wp-config.php file would have a line like this:
```
 define('DB_HOST', 'mysql_slave');
```

## Wordpress Integration
The goal is to have all database-reads go to `mysql_slave` locally, and all database-writes
go to the remote master db. For this, WordPress requires [HyperDB](https://wordpress.org/plugins/hyperdb).

It's not a normal plugin installation, and really only requires 2 files:

#### ./db-config.php
Here's a mini version that will work with the usual wp-config.php variables:
```
<?php
//./db-config.php
$wpdb->save_queries = true;
$wpdb->persistent = false;
$wpdb->max_connections = 10;
$wpdb->check_tcp_responsiveness = true;
//replicate on local.domain.com only

if( defined( "WP_CLI" ) && WP_CLI ){
    //don't say anything, it can mess with output parsing!
}else if(stripos($_SERVER['HTTP_HOST'], 'local.')!==false ){ //replicate if local, only, not dev or preview
    $wpdb->add_database(array(
        "host"     => "mysql_slave",     // If port is other than 3306, use host:port.
        "user"     => DB_USER,
        "password" => DB_PASSWORD,
        "name"     => DB_NAME,
        "write"    => 0,
        "read"     => 1,        // replication_ok() here is preferred.
        "dataset"  => "global",
        "timeout"  => 0.5,
    ));
}

$wpdb->add_database(array(
	"host"     => DB_HOST,     // If port is other than 3306, use host:port.
	"user"     => DB_USER,
	"password" => DB_PASSWORD,
	"name"     => DB_NAME,
	"write"    => 1,
	"read"     => 1,
	"dataset"  => "global",
	"timeout"  => .9,
));

```

#### wp-content/db.php
[save this](https://plugins.svn.wordpress.org/hyperdb/trunk/db.php) to `./wp-content/db.php`


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