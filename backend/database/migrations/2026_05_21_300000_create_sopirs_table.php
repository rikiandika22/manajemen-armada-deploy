<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('sopirs', function (Blueprint $table) {
            $table->id();
            $table->string('kode_sopir')->unique();
            $table->string('nama');
            $table->string('telepon');
            $table->text('alamat')->nullable();
            $table->string('status')->default('aktif'); // aktif, tidak_aktif
            $table->string('foto')->nullable(); // path ke file foto
            $table->text('keterangan')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('sopirs');
    }
};
