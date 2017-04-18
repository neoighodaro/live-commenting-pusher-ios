<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

require('vendor/autoload.php');

$comment = $_POST['comment'] ?? false;

if ($comment) {
    $status = "success";

    $options = ['encrypted' => true];

    $pusher = new Pusher('PUSHER_API_KEY', 'PUSHER_API_SECRET', 'PUSHER_APP_ID', $options);

    $pusher->trigger('comments', 'new_comment', ['text' => $comment]);
} else {
    $status = "failure";
}

header('Content-Type: application/json');
echo json_encode(["result" => $status]);
