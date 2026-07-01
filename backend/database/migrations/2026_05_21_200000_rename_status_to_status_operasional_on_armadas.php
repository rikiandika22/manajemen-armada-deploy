<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('armadas', function (Blueprint $table) {
            $table->string('status_operasional')->default('aktif')->after('status');
        });

        // Map lama → baru
        DB::table('armadas')->where('status', 'perawatan')->update(['status_operasional' => 'perawatan']);
        DB::table('armadas')->where('status', 'tidak_aktif')->update(['status_operasional' => 'tidak_aktif']);
        DB::table('armadas')->whereNotIn('status', ['perawatan', 'tidak_aktif'])->update(['status_operasional' => 'aktif']);

        Schema::table('armadas', function (Blueprint $table) {
            $table->dropColumn('status');
        });
    }

    public function down(): void
    {
        Schema::table('armadas', function (Blueprint $table) {
            $table->string('status')->default('tersedia')->after('satuan_kapasitas');
        });

        DB::table('armadas')->where('status_operasional', 'perawatan')->update(['status' => 'perawatan']);
        DB::table('armadas')->where('status_operasional', 'tidak_aktif')->update(['status' => 'tidak_aktif']);
        DB::table('armadas')->where('status_operasional', 'aktif')->update(['status' => 'tersedia']);

        Schema::table('armadas', function (Blueprint $table) {
            $table->dropColumn('status_operasional');
        });
    }
};
