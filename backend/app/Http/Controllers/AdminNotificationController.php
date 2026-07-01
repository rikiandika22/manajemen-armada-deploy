<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Order;
use App\Models\Payment;
use App\Models\Jadwal;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class AdminNotificationController extends Controller
{
    public function summary(Request $request)
    {
        try {
            // 1. Pemesanan count
            $pemesananCount = Order::where(DB::raw('LOWER(order_status)'), 'menunggu konfirmasi')->count();

            // 2. Pembayaran count
            $pembayaranCount = Payment::where(DB::raw('LOWER(payment_status)'), 'menunggu validasi')->count();

            // 3. Jadwal count
            $now = Carbon::now();
            
            $jadwalCount = Jadwal::whereIn(DB::raw('LOWER(status_jadwal)'), ['terjadwal'])
                ->whereHas('order', function ($query) {
                    $query->whereIn(DB::raw('LOWER(payment_status)'), ['lunas', 'paid'])
                          ->whereNotIn(DB::raw('LOWER(order_status)'), ['selesai', 'dibatalkan']);
                })
                ->where(function($query) use ($now) {
                    $query->whereRaw("CONCAT(tanggal_selesai, ' ', COALESCE(jam_selesai, '23:59:59')) <= ?", [$now]);
                })
                ->count();

            $total = $pemesananCount + $pembayaranCount + $jadwalCount;

            return response()->json([
                'data' => [
                    'total' => $total,
                    'pemesanan' => [
                        'count' => $pemesananCount,
                        'label' => 'Pesanan menunggu konfirmasi'
                    ],
                    'pembayaran' => [
                        'count' => $pembayaranCount,
                        'label' => 'Pembayaran menunggu validasi'
                    ],
                    'jadwal' => [
                        'count' => $jadwalCount,
                        'label' => 'Jadwal perlu diselesaikan'
                    ]
                ]
            ]);
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::error('Notification summary error: ' . $e->getMessage());
            return response()->json([
                'message' => 'Gagal memuat ringkasan notifikasi'
            ], 500);
        }
    }
}
