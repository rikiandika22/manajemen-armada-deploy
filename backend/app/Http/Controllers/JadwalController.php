<?php

namespace App\Http\Controllers;

use App\Models\Armada;
use App\Models\Jadwal;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class JadwalController extends Controller
{
    /**
     * Display a listing of the resource (with armada and order relations).
     */
    public function index()
    {
        $jadwals = Jadwal::with(['armada', 'order'])
            ->orderBy('tanggal_mulai', 'desc')
            ->get();

        // Optionally, format the data to match the user's requested response structure
        // But since React is already using row.armada etc., we just append order data
        return response()->json([
            'message' => 'Data jadwal berhasil diambil',
            'data'    => $jadwals,
        ]);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'armada_id'       => 'required|exists:armadas,id',
            'tanggal_mulai'   => 'required|date',
            'tanggal_selesai' => 'required|date|after_or_equal:tanggal_mulai',
            'jam_berangkat'   => 'required|string',
            'lokasi_asal'     => 'required|string',
            'lokasi_tujuan'   => 'required|string',
            'detail_lokasi'   => 'nullable|string',
            'nama_pelanggan'  => 'required|string',
            'nomor_telepon'   => 'required|string',
            'keperluan'       => 'nullable|string',
            'status_jadwal'   => 'required|string|in:tersedia,dipesan,dalam_perjalanan,selesai,dibatalkan',
            'jenis_jadwal'    => 'nullable|string',
            'keterangan'      => 'nullable|string',
        ]);

        // Cek status armada
        $armada = Armada::findOrFail($validated['armada_id']);

        if (in_array($armada->status_operasional, ['perawatan', 'tidak_aktif'])) {
            return response()->json([
                'message' => 'Armada dalam status ' . $armada->status_operasional . ' dan tidak dapat dijadwalkan.',
                'errors'  => ['armada_id' => ['Armada dalam status ' . $armada->status_operasional . ' dan tidak dapat dijadwalkan.']],
            ], 422);
        }

        // Cek bentrok jadwal — armada yang sama di tanggal yang overlap dengan jadwal aktif
        if ($this->isScheduleConflict($validated['armada_id'], $validated['tanggal_mulai'], $validated['tanggal_selesai'])) {
            return response()->json([
                'message' => 'Armada sudah memiliki jadwal pada tanggal tersebut.',
                'errors'  => ['armada_id' => ['Armada sudah memiliki jadwal pada tanggal tersebut.']],
            ], 422);
        }

        $jadwal = Jadwal::create($validated);
        $jadwal->load('armada');

        return response()->json([
            'message' => 'Data jadwal berhasil disimpan',
            'data'    => $jadwal,
        ], 201);
    }

    /**
     * Display the specified resource.
     */
    public function show(Jadwal $jadwal)
    {
        $jadwal->load('armada');

        return response()->json([
            'message' => 'Data jadwal berhasil diambil',
            'data'    => $jadwal,
        ]);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, Jadwal $jadwal)
    {
        $validated = $request->validate([
            'armada_id'       => 'required|exists:armadas,id',
            'tanggal_mulai'   => 'required|date',
            'tanggal_selesai' => 'required|date|after_or_equal:tanggal_mulai',
            'jam_berangkat'   => 'required|string',
            'lokasi_asal'     => 'required|string',
            'lokasi_tujuan'   => 'required|string',
            'detail_lokasi'   => 'nullable|string',
            'nama_pelanggan'  => 'required|string',
            'nomor_telepon'   => 'required|string',
            'keperluan'       => 'nullable|string',
            'status_jadwal'   => 'required|string|in:tersedia,dipesan,dalam_perjalanan,selesai,dibatalkan',
            'jenis_jadwal'    => 'nullable|string',
            'keterangan'      => 'nullable|string',
        ]);

        // Cek status armada
        $armada = Armada::findOrFail($validated['armada_id']);

        if (in_array($armada->status_operasional, ['perawatan', 'tidak_aktif'])) {
            return response()->json([
                'message' => 'Armada dalam status ' . $armada->status_operasional . ' dan tidak dapat dijadwalkan.',
                'errors'  => ['armada_id' => ['Armada dalam status ' . $armada->status_operasional . ' dan tidak dapat dijadwalkan.']],
            ], 422);
        }

        // Cek bentrok jadwal (exclude jadwal yang sedang diedit)
        if ($this->isScheduleConflict($validated['armada_id'], $validated['tanggal_mulai'], $validated['tanggal_selesai'], $jadwal->id)) {
            return response()->json([
                'message' => 'Armada sudah memiliki jadwal pada tanggal tersebut.',
                'errors'  => ['armada_id' => ['Armada sudah memiliki jadwal pada tanggal tersebut.']],
            ], 422);
        }

        $jadwal->update($validated);
        $jadwal->load('armada');

        return response()->json([
            'message' => 'Data jadwal berhasil diperbarui',
            'data'    => $jadwal,
        ]);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Jadwal $jadwal)
    {
        $jadwal->delete();

        return response()->json([
            'message' => 'Data jadwal berhasil dihapus',
        ]);
    }

    /**
     * Cek apakah armada memiliki jadwal aktif yang bertabrakan.
     * Jadwal aktif = status_jadwal in (dipesan, dalam_perjalanan)
     */
    private function isScheduleConflict(int $armadaId, string $start, string $end, ?int $excludeId = null): bool
    {
        $query = Jadwal::where('armada_id', $armadaId)
            ->whereIn('status_jadwal', ['dipesan', 'dalam_perjalanan'])
            ->where(function ($q) use ($start, $end) {
                // Overlap: existing.start <= new.end AND existing.end >= new.start
                $q->where('tanggal_mulai', '<=', $end)
                  ->where('tanggal_selesai', '>=', $start);
            });

        if ($excludeId) {
            $query->where('id', '!=', $excludeId);
        }

        return $query->exists();
    }

    /**
     * Tandai jadwal sebagai selesai.
     */
    public function complete($id)
    {
        $jadwal = Jadwal::with(['order', 'armada'])->find($id);

        if (!$jadwal) {
            return response()->json([
                'message' => 'Jadwal tidak ditemukan'
            ], 404);
        }

        if ($jadwal->status_jadwal === 'selesai' || $jadwal->status_jadwal === 'Selesai') {
            return response()->json([
                'message' => 'Jadwal sudah selesai'
            ], 400);
        }

        if ($jadwal->status_jadwal === 'dibatalkan' || $jadwal->status_jadwal === 'Dibatalkan') {
            return response()->json([
                'message' => 'Jadwal yang dibatalkan tidak bisa diselesaikan'
            ], 400);
        }

        try {
            \Illuminate\Support\Facades\DB::beginTransaction();

            $order = $jadwal->order;
            
            if (!$order && !empty($jadwal->kode_pesanan)) {
                $order = \App\Models\Order::where('order_code', $jadwal->kode_pesanan)->first();
            }

            if (!$order) {
                \Illuminate\Support\Facades\DB::rollBack();
                return response()->json(['message' => 'Jadwal tidak memiliki relasi pesanan yang valid.'], 400);
            }

            if (strtolower($order->order_status) === 'dibatalkan') {
                \Illuminate\Support\Facades\DB::rollBack();
                return response()->json(['message' => 'Pesanan sudah dibatalkan'], 400);
            }

            $isPaidOff = in_array(strtolower(trim($order->payment_status)), ['lunas', 'paid']);

            if (!$isPaidOff) {
                if ($order->payment_status === 'Menunggu Validasi Pelunasan') {
                    \Illuminate\Support\Facades\DB::rollBack();
                    return response()->json(['message' => 'Pelunasan masih menunggu validasi admin.'], 400);
                }
                \Illuminate\Support\Facades\DB::rollBack();
                return response()->json(['message' => 'Pembayaran belum lunas. Jadwal belum bisa diselesaikan.'], 400);
            }

            $pelunasanWaiting = $order->payments()
                ->whereIn(\Illuminate\Support\Facades\DB::raw('LOWER(payment_type)'), ['pelunasan', 'settlement'])
                ->where('payment_status', 'Menunggu Validasi')
                ->exists();

            if ($pelunasanWaiting) {
                \Illuminate\Support\Facades\DB::rollBack();
                return response()->json(['message' => 'Pelunasan masih menunggu validasi admin.'], 400);
            }

            $hasPelunasan = $order->payments()
                ->whereIn(\Illuminate\Support\Facades\DB::raw('LOWER(payment_type)'), ['pelunasan', 'settlement'])
                ->exists();
                
            $pelunasanDiterima = $order->payments()
                ->whereIn(\Illuminate\Support\Facades\DB::raw('LOWER(payment_type)'), ['pelunasan', 'settlement'])
                ->where('payment_status', 'Diterima')
                ->exists();
            
            if ($hasPelunasan && !$pelunasanDiterima) {
                \Illuminate\Support\Facades\DB::rollBack();
                return response()->json(['message' => 'Status pelunasan belum valid.'], 400);
            }

            if ($order->remaining_payment > 0 && !$pelunasanDiterima) {
                \Illuminate\Support\Facades\DB::rollBack();
                return response()->json(['message' => 'Data pembayaran belum valid untuk menyelesaikan jadwal.'], 400);
            }

            // 1. Update status_jadwal
            $jadwal->status_jadwal = 'selesai';
            $jadwal->save();

            // 2. Update order_status jika ada order
            if ($order) {
                $order->order_status = 'Selesai';
                $order->save();
            } else if ($jadwal->order_id) {
                \App\Models\Order::where('id', $jadwal->order_id)->update(['order_status' => 'Selesai']);
            }

            // 3. Bebaskan armada (kembalikan ke Tersedia jika statusnya aktif/terpakai)
            if ($jadwal->armada && !in_array($jadwal->armada->status_operasional, ['perawatan', 'Perawatan', 'tidak_aktif', 'Tidak Aktif'])) {
                $jadwal->armada->status_operasional = 'Tersedia';
                $jadwal->armada->save();
            }

            \Illuminate\Support\Facades\DB::commit();

            return response()->json([
                'message' => 'Jadwal berhasil ditandai selesai',
                'data' => [
                    'jadwal_id' => $jadwal->id,
                    'status_jadwal' => 'Selesai',
                    'order_status' => 'Selesai',
                    'payment_status' => $order ? $order->payment_status : null
                ]
            ]);

        } catch (\Exception $e) {
            \Illuminate\Support\Facades\DB::rollBack();
            return response()->json([
                'message' => 'Terjadi kesalahan saat menyelesaikan jadwal',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get summary of jadwals for the dashboard/jadwal page
     */
    public function summary()
    {
        try {
            $now = \Carbon\Carbon::now()->timezone('Asia/Jakarta');
            
            // 1. Terjadwal: status_jadwal Terjadwal dan belum Selesai atau Dibatalkan
            $terjadwal = Jadwal::whereIn(\Illuminate\Support\Facades\DB::raw('LOWER(status_jadwal)'), ['terjadwal'])
                ->count();

            // 2. Dalam Perjalanan: status_jadwal Terjadwal dan waktu sekarang di antara waktu mulai dan waktu selesai
            $dalamPerjalanan = Jadwal::whereIn(\Illuminate\Support\Facades\DB::raw('LOWER(status_jadwal)'), ['terjadwal'])
                ->whereRaw("CONCAT(tanggal_mulai, ' ', COALESCE(jam_berangkat, '00:00:00')) <= ?", [$now])
                ->whereRaw("CONCAT(tanggal_selesai, ' ', COALESCE(jam_selesai, '23:59:59')) >= ?", [$now])
                ->count();

            // 3. Perlu Diselesaikan: status_jadwal Terjadwal, waktu selesai terlewati, payment lunas, order belum selesai
            $perluDiselesaikan = Jadwal::whereIn(\Illuminate\Support\Facades\DB::raw('LOWER(status_jadwal)'), ['terjadwal'])
                ->whereRaw("CONCAT(tanggal_selesai, ' ', COALESCE(jam_selesai, '23:59:59')) < ?", [$now])
                ->whereHas('order', function ($query) {
                    $query->whereIn(\Illuminate\Support\Facades\DB::raw('LOWER(payment_status)'), ['lunas', 'paid'])
                          ->whereNotIn(\Illuminate\Support\Facades\DB::raw('LOWER(order_status)'), ['selesai', 'dibatalkan']);
                })
                ->count();

            // 4. Selesai Hari Ini: status_jadwal selesai pada hari ini
            $selesaiHariIni = Jadwal::whereIn(\Illuminate\Support\Facades\DB::raw('LOWER(status_jadwal)'), ['selesai'])
                ->whereDate('updated_at', clone $now)
                ->count();

            return response()->json([
                'data' => [
                    'terjadwal' => $terjadwal,
                    'dalam_perjalanan' => $dalamPerjalanan,
                    'perlu_diselesaikan' => $perluDiselesaikan,
                    'selesai_hari_ini' => $selesaiHariIni,
                ]
            ]);

        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::error('Jadwal summary error: ' . $e->getMessage());
            return response()->json([
                'message' => 'Gagal memuat ringkasan jadwal.'
            ], 500);
        }
    }
}
