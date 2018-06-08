<!DOCTYPE html>
<html class="" lang="en">
<body>
<h3>Available Domains Locally:
</h3>
<ul>
<?php
foreach (glob("/var/www/domains/*.*/local") as $filename) {
//$domain=str_replace(array("/var/www/domains/","/local"),"",$filename);
$file_split = explode('/',$filename);
$domain=$file_split[4];
?>
	<li><a href="http://local.<?php echo $domain; ?>/"><?php echo $domain;?></a></li>
<?php
}
?>

</ul>
</body>
</html>