<?php

namespace App\Http\Controllers;

use App\Models\Payment;
use App\Models\Order;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AdminPaymentController extends Controller
{
    /**
     * Display a listing of the payments.
     */
    public function index(Request $request)
    {
        $payments = Payment::with(['order', 'user'])
            ->orderBy('created_at', 'desc')
            ->get()
            ->map(function ($payment) {
                return [
                    'id' => $payment->id,
                    'order_id' => $payment->order_id,
                    'order_code' => $payment->order->order_code ?? '-',
                    'customer_name' => $payment->user->name ?? '-',
                    'fleet_name' => $payment->order->fleet_name ?? '-',
                    'service_type' => $payment->order->service_type ?? '-',
                    'bank_name' => $payment->bank_name,
                    'amount' => (float) $payment->amount,
                    'payment_type' => $payment->payment_type,
                    'payment_status' => $payment->payment_status,
                    'payment_proof_url' => $payment->payment_proof_url,
                    'created_at' => $payment->created_at->format('Y-m-d H:i:s'),
                ];
            });

        return response()->json([
            'message' => 'Data pembayaran berhasil diambil',
            'data' => $payments
        ]);
    }

    /**
     * Display the specified payment detail.
     */
    public function show($id)
    {
        $payment = Payment::with(['order', 'user'])->findOrFail($id);

        return response()->json([
            'message' => 'Detail pembayaran berhasil diambil',
            'data' => [
                'id' => $payment->id,
                'order_id' => $payment->order_id,
                'order_code' => $payment->order->order_code ?? '-',
                'customer_name' => $payment->user->name ?? '-',
                'customer_email' => $payment->user->email ?? '-',
                'customer_phone' => $payment->user->phone_number ?? '-',
                'fleet_name' => $payment->order->fleet_name ?? '-',
                'service_type' => $payment->order->service_type ?? '-',
                'origin' => $payment->order->origin ?? '-',
                'destination' => $payment->order->destination ?? '-',
                'departure_date' => $payment->order->departure_date ? $payment->order->departure_date->format('Y-m-d') : '-',
                'bank_name' => $payment->bank_name,
                'amount' => (float) $payment->amount,
                'payment_type' => $payment->payment_type,
                'payment_status' => $payment->payment_status,
                'payment_proof_url' => $payment->payment_proof_url,
                'rejected_reason' => $payment->rejected_reason,
                'created_at' => $payment->created_at->format('Y-m-d H:i:s'),
            ]
        ]);
    }

    /**
     * Approve the payment.
     */
    public function approve(Request $request, $id)
    {
        $payment = Payment::with('order.user')->findOrFail($id);

        if (!in_array($payment->payment_status, ['Menunggu Validasi'])) {
            if (in_array($payment->payment_status, ['DP Diterima', 'Lunas', 'Diterima'])) {
                $existingJadwal = \App\Models\Jadwal::where('order_id', $payment->order_id)->first();
                if ($existingJadwal) {
                    return response()->json([
                        'message' => 'Pesanan sudah memiliki jadwal',
                        'data' => [
                            'payment_status' => $payment->payment_status,
                            'order_status' => $payment->order->order_status ?? 'Terjadwal',
                            'schedule_created' => false,
                            'schedule_exists' => true
                        ]
                    ]);
                }
            } else {
                return response()->json([
                    'message' => 'Status pembayaran tidak valid untuk diproses'
                ], 422);
            }
        }

        $order = $payment->order;

        if (!$order || in_array($order->order_status, ['Dibatalkan', 'Selesai'])) {
            return response()->json([
                'message' => 'Pesanan tidak valid atau sudah selesai/dibatalkan'
            ], 422);
        }

        // Logic for "Pelunasan"
        if ($payment->payment_type === 'Pelunasan') {
            DB::transaction(function () use ($payment, $order, $request) {
                $payment->payment_status = 'Diterima';
                $payment->verified_by = $request->user()->id ?? null;
                $payment->verified_at = now();
                $payment->rejected_reason = null;
                $payment->save();

                $order->payment_status = 'Lunas';
                $order->remaining_payment = 0;
                $order->save();
            });

            return response()->json([
                'message' => 'Pelunasan diterima dan status pesanan menjadi lunas',
                'data' => [
                    'payment_status' => 'Lunas',
                    'order_status' => $order->order_status,
                    'schedule_created' => false,
                    'schedule_exists' => true
                ]
            ]);
        }

        // Logic for "DP"
        if (empty($order->assigned_fleet_id)) {
            $msg = strtolower($order->fleet_type) === 'truk' || strtolower($order->service_type) === 'truk logistik' 
                ? 'Unit truk belum ditetapkan' 
                : 'Tetapkan unit armada terlebih dahulu sebelum menerima pembayaran';
            return response()->json([
                'message' => $msg
            ], 422);
        }

        if (strtolower($order->fleet_type) === 'truk' || strtolower($order->service_type) === 'truk logistik') {
            if ($order->total_price === null) {
                return response()->json([
                    'message' => 'Harga truk belum ditentukan'
                ], 422);
            }
        }

        $existingJadwal = \App\Models\Jadwal::where('order_id', $order->id)->first();
        if ($existingJadwal) {
            return response()->json([
                'message' => 'Pesanan ini sudah memiliki jadwal',
                'data' => [
                    'payment_status' => 'DP Diterima',
                    'order_status' => 'Terjadwal',
                    'schedule_created' => false,
                    'schedule_exists' => true
                ]
            ]);
        }

        $armadaId = $order->assigned_fleet_id;
        $tanggalMulai = $order->departure_date ? $order->departure_date->format('Y-m-d') : null;
        $jamMulai = $order->departure_time;
        
        if (!$tanggalMulai) {
             return response()->json([
                'message' => 'Tanggal keberangkatan tidak valid'
            ], 422);
        }

        $tanggalSelesai = $order->estimated_finish ? $order->estimated_finish->format('Y-m-d') : \Carbon\Carbon::parse($tanggalMulai)->addDay()->format('Y-m-d');
        $jamSelesai = $order->estimated_finish ? $order->estimated_finish->format('H:i') : '23:59';

        $newStart = $tanggalMulai . ' ' . $jamMulai;
        $newEnd = $tanggalSelesai . ' ' . $jamSelesai;

        $conflict = \App\Models\Jadwal::where('armada_id', $armadaId)
            ->whereIn('status_jadwal', ['Terjadwal', 'Aktif', 'Dipesan', 'Dalam Perjalanan'])
            ->whereRaw("CONCAT(tanggal_mulai, ' ', jam_berangkat) < ?", [$newEnd])
            ->whereRaw("CONCAT(tanggal_selesai, ' ', COALESCE(jam_selesai, '23:59:00')) > ?", [$newStart])
            ->first();

        if ($conflict) {
            return response()->json([
                'message' => 'Armada sudah memiliki jadwal pada waktu tersebut'
            ], 422);
        }

        $jadwal = null;
        try {
            DB::transaction(function () use ($payment, $order, $request, $armadaId, $tanggalMulai, $jamMulai, $tanggalSelesai, $jamSelesai, &$jadwal) {
                $jadwal = \App\Models\Jadwal::create([
                    'order_id' => $order->id,
                    'user_id' => $order->user_id,
                    'kode_pesanan' => $order->order_code,
                    'armada_id' => $armadaId,
                    'tanggal_mulai' => $tanggalMulai,
                    'tanggal_selesai' => $tanggalSelesai,
                    'jam_berangkat' => $jamMulai,
                    'jam_selesai' => $jamSelesai,
                    'lokasi_asal' => $order->origin,
                    'lokasi_tujuan' => $order->destination,
                    'nama_pelanggan' => $order->user->name ?? 'Unknown',
                    'nomor_telepon' => $order->user->phone_number ?? 'Unknown',
                    'keperluan' => $order->service_type,
                    'status_jadwal' => 'Terjadwal',
                    'jenis_jadwal' => 'Reservasi',
                    'keterangan' => $order->notes,
                ]);

                $payment->payment_status = 'Diterima';
                $payment->verified_by = $request->user()->id ?? null;
                $payment->verified_at = now();
                $payment->rejected_reason = null;
                $payment->save();

                $order->payment_status = 'DP Diterima';
                $order->order_status = 'Terjadwal';
                $order->save();
            });
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Gagal membuat jadwal'
            ], 500);
        }

        return response()->json([
            'message' => 'Pembayaran diterima dan jadwal berhasil dibuat',
            'data' => [
                'payment_status' => 'DP Diterima',
                'order_status' => 'Terjadwal',
                'schedule_created' => true,
                'jadwal_id' => $jadwal->id
            ]
        ]);
    }

    /**
     * Reject the payment.
     */
    public function reject(Request $request, $id)
    {
        $request->validate([
            'rejected_reason' => 'required|string',
        ], [
            'rejected_reason.required' => 'Alasan penolakan wajib diisi',
        ]);

        $payment = Payment::findOrFail($id);

        DB::transaction(function () use ($payment, $request) {
            $payment->payment_status = 'Ditolak';
            $payment->rejected_reason = $request->rejected_reason;
            $payment->verified_by = $request->user()->id ?? null;
            $payment->verified_at = now();
            $payment->save();

            if ($payment->order) {
                if ($payment->payment_type === 'Pelunasan') {
                    $payment->order->payment_status = 'DP Diterima';
                } else {
                    $payment->order->payment_status = 'Ditolak';
                }
                $payment->order->save();
            }
        });

        return response()->json([
            'message' => 'Pembayaran berhasil ditolak',
            'data' => $payment
        ]);
    }
}
