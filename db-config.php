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
    $localdb="mysql_slave";
    $wpdb->add_database(array(
        "host"     => $localdb,     // If port is other than 3306, use host:port.
        "user"     => DB_USER,
        "password" => DB_PASSWORD,
        "name"     => DB_NAME,
        "write"    => 0,
        "read"     => replication_ok($localdb),    //is_admin() ? 0 : 1,
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

function wpdb_connection_error( $host, $port, $op, $tbl, $ds, $dbhname, $wpdb ) {
//if(is_logged_in()) isn't real with no db!
    var_dump($host);
    var_dump($port);
    var_dump($tbl);
    var_dump($op);
    var_dump($wpdb->last_query);
	dead_db();
}
$wpdb->add_callback( 'wpdb_connection_error', 'db_connection_error' );

function replication_ok($server='mysql_slave'){   //health check: ideally it would only run once in awhile, not every pageload
$errors = '';
$returncode=1;
if ( defined( "WP_CLI" ) && WP_CLI ){
    //don't say anything, it can mess with output parsing!
}else{
//foreach($servers as $server) {
	$link = mysqli_connect($server, DB_USER, DB_PASSWORD);
	if($link) {
		$res = mysqli_query($link, "SHOW SLAVE STATUS");
		$row = mysqli_fetch_assoc($res);
		if($row['Slave_IO_Running'] == 'No') {
			$errors .= "Slave IO not running on $server\n";
			$errors .= "Error number: {$row['Last_IO_Errno']}\n";
			$errors .= "Error message: {$row['Last_IO_Error']}\n\n";
    		    $returncode=0;
		}
		if($row['Slave_SQL_Running'] == 'No') {
			$errors .= "Slave SQL not running on $server\n";
			$errors .= "Error number: {$row['Last_SQL_Errno']}\n";
			$errors .= "Error message: {$row['Last_SQL_Error']}\n\n";
        		$returncode=0;
		}
		if($row['Read_Master_Log_Pos']!==$row['Exec_Master_Log_Pos']){
        		$returncode=0;
		}
		if($row['Last_IO_Errno']>0 || $row['Last_SQL_Errno']>0){
        		$returncode=0;
		}
		mysqli_close($link);
	} else {
		$errors .= "Could not connect to $server\n\n";
		$returncode=0;    //unsure what htis means
	}//link
    if(stripos($_SERVER['REQUEST_URI'],'wp-json')===false ){ //again, don't mess up json!
        add_action('wp_footer', function() use($server, $returncode, $errors){ echo "\n<!-- \n\tReplication on $server status: $returncode \n\tDetails: $errors \n\t-->\n"; }, 99 );
    }
} //not cli
return $returncode;  //1 for ok, 0 for 'do not read from this'
}

