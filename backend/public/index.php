<?php

use Illuminate\Foundation\Application;
use Illuminate\Http\Request;

define('LARAVEL_START', microtime(true));

// ─── Serve storage files for PHP built-in server (php artisan serve) ───
// PHP built-in server cannot follow symlinks on macOS.
// This serves files directly before Laravel bootstraps (no middleware overhead).
// On production (Nginx/Apache), the web server handles static files directly.
if (PHP_SAPI === 'cli-server') {
    $uri = urldecode(parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH));
    if (preg_match('#^/storage/(.+)$#', $uri, $matches)) {
        $storagePath = __DIR__ . '/../storage/app/public/' . $matches[1];
        if (is_file($storagePath)) {
            $mimeType = mime_content_type($storagePath) ?: 'application/octet-stream';
            header('Content-Type: ' . $mimeType);
            header('Cache-Control: public, max-age=31536000');
            readfile($storagePath);
            exit;
        }
    }
}

// Determine if the application is in maintenance mode...
if (file_exists($maintenance = __DIR__.'/../storage/framework/maintenance.php')) {
    require $maintenance;
}

// Register the Composer autoloader...
require __DIR__.'/../vendor/autoload.php';

// Bootstrap Laravel and handle the request...
/** @var Application $app */
$app = require_once __DIR__.'/../bootstrap/app.php';

$app->handleRequest(Request::capture());
