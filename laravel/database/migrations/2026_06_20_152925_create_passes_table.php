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
        Schema::create('passes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('event_id')->constrained('events')->onDelete('cascade');
            $table->foreignId('pass_type_id')->constrained('pass_types')->onDelete('cascade');
            $table->string('pass_uid', 16)->unique(); // Random unique ID for QR
            $table->string('signature'); // HMAC-SHA256 signature
            $table->string('attendee_name')->nullable(); // NULL for dynamic passes
            $table->string('company')->nullable();
            $table->string('phone')->nullable();
            $table->json('metadata')->nullable();
            $table->integer('scan_count')->default(0);
            $table->enum('status', ['active', 'used', 'revoked'])->default('active');
            $table->timestamps();

            $table->index('event_id');
            $table->index('pass_uid');
            $table->index('pass_type_id');
            $table->index('status');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('passes');
    }
};
