<?php
foreach($_REQUEST as $k=>$v){
    $_REQUEST[$k] = filter_var($v, FILTER_SANITIZE_URL);
}

if(array_key_exists('domain_name', $_REQUEST) ){
    $return_status=file_put_contents('/tmp/domain-setup-queue/'.$_REQUEST['domain_name'].'.txt', "DB_NAME=".$_REQUEST['db_name']);
    //exec('/bin/bash /setup-domain.sh setup '.$_REQUEST['domain_name'].' '.$_REQUEST['db_name'], $result, $return_status);
    if($return_status > 0){ echo "\n<br/> Setup started for ".$_REQUEST['domain_name'].".. <br/>";
        exit;

    }else{
        echo "\n<br/> Setup NOT started for ".$_REQUEST['domain_name']."..[$return_status] <br/>";
        exit;
    }
}
?>
<!DOCTYPE html>
<html class="" lang="en">

<?php
if(array_key_exists('domain_name', $_REQUEST) ){
?><script>
var domain_name = '<?php echo $_REQUEST["domain_name"]; ?>';
</script>
<?php } ?>

<style>
form{width:100%;margin:40px 0;}
form,label,input{float:left;}
label,input[type='submit']{clear:left;}
#result{
overflow-y: scroll;
max-height: 50vh;
width:100%;
}

</style>
<body>
<h2>You're Running Docker!</h2>

<h4>Actions</h4>
<ul>
<li><a href='/phpinfo.php'>PHP Info</a></li>
<li><a href='/list.php'>List of Local Domains</a></li>

</ul>


<form id="setup-domain">
<h4>Setup a new domain</h4>
<label for='domain_name'>Domain Name:</label>
<input class='domain_name' name='domain_name' type="text"/>
<label for='db_name'>Database Name:</label>
<input class='db_name' name='db_name' type="text"/>
<input class='form-submit' type="submit" />
</form>


<div class='result-initial'>

</div>

<pre id='result'>
</pre>

<h4 id='final-result'></h4>


</body>
<script src="https://ajax.googleapis.com/ajax/libs/jquery/3.3.1/jquery.min.js"></script>
<script>
jQuery(document).ready(function($){
    console.log('doc ready..');

    $('.form-submit').click(function(e){
        e.preventDefault();
        console.log('setup submitted..');
        domain_name = $('.domain_name').val();
        var tid = setTimeout(doPoll, 5200);
        console.log('timeoutid', tid);

            $.ajax({
                url: "index.php",
                type: "GET",
                data: $('#setup-domain').serialize(),
                success: function (data) {
                    doPoll();
                },
                error: function (jXHR, textStatus, errorThrown) {
                    jQuery('#result').html("Error!\n"+textStatus+"\n"+errorThrown);
                }
            }); // AJAX Get Jquery statment

    });

});

var pollingStarted = 0;

function doPoll(){
    pollingStarted++;
    console.log('PollingIndex:', pollingStarted);

    jQuery.get('/status/'+domain_name+'.txt')
    .done(function(data) {
        console.log('Success loading AJAX:', data);

        if(data=='') data='Nothing yet, checking again in 4 seconds';
        jQuery('#result').html(data);  // process results here
        setTimeout(doPoll, 5500);
    })
    .fail(function(xhr, status, error) {
        console.log('Error loading AJAX:', xhr, xhr.statusCode, error);

        if(xhr.status=='404'){
            if( pollingStarted < 5) setTimeout(doPoll, 11200);  // 3 rounds of 11 seconds.
            else jQuery('#final-result').html("Setup Finished. Review above for details.");
        }

        //Doesn't restart polling.
    });
}
</script>
</html>