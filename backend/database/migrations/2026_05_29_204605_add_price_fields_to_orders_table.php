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
        Schema::table('orders', function (Blueprint $table) {
            $table->decimal('dp_amount', 15, 2)->nullable();
            $table->decimal('remaining_payment', 15, 2)->nullable();
            $table->text('price_note')->nullable();
            $table->string('price_status')->default('Menunggu Harga');
            $table->timestamp('price_sent_at')->nullable();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn([
                'dp_amount',
                'remaining_payment',
                'price_note',
                'price_status',
                'price_sent_at'
            ]);
        });
    }
};
