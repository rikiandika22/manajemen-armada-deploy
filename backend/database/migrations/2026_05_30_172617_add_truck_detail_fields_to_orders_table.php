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
            $table->string('truck_load_type')->nullable();
            $table->string('truck_load_description')->nullable();
            $table->string('truck_load_weight')->nullable();
            $table->string('truck_load_weight_unit')->nullable();
            $table->string('truck_load_quantity')->nullable();
            $table->string('truck_load_quantity_unit')->nullable();
            $table->string('truck_access_note')->nullable();
            $table->text('truck_additional_note')->nullable();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn([
                'truck_load_type',
                'truck_load_description',
                'truck_load_weight',
                'truck_load_weight_unit',
                'truck_load_quantity',
                'truck_load_quantity_unit',
                'truck_access_note',
                'truck_additional_note'
            ]);
        });
    }
};
