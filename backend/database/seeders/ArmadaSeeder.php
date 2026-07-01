<?php

namespace Database\Seeders;

use App\Models\Armada;
use Illuminate\Database\Seeder;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;

class ArmadaSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Run the database seeds.
     * Menggunakan updateOrCreate agar aman dijalankan berkali-kali.
     * Kode armada menggunakan prefix BUS/ELF/TRK sesuai spesifikasi.
     */
    public function run(): void
    {
        $armadas = [
            [
                'kode_armada'      => 'BUS001',
                'nama_armada'      => 'Bus Medium 01',
                'plat_nomor'       => 'H 1234 AA',
                'jenis_armada'     => 'Bus Medium',
                'kapasitas'        => 30,
                'satuan_kapasitas' => 'seat',
                'status_operasional' => 'aktif',
                'keterangan'       => 'Kondisi baik, siap beroperasi',
            ],
            [
                'kode_armada'      => 'ELF001',
                'nama_armada'      => 'Elf Long 01',
                'plat_nomor'       => 'H 5678 BB',
                'jenis_armada'     => 'Elf Long',
                'kapasitas'        => 16,
                'satuan_kapasitas' => 'seat',
                'status_operasional' => 'aktif',
                'keterangan'       => 'Siap beroperasi untuk rute dalam kota',
            ],
            [
                'kode_armada'      => 'TRK001',
                'nama_armada'      => 'Truk CDD 01',
                'plat_nomor'       => 'H 9012 CC',
                'jenis_armada'     => 'Truk CDD Bak Terbuka',
                'kapasitas'        => 5000,
                'satuan_kapasitas' => 'kg',
                'status_operasional' => 'aktif',
                'keterangan'       => 'Siap untuk pengiriman logistik',
            ],
            [
                'kode_armada'      => 'TRK002',
                'nama_armada'      => 'Truk CDD 02',
                'plat_nomor'       => 'H 3456 DD',
                'jenis_armada'     => 'Truk CDD Bak Terbuka',
                'kapasitas'        => 5000,
                'satuan_kapasitas' => 'kg',
                'status_operasional' => 'perawatan',
                'keterangan'       => 'Servis rutin di bengkel',
            ],
            [
                'kode_armada'      => 'TRK003',
                'nama_armada'      => 'Truk CDD 03',
                'plat_nomor'       => 'H 7890 EE',
                'jenis_armada'     => 'Truk CDD Bak Terbuka',
                'kapasitas'        => 5000,
                'satuan_kapasitas' => 'kg',
                'status_operasional' => 'aktif',
                'keterangan'       => 'Pengiriman area Grobogan',
            ],
            [
                'kode_armada'      => 'TRK004',
                'nama_armada'      => 'Truk CDD 04',
                'plat_nomor'       => 'H 2345 FF',
                'jenis_armada'     => 'Truk CDD Bak Terbuka',
                'kapasitas'        => 5000,
                'satuan_kapasitas' => 'kg',
                'status_operasional' => 'aktif',
                'keterangan'       => 'Siap beroperasi',
            ],
        ];

        foreach ($armadas as $data) {
            Armada::updateOrCreate(
                ['kode_armada' => $data['kode_armada']],
                $data
            );
        }
    }
}
