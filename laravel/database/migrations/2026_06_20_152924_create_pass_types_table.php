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
        Schema::create('pass_types', function (Blueprint $table) {
            $table->id();
            $table->foreignId('event_id')->constrained('events')->onDelete('cascade');
            $table->string('name'); // VIP, Guest, Staff, Security, etc.
            $table->integer('entry_limit')->nullable(); // Max entries allowed
            $table->json('access_zones')->nullable(); // Zones this pass type can access
            $table->json('date_restrictions')->nullable(); // Date range restrictions
            $table->json('time_restrictions')->nullable(); // Time range restrictions
            $table->timestamps();

            $table->index('event_id');
            $table->unique(['event_id', 'name']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('pass_types');
    }
};
