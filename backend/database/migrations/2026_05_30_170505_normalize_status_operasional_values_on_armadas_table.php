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
        DB::table('armadas')
            ->whereIn('status_operasional', ['aktif', 'Aktif'])
            ->update(['status_operasional' => 'Tersedia']);

        DB::table('armadas')
            ->whereIn('status_operasional', ['perawatan', 'Perawatan'])
            ->update(['status_operasional' => 'Perawatan']);

        DB::table('armadas')
            ->whereIn('status_operasional', ['tidak_aktif', 'Tidak Aktif'])
            ->update(['status_operasional' => 'Tidak Aktif']);
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Reverting back to lowercase format for previous states if needed
        DB::table('armadas')
            ->where('status_operasional', 'Tersedia')
            ->update(['status_operasional' => 'aktif']);
            
        DB::table('armadas')
            ->where('status_operasional', 'Perawatan')
            ->update(['status_operasional' => 'perawatan']);
            
        DB::table('armadas')
            ->where('status_operasional', 'Tidak Aktif')
            ->update(['status_operasional' => 'tidak_aktif']);
    }
};
