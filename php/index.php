<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

require('vendor/autoload.php');

$comment = $_POST['comment'] ?? false;

if ($comment) {
    $status = "success";

    $options = ['encrypted' => true];

    $pusher = new Pusher('b9f32d17ee5e19db5c65', '6bbe3f94c64cd34e8bee', '328150', $options);

    $pusher->trigger('comments', 'new_comment', ['text' => $comment]);
} else {
    $status = "failure";
}

header('Content-Type: application/json');
echo json_encode(["result" => $status]);
