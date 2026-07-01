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
        Schema::table('armada_images', function (Blueprint $table) {
            $table->string('cloudinary_public_id')->nullable()->after('image_path');
        });

        Schema::table('payments', function (Blueprint $table) {
            $table->string('cloudinary_public_id')->nullable()->after('payment_proof_path');
            $table->string('settlement_cloudinary_public_id')->nullable()->after('cloudinary_public_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('armada_images', function (Blueprint $table) {
            $table->dropColumn('cloudinary_public_id');
        });

        Schema::table('payments', function (Blueprint $table) {
            $table->dropColumn(['cloudinary_public_id', 'settlement_cloudinary_public_id']);
        });
    }
};
