#! /bin/bash
## Sourced from: github.com/Martin91/mysql-replication.git
## Sourced from: github.com/thanhson1085/docker-mysql-replication.git


/etc/init.d/mysql stop


#### CONFIG:

_datadir() {
    "$@" --verbose --help 2>/dev/null | awk '$1 == "datadir" { print $2; exit }'
}

CONF_FILE="/etc/mysql/mysql.conf.d/mysqld.cnf"
REPLICATION_CONFIG_FILE="/etc/mysql/mysql.conf.d/replication.cnf"

#### REDUCE ERRORS:
chown -R mysql:mysql /var/lib/mysql /var/run/mysqld
# Clear Logs per run
ls -l rm /var/log/mysql/
rm /var/log/mysql/*



# Set MySQL REPLICATION - SLAVE
if [ -n "${REPLICATION_SLAVE}" ]; then
    echo "=> Configuring MySQL replication as slave ..."

    echo "[mysqld]" > $REPLICATION_CONFIG_FILE
    for DBNAME in $MYSQL_DATABASES; do
        echo "replicate_do_db=$DBNAME" >> $REPLICATION_CONFIG_FILE
    done
    echo "------------------------- Replicating DBs: -------------------------";
    cat $REPLICATION_CONFIG_FILE

    ## Sourced from: github.com/thanhson1085/docker-mysql-replication.git
    if [ -n "${MYSQL_MASTER_TCP_ADDR}" ] && [ -n "${MYSQL_MASTER_TCP_PORT}" ]; then
        if [ ! -f /tmp/replication_set.1 ]; then
            RAND="$(date +%s | rev | cut -c 1-2)$(echo ${RANDOM})"
            echo "=> Writing configuration file '${CONF_FILE}' with server-id=${RAND}"
            cat ${CONF_FILE} > /tmp/mysqld.cnf && \
                echo "character-set-server=utf8" >> /tmp/mysqld.cnf && \
                echo "collation-server=utf8_general_ci" >> /tmp/mysqld.cnf && \
                echo "bind-address = 0.0.0.0" >> /tmp/mysqld.cnf && \
                echo "server-id = ${RAND}" >> /tmp/mysqld.cnf && \
                echo "log-bin = mysql-bin" >> /tmp/mysqld.cnf && \
                echo "replicate_ignore_db=mysql" >> /tmp/mysqld.cnf && \
                echo "replicate_ignore_db=sys" >> /tmp/mysqld.cnf && \
                echo "read_only=1" >> /tmp/mysqld.cnf

                mv /tmp/mysqld.cnf ${CONF_FILE}

            /etc/init.d/mysql start

            echo "------------------------- Adding Timezones: -------------------------"
            # Adding in missing Timezones
            # sed is for https://bugs.mysql.com/bug.php?id=20545
            # mysql_tzinfo_to_sql /usr/share/zoneinfo | sed 's/Local time zone must be set--see zic manual page/FCTY/' |
            mysql_tzinfo_to_sql /usr/share/zoneinfo  | sed 's/Local time zone must be set--see zic manual page/FCTY/' > install_mysql_zoneinfo.sql
            mysql -u root mysql < install_mysql_zoneinfo.sql

            echo "------------------------- Adding users: -------------------------"
#### ADD USERS

## Sourced from: github.com/thanhson1085/docker-mysql-replication.git
# https://stackoverflow.com/questions/20036547/mysql-grant-read-only-options
READ_ONLY=" SELECT, SHOW VIEW, PROCESS, REPLICATION CLIENT "
mysql -u root <<-EOSQL
    SET @@SESSION.SQL_LOG_BIN=0;
    CREATE USER 'root'@'%' IDENTIFIED BY '' ;
    GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION ;
    # Replication Manager: Must Write
    CREATE USER '$MYSQL_ENV_REPLICATION_USER'@'localhost' IDENTIFIED BY '$MYSQL_ENV_REPLICATION_PASS' ;
    GRANT ALL  ON *.* TO '$MYSQL_ENV_REPLICATION_USER'@'localhost' WITH GRANT OPTION ;
    CREATE USER '$MYSQL_ENV_REPLICATION_USER'@'%' IDENTIFIED BY '$MYSQL_ENV_REPLICATION_PASS' ;
    GRANT ALL  ON *.* TO '$MYSQL_ENV_REPLICATION_USER'@'%' WITH GRANT OPTION ;
    # Per-Project User: Must Not Write
    CREATE USER '$MYSQL_ENV_READONLY_USER'@'localhost' IDENTIFIED BY '$MYSQL_ENV_READONLY_PASS' ;
    GRANT $READ_ONLY  ON *.* TO '$MYSQL_ENV_READONLY_USER'@'localhost' WITH GRANT OPTION ;
    CREATE USER '$MYSQL_ENV_READONLY_USER'@'%' IDENTIFIED BY '$MYSQL_ENV_READONLY_PASS' ;
    GRANT $READ_ONLY  ON *.* TO '$MYSQL_ENV_READONLY_USER'@'%' WITH GRANT OPTION ;

    DROP DATABASE IF EXISTS test ;
    FLUSH PRIVILEGES ;
EOSQL

            # Config'd key
            touch /tmp/replication_set.1


        else
            echo "=> MySQL replication slave already configured, skip"
            /etc/init.d/mysql start
        fi
    else
        echo "=> Cannot configure slave, please link it to another MySQL container with alias as 'mysql'"

        exit 1
    fi
fi


#### INITIAL STARTUP CHECK
echo ""
echo "------------------------- Initial Startup: -------------------------"
mysql -u root -e "status;"

#ls -ltar /var/log/mysql/
cat /var/log/mysql/error.log


#### EXPORT
rm my.dump
if [ -z "$MYSQL_DATABASES" ]; then
    DB_NAMES=" --all-databases ";
else
    DB_NAMES=" --databases $MYSQL_DATABASES"
fi

echo ""
echo "------------------------- Remote DBs: -------------------------"
mysql -u $MYSQL_ENV_REPLICATION_USER -p"$MYSQL_ENV_REPLICATION_PASS" -h $MYSQL_MASTER_TCP_ADDR -P$MYSQL_MASTER_TCP_PORT -e "show databases;"

echo ""
echo "------------------------- Recently Used DBs: -------------------------"
mysql -u $MYSQL_ENV_REPLICATION_USER -p"$MYSQL_ENV_REPLICATION_PASS" -h $MYSQL_MASTER_TCP_ADDR -P$MYSQL_MASTER_TCP_PORT -e "SELECT TABLE_SCHEMA, max(UPDATE_TIME) FROM   information_schema.tables where table_schema != 'mysql'  and update_Time > (now() - (3600*24*7*2)) group by table_schema order by max(update_time);"

echo ""
echo "------------------------- Dumping to my.dump: -------------------------"
echo "If this takes too long, reduce this list of DB_NAMES in mysql.slave.env: $MYSQL_DATABASES"
echo ""
mysqldump -u $MYSQL_ENV_READONLY_USER -p"$MYSQL_ENV_READONLY_PASS" -h $MYSQL_MASTER_TCP_ADDR -P$MYSQL_MASTER_TCP_PORT $DB_NAMES --single-transaction --compress --order-by-primary \
        --ignore-table=mysql.user --ignore-table=mysql.columns_priv --ignore-table=mysql.db  --ignore-table=mysql.event  --ignore-table=mysql.func  --ignore-table=mysql.general_log  --ignore-table=mysql.help_category  --ignore-table=mysql.help_keyword  --ignore-table=mysql.help_relation  --ignore-table=mysql.help_topic  --ignore-table=mysql.host  --ignore-table=mysql.innodb_index_stats  --ignore-table=mysql.innodb_table_stats  --ignore-table=mysql.ndb_binlog_index  --ignore-table=mysql.plugin  --ignore-table=mysql.proc  --ignore-table=mysql.procs_priv  --ignore-table=mysql.proxies_priv  --ignore-table=mysql.servers  --ignore-table=mysql.slave_master_info  --ignore-table=mysql.slave_relay_log_info  --ignore-table=mysql.slave_worker_info  --ignore-table=mysql.slow_log  --ignore-table=mysql.tables_priv  --ignore-table=mysql.time_zone  --ignore-table=mysql.time_zone_leap_second  --ignore-table=mysql.time_zone_name  --ignore-table=mysql.time_zone_transition  --ignore-table=mysql.time_zone_transition_type --ignore-table=mysql.rds_heartbeat2 \
        --ignore-table=sys.host_summary_by_file_io  --ignore-table=sys.host_summary_by_file_io_type  --ignore-table=sys.host_summary_by_stages  --ignore-table=sys.host_summary_by_statement_latency --ignore-table=sys.host_summary_by_statement_type  --ignore-table=sys.innodb_buffer_stats_by_schema  --ignore-table=sys.innodb_buffer_stats_by_table  --ignore-table=sys.innodb_lock_waits  --ignore-table=sys.io_by_thread_by_latency  --ignore-table=sys.io_global_by_file_by_bytes  --ignore-table=sys.io_global_by_file_by_latency  --ignore-table=sys.io_global_by_wait_by_bytes  --ignore-table=sys.io_global_by_wait_by_latency  --ignore-table=sys.latest_file_io   --ignore-table=sys.metrics   --ignore-table=sys.processlist   --ignore-table=sys.ps_check_lost_instrumentation  --ignore-table=sys.schema_auto_increment_columns  --ignore-table=sys.schema_index_statistics  --ignore-table=sys.schema_object_overview  --ignore-table=sys.schema_redundant_indexes  --ignore-table=sys.schema_table_statistics  --ignore-table=sys.schema_table_statistics_with_buffer --ignore-table=sys.schema_tables_with_full_table_scans --ignore-table=sys.schema_unused_indexes  --ignore-table=sys.session   --ignore-table=sys.statement_analysis  --ignore-table=sys.statements_with_errors_or_warnings --ignore-table=sys.statements_with_full_table_scans --ignore-table=sys.statements_with_runtimes_in_95th_percentile --ignore-table=sys.statements_with_sorting  --ignore-table=sys.statements_with_temp_tables  --ignore-table=sys.sys_config   --ignore-table=sys.user_summary   --ignore-table=sys.user_summary_by_file_io  --ignore-table=sys.user_summary_by_file_io_type  --ignore-table=sys.user_summary_by_stages  --ignore-table=sys.user_summary_by_statement_latency --ignore-table=sys.user_summary_by_statement_type  --ignore-table=sys.version   --ignore-table=sys.wait_classes_global_by_avg_latency --ignore-table=sys.wait_classes_global_by_latency  --ignore-table=sys.waits_by_host_by_latency  --ignore-table=sys.waits_by_user_by_latency  --ignore-table=sys.waits_global_by_latency  --ignore-table=sys.x$host_summary   --ignore-table=sys.x$host_summary_by_file_io  --ignore-table=sys.x$host_summary_by_file_io_type  --ignore-table=sys.x$host_summary_by_stages  --ignore-table=sys.x$host_summary_by_statement_latency --ignore-table=sys.x$host_summary_by_statement_type --ignore-table=sys.x$innodb_buffer_stats_by_schema --ignore-table=sys.x$innodb_buffer_stats_by_table  --ignore-table=sys.x$innodb_lock_waits  --ignore-table=sys.x$io_by_thread_by_latency  --ignore-table=sys.x$io_global_by_file_by_bytes  --ignore-table=sys.x$io_global_by_file_by_latency  --ignore-table=sys.x$io_global_by_wait_by_bytes  --ignore-table=sys.x$io_global_by_wait_by_latency  --ignore-table=sys.x$latest_file_io  --ignore-table=sys.x$processlist   --ignore-table=sys.x$ps_digest_95th_percentile_by_avg_us --ignore-table=sys.x$ps_digest_avg_latency_distribution --ignore-table=sys.x$ps_schema_table_statistics_io --ignore-table=sys.x$schema_flattened_keys  --ignore-table=sys.x$schema_index_statistics  --ignore-table=sys.x$schema_table_statistics  --ignore-table=sys.x$schema_table_statistics_with_buffer --ignore-table=sys.x$schema_tables_with_full_table_scans --ignore-table=sys.x$session   --ignore-table=sys.x$statement_analysis  --ignore-table=sys.x$statements_with_errors_or_warnings --ignore-table=sys.x$statements_with_full_table_scans --ignore-table=sys.x$statements_with_runtimes_in_95th_percentile --ignore-table=sys.x$statements_with_sorting  --ignore-table=sys.x$statements_with_temp_tables  --ignore-table=sys.x$user_summary   --ignore-table=sys.x$user_summary_by_file_io  --ignore-table=sys.x$user_summary_by_file_io_type  --ignore-table=sys.x$user_summary_by_stages  --ignore-table=sys.x$user_summary_by_statement_latency --ignore-table=sys.x$user_summary_by_statement_type --ignore-table=sys.x$wait_classes_global_by_avg_latency --ignore-table=sys.x$wait_classes_global_by_latency --ignore-table=sys.x$waits_by_host_by_latency  --ignore-table=sys.x$waits_by_user_by_latency  --ignore-table=sys.x$waits_global_by_latency  > my.dump




#### IMPORT
echo "------------------------- Importing my.dump -------------------------"
  mysql -u root < my.dump

echo ""
echo "Import Errors: ";
tail --lines 20 /var/log/mysql/error.log

#### SETUP SLAVE

if [ -n "$REPLICATION_SLAVE" ] && $REPLICATION_SLAVE == true
then

#### CONFIG REPLICATION
echo "------------------------- Configuring Replication: -------------------------"

  MASTER_LOG_FILE=`mysql -u $MYSQL_ENV_REPLICATION_USER -p"$MYSQL_ENV_REPLICATION_PASS" -h $MYSQL_MASTER_TCP_ADDR -P$MYSQL_MASTER_TCP_PORT -e "show master status\G;" | grep -E "File:\s" | sed 's/.*: //'`
  MASTER_LOG_POS=`mysql -u $MYSQL_ENV_REPLICATION_USER -p"$MYSQL_ENV_REPLICATION_PASS" -h $MYSQL_MASTER_TCP_ADDR -P$MYSQL_MASTER_TCP_PORT  -e "show master status\G;" | grep -E "Position:\s" | sed 's/.*: //'`
  echo "MASTER LOG FILE: $MASTER_LOG_FILE"
  echo "MASTER LOG POS: $MASTER_LOG_POS"

## MySQL complained about adding this: '--relay-log=4b8282fcd04a-relay-bin'
## But inline didn't do anything: RELAY_LOG_FILE='mysql-docker'

echo " Starting Replication:"
mysql -u root -e "reset slave ALL;"
mysql -u root -e "CHANGE MASTER TO MASTER_HOST='$MYSQL_MASTER_TCP_ADDR',MASTER_PORT=$MYSQL_MASTER_TCP_PORT,MASTER_USER='$MYSQL_ENV_REPLICATION_USER',MASTER_PASSWORD='${MYSQL_ENV_REPLICATION_PASS}',MASTER_LOG_FILE='$MASTER_LOG_FILE',MASTER_LOG_POS=$MASTER_LOG_POS;"

#### START REPLICATION
  mysql -u root -e "start slave ;"
  mysql -u root -e "show slave status\G;"

echo ""
echo " Local MySQL DBs:"
  mysql -u root -e "show databases;"


echo "------------------------- MySQL Running: statuses -------------------------"

## loop for slave status updates:
    while true ; do
        DATETIME=$( date );
        echo "------------------------- MySQL Running: status at $DATETIME-------------------------"
        echo " "
        echo "MySQL slave status:"
        mysql -u root -e "show slave status\G;" | grep -E "(Slave|Pos|Last_Error)"
        echo " "
        echo " "
        echo "MySQL errors:"
        tail /var/log/mysql/*
        echo ""
        echo " Database should be ready."
        echo " Replication status will be rechecked every 2 minutes."
        echo ""
        sleep 120
        #No need to repeat old errors
        echo "" > /var/log/mysql/error.log

    done


else

echo "Actually Run now: ";
/etc/init.d/mysql stop
/usr/bin/mysqld_safe

fi

