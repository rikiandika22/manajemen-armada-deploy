<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use App\Models\Order;
use App\Models\Payment;
use App\Models\Jadwal;
use App\Models\Armada;

class ClearOrderDataCommand extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'orders:clear-testing-data {--force : Skip confirmation prompt}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Hapus semua data pesanan, pembayaran, jadwal terkait pesanan, dan bukti pembayaran (Hanya untuk local/development)';

    /**
     * Execute the console command.
     *
     * @return int
     */
    public function handle()
    {
        // 1. Cek environment
        if (!app()->isLocal() && !app()->environment('development')) {
            $this->error('Command ini hanya boleh dijalankan di environment development atau local.');
            return 1;
        }

        // 2. Tampilkan peringatan
        $this->warn('====================================================');
        $this->warn('PERHATIAN: Anda akan menghapus SEMUA data pesanan!');
        $this->warn('====================================================');
        $this->line('Data yang akan dihapus:');
        $this->line('- Semua data di tabel orders');
        $this->line('- Semua data di tabel payments yang terkait order');
        $this->line('- Semua data di tabel jadwals yang berasal dari order');
        $this->line('- File bukti pembayaran di storage');
        $this->line('');
        $this->line('Data user, admin, armada, dan sopir akan tetap AMAN.');
        $this->line('');

        $force = $this->option('force');

        // 3. Minta konfirmasi
        if (!$force) {
            if (!$this->confirm('Apakah Anda yakin ingin melanjutkan penghapusan ini?', false)) {
                $this->info('Penghapusan dibatalkan.');
                return 0;
            }
        }

        $this->info('Memulai penghapusan data...');

        DB::beginTransaction();

        try {
            // 4. Proses hapus file bukti pembayaran
            $payments = Payment::whereNotNull('payment_proof_path')->get();
            $deletedFilesCount = 0;

            foreach ($payments as $payment) {
                if (Storage::disk('public')->exists($payment->payment_proof_path)) {
                    Storage::disk('public')->delete($payment->payment_proof_path);
                    $deletedFilesCount++;
                }
            }

            // 5. Proses hapus dari database
            $paymentsCount = Payment::count();
            Payment::query()->delete();

            $jadwalsQuery = Jadwal::whereNotNull('order_id')
                ->orWhereNotNull('kode_pesanan')
                ->orWhere('jenis_jadwal', 'Pesanan Mobile')
                ->orWhere('jenis_jadwal', 'Reservasi');
            
            $jadwalsCount = $jadwalsQuery->count();
            $jadwalsQuery->delete();

            $ordersCount = Order::count();
            Order::query()->delete();

            // Reset status armada ke Tersedia jika statusnya Terjadwal
            // Note: Armada yang sedang perawatan/tidak aktif tidak boleh diubah
            // Tapi karena display_status adalah accessor, kita tidak bisa mengubah tabel secara langsung untuk Terjadwal.
            // Namun, jika ada armada yang status_operasional-nya sengaja di-hardcode ke Terjadwal atau semacamnya, 
            // kita bisa kembalikan ke Tersedia.
            // Karena status armada diatur lewat display_status yang bergantung pada tabel jadwals,
            // penghapusan jadwals di atas sudah secara otomatis mereset status dinamis armada ke Tersedia.
            
            // Opsional: Reset AUTO_INCREMENT (sqlite tidak punya AUTO_INCREMENT query langsung seperti MySQL, 
            // MySQL butuh ALTER TABLE, kita lewati reset AI agar lebih aman multi-database).

            DB::commit();

            $this->info('Berhasil menghapus data testing!');
            $this->line("- $ordersCount orders dihapus.");
            $this->line("- $paymentsCount payments dihapus.");
            $this->line("- $jadwalsCount jadwals dihapus.");
            $this->line("- $deletedFilesCount file bukti pembayaran dihapus.");

            return 0;

        } catch (\Exception $e) {
            DB::rollBack();
            $this->error('Terjadi kesalahan: ' . $e->getMessage());
            return 1;
        }
    }
}
