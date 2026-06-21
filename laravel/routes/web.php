<?php

use App\Http\Controllers\AdminAuthController;
use App\Http\Controllers\AdminController;
use Illuminate\Support\Facades\Route;

Route::view('/', 'welcome');
Route::view('/admin', 'admin');

// Admin authentication (session-based)
Route::get('/login', [AdminAuthController::class, 'loginForm'])->name('login');
Route::post('/login', [AdminAuthController::class, 'login'])->name('admin.login');
Route::post('/logout', [AdminAuthController::class, 'logout'])->name('logout');

Route::middleware(['auth:web', 'can:access-admin'])->prefix('admin')->group(function () {
    Route::get('/', [AdminController::class, 'dashboard'])->name('admin.dashboard');
    Route::get('/users', [AdminController::class, 'users'])->name('admin.users');
    Route::get('/events', [AdminController::class, 'events'])->name('admin.events');
    Route::get('/devices', [AdminController::class, 'devices'])->name('admin.devices');
    Route::get('/scans', [AdminController::class, 'scans'])->name('admin.scans');

    // Device actions
    Route::post('/devices/{device}/approve', [AdminController::class, 'approveDevice'])->name('admin.devices.approve');
    Route::post('/devices/{device}/revoke', [AdminController::class, 'revokeDevice'])->name('admin.devices.revoke');
    Route::delete('/devices/{device}', [AdminController::class, 'deleteDevice'])->name('admin.devices.delete');

    // Event actions
    Route::put('/events/{event}/lock', [AdminController::class, 'lockEvent'])->name('admin.events.lock');
    Route::delete('/events/{event}', [AdminController::class, 'deleteEvent'])->name('admin.events.delete');

    // User actions
    Route::delete('/users/{user}', [AdminController::class, 'deleteUser'])->name('admin.users.delete');
});
