<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('jadwals', function (Blueprint $table) {
            $table->id();
            $table->foreignId('armada_id')->constrained('armadas')->cascadeOnDelete();
            $table->date('tanggal_mulai');
            $table->date('tanggal_selesai');
            $table->string('jam_berangkat');
            $table->string('lokasi_asal');
            $table->string('lokasi_tujuan');
            $table->text('detail_lokasi')->nullable();
            $table->string('nama_pelanggan');
            $table->string('nomor_telepon');
            $table->text('keperluan')->nullable();
            $table->string('status_jadwal')->default('tersedia');
            $table->text('keterangan')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('jadwals');
    }
};
