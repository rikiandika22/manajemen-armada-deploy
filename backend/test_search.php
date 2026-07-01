<?php
$request = Request::create('/api/admin/search/global', 'GET', ['q' => 'PSN']);
$response = app()->handle($request);
echo $response->getContent();
