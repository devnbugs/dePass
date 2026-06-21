<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('scans', function (Blueprint $table) {
            $table->id();
            $table->foreignId('pass_id')->constrained('passes')->onDelete('cascade');
            $table->foreignId('device_id')->nullable()->constrained('devices')->onDelete('set null');
            $table->enum('scan_result', ['valid', 'invalid', 'duplicate'])->default('valid');
            $table->dateTime('scanned_at');
            $table->string('location_zone')->nullable(); // Main Hall, VIP Lounge, etc.
            $table->json('metadata')->nullable();
            $table->timestamps();

            $table->index('pass_id');
            $table->index('device_id');
            $table->index('scanned_at');
            $table->index('scan_result');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('scans');
    }
};
