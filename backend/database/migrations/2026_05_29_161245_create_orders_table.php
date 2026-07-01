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
        Schema::create('orders', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
            $table->string('order_code')->unique();
            $table->string('service_type');
            $table->string('fleet_name');
            $table->string('fleet_type');
            $table->string('origin');
            $table->string('destination');
            $table->date('departure_date');
            $table->time('departure_time');
            $table->dateTime('estimated_finish')->nullable();
            $table->decimal('total_price', 15, 2)->nullable();
            $table->string('payment_status')->default('Menunggu Validasi');
            $table->string('order_status')->default('Menunggu Konfirmasi');
            $table->text('notes')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('orders');
    }
};
