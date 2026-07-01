<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\ArmadaController;
use App\Http\Controllers\JadwalController;
use App\Http\Controllers\SopirController;
use App\Http\Controllers\SettingController;
use App\Http\Controllers\MobileAuthController;
use App\Http\Controllers\MobileOrderController;
use App\Http\Controllers\MobileFleetController;

Route::post('/login', [AuthController::class, 'login']);

// Mobile API Routes
Route::prefix('mobile')->group(function () {
    Route::post('/register', [MobileAuthController::class, 'register']);
    Route::post('/login', [MobileAuthController::class, 'login']);
    
    // Public routes (Guest can view fleets and schedule)
    Route::get('/fleets', [MobileFleetController::class, 'index']);
    Route::get('/fleets/{id}', [MobileFleetController::class, 'show']);
    Route::get('/fleets/{id}/availability', [MobileFleetController::class, 'availability']);
    Route::get('/fleet-summary', [MobileFleetController::class, 'summary']);
    Route::get('/truck-units', [MobileFleetController::class, 'truckUnits']);
    Route::get('/payment_accounts', [\App\Http\Controllers\PaymentAccountController::class, 'mobileIndex']);
    
    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/me', [MobileAuthController::class, 'me']);
        Route::post('/logout', [MobileAuthController::class, 'logout']);
        Route::put('/profile', [MobileAuthController::class, 'updateProfile']);
        Route::put('/change-password', [MobileAuthController::class, 'changePassword']);
        
        // Orders
        Route::get('/orders', [MobileOrderController::class, 'index']);
        Route::post('/orders', [MobileOrderController::class, 'store']);
        Route::get('/orders/archived', [MobileOrderController::class, 'archived']);
        Route::get('/orders/{id}', [MobileOrderController::class, 'show']);
        Route::post('/orders/{id}/cancel', [MobileOrderController::class, 'cancel']);
        Route::patch('/orders/{id}/archive', [MobileOrderController::class, 'archive']);
        Route::patch('/orders/{id}/unarchive', [MobileOrderController::class, 'unarchive']);
        Route::post('/orders/{id}/upload-payment', [MobileOrderController::class, 'uploadPaymentProof']);
        Route::post('/orders/{id}/payments/settlement', [MobileOrderController::class, 'uploadSettlementProof']);
    });
});

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/me', [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);

    // Settings
    Route::put('/profile', [SettingController::class, 'updateProfile']);
    Route::get('/business-setting', [SettingController::class, 'getBusinessSetting']);
    Route::put('/business-setting', [SettingController::class, 'updateBusinessSetting']);
    Route::put('/change-password', [SettingController::class, 'changePassword']);

    Route::get('/ping', function () {
        return response()->json([
            'message' => 'API Laravel aktif'
        ]);
    });

    // Dashboard
    Route::get('/admin/dashboard', [\App\Http\Controllers\AdminDashboardController::class, 'dashboard']);
    Route::get('/admin/dashboard/calendar', [\App\Http\Controllers\AdminDashboardController::class, 'calendar']);

    // Global Search
    Route::get('/admin/search/global', [\App\Http\Controllers\AdminGlobalSearchController::class, 'search']);

    // Notifications
    Route::get('/admin/notifications/summary', [\App\Http\Controllers\AdminNotificationController::class, 'summary']);

    // Reports
    Route::get('/admin/reports/summary', [\App\Http\Controllers\AdminReportController::class, 'summary']);
    Route::get('/admin/reports/operational', [\App\Http\Controllers\AdminReportController::class, 'operational']);
    Route::get('/admin/reports/export/pdf', [\App\Http\Controllers\AdminReportController::class, 'exportPdf']);
    Route::get('/admin/reports/export/excel', [\App\Http\Controllers\AdminReportController::class, 'exportExcel']);

    // Payment Accounts
    Route::get('/admin/payment_accounts', [\App\Http\Controllers\PaymentAccountController::class, 'index']);
    Route::post('/admin/payment_accounts', [\App\Http\Controllers\PaymentAccountController::class, 'store']);
    Route::put('/admin/payment_accounts/{id}', [\App\Http\Controllers\PaymentAccountController::class, 'update']);
    Route::delete('/admin/payment_accounts/{id}', [\App\Http\Controllers\PaymentAccountController::class, 'destroy']);
    Route::patch('/admin/payment_accounts/{id}/toggle', [\App\Http\Controllers\PaymentAccountController::class, 'toggle']);

    // Armada
    Route::apiResource('armadas', ArmadaController::class);
    Route::post('/armadas/{armada}/images', [App\Http\Controllers\ArmadaImageController::class, 'store']);
    Route::delete('/armadas/images/{image}', [App\Http\Controllers\ArmadaImageController::class, 'destroy']);
    Route::put('/armadas/images/{image}/set-primary', [App\Http\Controllers\ArmadaImageController::class, 'setPrimary']);

    // Jadwal
    Route::get('/admin/jadwals/summary', [JadwalController::class, 'summary']);
    Route::apiResource('jadwals', JadwalController::class);
    Route::patch('/admin/jadwals/{id}/complete', [JadwalController::class, 'complete']);

    // Sopir
    Route::apiResource('sopirs', SopirController::class);

    // Orders (Pemesanan Admin)
    Route::get('/orders', [\App\Http\Controllers\OrderController::class, 'index']);
    Route::get('/orders/{id}', [\App\Http\Controllers\OrderController::class, 'show']);
    Route::put('/orders/{id}/assign-fleet', [\App\Http\Controllers\OrderController::class, 'assignFleet']);
    Route::post('/orders/{id}/set-truck-price', [\App\Http\Controllers\OrderController::class, 'setTruckPrice']);
    Route::post('/orders/{id}/confirm', [\App\Http\Controllers\OrderController::class, 'confirm']);

    // Admin Payments
    Route::get('/admin/payments', [\App\Http\Controllers\AdminPaymentController::class, 'index']);
    Route::get('/admin/payments/{id}', [\App\Http\Controllers\AdminPaymentController::class, 'show']);
    Route::post('/admin/payments/{id}/approve', [\App\Http\Controllers\AdminPaymentController::class, 'approve']);
    Route::post('/admin/payments/{id}/reject', [\App\Http\Controllers\AdminPaymentController::class, 'reject']);
});

