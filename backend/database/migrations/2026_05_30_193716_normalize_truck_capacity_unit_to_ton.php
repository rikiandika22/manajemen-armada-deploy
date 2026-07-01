<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // 1. Ubah tipe data kapasitas menjadi decimal
        Schema::table('armadas', function (Blueprint $table) {
            $table->decimal('kapasitas', 8, 2)->change();
        });

        // 2. Normalisasi data lama (Truk dengan satuan kg atau kapasitas di atas 100)
        $armadas = DB::table('armadas')
            ->where('jenis_armada', 'like', '%Truk%')
            ->orWhere('jenis_armada', 'like', '%Truck%')
            ->get();

        foreach ($armadas as $a) {
            $kapasitas = (float) $a->kapasitas;
            $satuan = strtolower(trim($a->satuan_kapasitas));

            if ($satuan === 'kg' || $kapasitas >= 100) {
                // Konversi kg ke Ton
                $newKapasitas = $kapasitas / 1000;
                DB::table('armadas')->where('id', $a->id)->update([
                    'kapasitas' => $newKapasitas,
                    'satuan_kapasitas' => 'Ton'
                ]);
            } else {
                // Pastikan satuannya seragam "Ton"
                DB::table('armadas')->where('id', $a->id)->update([
                    'satuan_kapasitas' => 'Ton'
                ]);
            }
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Reverse data untuk Truk (Ton -> Kg)
        $armadas = DB::table('armadas')
            ->where('jenis_armada', 'like', '%Truk%')
            ->orWhere('jenis_armada', 'like', '%Truck%')
            ->get();

        foreach ($armadas as $a) {
            $kapasitas = (float) $a->kapasitas;
            $newKapasitas = $kapasitas * 1000;
            DB::table('armadas')->where('id', $a->id)->update([
                'kapasitas' => $newKapasitas,
                'satuan_kapasitas' => 'kg'
            ]);
        }

        // Kembalikan ke integer
        Schema::table('armadas', function (Blueprint $table) {
            $table->integer('kapasitas')->change();
        });
    }
};
