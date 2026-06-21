<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\DeviceController;
use App\Http\Controllers\Api\DeviceSyncController;
use App\Http\Controllers\Api\EventController;
use App\Http\Controllers\Api\GatemanSettingsController;
use App\Http\Controllers\Api\OrganizationController;
use App\Http\Controllers\Api\PassController;
use App\Http\Controllers\Api\PassTemplateController;
use App\Http\Controllers\Api\PassTypeController;
use App\Http\Controllers\Api\QrValidationController;
use App\Http\Controllers\Api\QrWizardController;
use App\Http\Controllers\Api\ScanController;
use App\Http\Controllers\Api\SystemConfigurationController;
use App\Http\Controllers\Api\UserController;
use Illuminate\Support\Facades\Route;

// Public routes
Route::post('/login', [AuthController::class, 'login']);
Route::post('/device-registration', [DeviceController::class, 'publicRegister']);
Route::post('/device-registration/status', [DeviceController::class, 'publicStatus']);
Route::post('/validate-pass', [QrValidationController::class, 'verify']);

// Protected routes (require authentication)
Route::middleware('auth:sanctum')->group(function () {
    // Auth
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me', [AuthController::class, 'me']);
    Route::post('/refresh', [AuthController::class, 'refresh']);

    // Users
    Route::apiResource('users', UserController::class);

    // Organizations
    Route::apiResource('organizations', OrganizationController::class);

    // Devices
    Route::apiResource('devices', DeviceController::class);
    Route::post('/devices/{device}/approve', [DeviceController::class, 'approve']);
    Route::post('/devices/{device}/revoke', [DeviceController::class, 'revoke']);

    // Device sync
    Route::get('/device/profile', [DeviceSyncController::class, 'profile']);
    Route::post('/device/sync', [DeviceSyncController::class, 'sync']);
    Route::get('/device/package', [DeviceSyncController::class, 'downloadPackage']);

    // System configuration
    Route::get('/admin/dashboard', [SystemConfigurationController::class, 'dashboard']);
    Route::apiResource('configurations', SystemConfigurationController::class);

    // Events
    Route::apiResource('events', EventController::class);
    Route::put('/events/{event}/lock', [EventController::class, 'lock']);
    Route::get('/stats', [EventController::class, 'stats']);

    // Pass Types
    Route::apiResource('events.pass-types', PassTypeController::class)->shallow();

    // Pass Templates
    Route::apiResource('events.templates', PassTemplateController::class)->shallow();

    // Passes
    Route::apiResource('events.passes', PassController::class)->shallow();
    Route::post('/events/{event}/passes/bulk-generate', [PassController::class, 'bulkGenerate']);
    Route::post('/events/{event}/print-manifest', [PassController::class, 'printManifest']);
    Route::get('/events/{event}/package', [EventController::class, 'package']);

    // Scans
    Route::apiResource('scans', ScanController::class);
    Route::post('/scans/batch', [ScanController::class, 'batchStore']);

    // Scanner settings
    Route::get('/scanner/settings', [GatemanSettingsController::class, 'index']);
    Route::put('/scanner/settings', [GatemanSettingsController::class, 'update']);

    // QR Wizard
    Route::get('/qr-wizard/themes', [QrWizardController::class, 'themes']);
    Route::post('/qr-wizard/generate', [QrWizardController::class, 'generate']);
    Route::post('/qr-wizard/bulk-generate', [QrWizardController::class, 'bulkGenerate']);
});
