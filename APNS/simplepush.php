<?php

// Put your device token here (without spaces):
$deviceToken = 'c2f78e59430edff5a0c58b3288198eb27ca9cec230e959dc6883cdc80f145974';

// Put your private key's passphrase here:
$passphrase = 'toto';

// Put your alert message here:
$message = 'New DZ data available !';

////////////////////////////////////////////////////////////////////////////////

$ctx = stream_context_create();
stream_context_set_option($ctx, 'ssl', 'local_cert', 'ck.pem');
stream_context_set_option($ctx, 'ssl', 'passphrase', $passphrase);

// Open a connection to the APNS server
$fp = stream_socket_client(
	'ssl://gateway.sandbox.push.apple.com:2195', $err,
	$errstr, 60, STREAM_CLIENT_CONNECT|STREAM_CLIENT_PERSISTENT, $ctx);

if (!$fp)
	exit("Failed to connect: $err $errstr" . PHP_EOL);

echo 'Connected to APNS' . PHP_EOL;

$locargs = array( 'Test1', 'Test2');

$test = array(
	'loc-key' => $message,
	'loc-args' => $locargs
	);

// Create the payload body
$body['aps'] = array(
	'alert' => $test,
	'badge' => 1
	);

// Encode the payload as JSON
$payload = json_encode($body);

echo $payload;

// Build the binary notification
$msg = chr(0) . pack('n', 32) . pack('H*', $deviceToken) . pack('n', strlen($payload)) . $payload;

// Send it to the server
$result = fwrite($fp, $msg, strlen($msg));

if (!$result)
	echo 'Message not delivered' . PHP_EOL;
else
	echo 'Message successfully delivered' . PHP_EOL;

// Close the connection to the server
fclose($fp);
