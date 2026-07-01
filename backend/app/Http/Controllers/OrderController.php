<?php

namespace App\Http\Controllers;

use App\Models\Order;
use App\Models\Armada;
use Illuminate\Http\Request;

class OrderController extends Controller
{
    /**
     * Display a listing of the orders for admin.
     */
    public function index()
    {
        $orders = Order::with(['assignedFleet.images', 'user'])->orderBy('created_at', 'desc')->get();
        return response()->json([
            'message' => 'Data pemesanan berhasil diambil',
            'data' => $orders
        ]);
    }

    /**
     * Display the specified order.
     */
    public function show($id)
    {
        $order = Order::with(['assignedFleet.images', 'user'])->findOrFail($id);
        return response()->json([
            'message' => 'Detail pemesanan berhasil diambil',
            'data' => $order
        ]);
    }

    /**
     * Assign a specific fleet unit to an order.
     */
    public function assignFleet(Request $request, $id)
    {
        $validated = $request->validate([
            'assigned_fleet_id' => 'required|exists:armadas,id',
        ]);

        $order = Order::findOrFail($id);

        $armada = Armada::findOrFail($validated['assigned_fleet_id']);
        $normalizeFleet = function ($type) {
            $lower = strtolower($type);
            if (str_contains($lower, 'bus')) return 'bus';
            if (str_contains($lower, 'elf')) return 'elf';
            if (str_contains($lower, 'truk') || str_contains($lower, 'truck')) return 'truk';
            return 'lainnya';
        };

        if ($normalizeFleet($order->fleet_type) !== $normalizeFleet($armada->jenis_armada)) {
            return response()->json([
                'message' => 'Unit armada tidak sesuai dengan jenis pesanan.',
            ], 422);
        }

        if (in_array($order->order_status, ['Selesai', 'Dibatalkan'])) {
            return response()->json([
                'message' => 'Pesanan selesai atau dibatalkan tidak bisa mengubah unit armada.',
            ], 422);
        }

        if ($order->order_status === 'Terjadwal' && $order->assigned_fleet_id !== null) {
            return response()->json([
                'message' => 'Pesanan yang sudah terjadwal tidak bisa mengubah unit armada.',
            ], 422);
        }

        // Validasi: Status armada
        if (strtolower($armada->status_operasional) === 'tidak aktif') {
            return response()->json([
                'message' => 'Gagal menetapkan unit. Armada sedang tidak aktif.',
            ], 422);
        }
        
        if (strtolower($armada->status_operasional) === 'perawatan') {
            return response()->json([
                'message' => 'Gagal menetapkan unit. Armada sedang dalam perawatan.',
            ], 422);
        }

        $tanggalMulai = $order->departure_date->format('Y-m-d');
        $jamMulai = $order->departure_time;
        $tanggalSelesai = $order->estimated_finish ? $order->estimated_finish->format('Y-m-d') : $tanggalMulai;
        $jamSelesai = $order->estimated_finish ? $order->estimated_finish->format('H:i') : '23:59';
        
        $newStart = $tanggalMulai . ' ' . $jamMulai;
        $newEnd = $tanggalSelesai . ' ' . $jamSelesai;

        $conflict = \App\Models\Jadwal::where('armada_id', $armada->id)
            ->whereIn('status_jadwal', ['Dipesan', 'Dalam Perjalanan'])
            ->whereRaw("CONCAT(tanggal_mulai, ' ', jam_berangkat) < ?", [$newEnd])
            ->whereRaw("CONCAT(tanggal_selesai, ' ', COALESCE(jam_selesai, '23:59:00')) > ?", [$newStart])
            ->first();

        if ($conflict) {
            return response()->json([
                'message' => 'Gagal menetapkan unit. Armada bentrok dengan jadwal lain.'
            ], 422);
        }

        $order->assigned_fleet_id = $armada->id;
        $order->save();

        // Refresh and load relations to match expected frontend structure
        // including assignedFleet and its nested images if they exist
        $order->load(['user', 'assignedFleet.images']);

        return response()->json([
            'message' => 'Unit armada berhasil ditetapkan',
            'data' => $order
        ]);
    }

    /**
     * Set price for truck orders.
     */
    public function setTruckPrice(Request $request, $id)
    {
        $order = Order::findOrFail($id);

        if (!str_contains(strtolower($order->fleet_type), 'truk')) {
            return response()->json([
                'message' => 'Hanya pesanan truk yang dapat diatur harganya melalui endpoint ini.'
            ], 422);
        }

        if (empty($order->assigned_fleet_id)) {
            return response()->json([
                'message' => 'Tetapkan unit truk terlebih dahulu sebelum mengirim harga.'
            ], 422);
        }

        $validated = $request->validate([
            'total_price' => 'required|numeric|min:1',
            'dp_amount' => 'required|numeric|min:0|lte:total_price',
            'price_note' => 'nullable|string'
        ]);

        $order->total_price = $validated['total_price'];
        $order->dp_amount = $validated['dp_amount'];
        $order->remaining_payment = $validated['total_price'] - $validated['dp_amount'];
        $order->price_note = $validated['price_note'] ?? null;
        
        $order->price_status = 'Harga Dikirim';
        $order->price_sent_at = now();

        if ($order->payment_status === 'Belum Ditagihkan' || $order->payment_status === 'Menunggu Validasi') {
            $order->payment_status = 'Belum Membayar';
        }

        $order->save();

        return response()->json([
            'message' => 'Harga berhasil dikirim ke pelanggan',
            'data' => [
                'order_id' => $order->id,
                'total_price' => $order->total_price,
                'dp_amount' => $order->dp_amount,
                'remaining_payment' => $order->remaining_payment,
                'price_status' => $order->price_status,
                'payment_status' => $order->payment_status
            ]
        ]);
    }

    /**
     * Confirm an order and generate a schedule.
     */
    public function confirm(Request $request, $id)
    {
        $order = Order::with('user')->findOrFail($id);

        if (strtolower($order->fleet_type) === 'truk' || strtolower($order->service_type) === 'truk logistik') {
            if ($order->total_price === null) {
                return response()->json([
                    'message' => 'Harga truk belum ditentukan'
                ], 422);
            }
        }

        if (empty($order->assigned_fleet_id)) {
            return response()->json([
                'message' => 'Tetapkan unit armada terlebih dahulu di menu Pemesanan sebelum menerima DP.'
            ], 422);
        }

        if (!in_array($order->payment_status, ['DP Diterima', 'Lunas', 'Pembayaran Diterima'])) {
            return response()->json([
                'message' => 'Pembayaran belum divalidasi'
            ], 422);
        }

        // Idempotency Check
        $existingJadwal = \App\Models\Jadwal::where('order_id', $order->id)->first();
        if ($existingJadwal) {
            return response()->json([
                'message' => 'Pesanan sudah dikonfirmasi dan jadwal sudah tersedia',
                'data' => [
                    'order_id' => $order->id,
                    'schedule_created' => false,
                    'schedule_exists' => true
                ]
            ]);
        }

        $armadaId = $order->assigned_fleet_id;
        $tanggalMulai = $order->departure_date->format('Y-m-d');
        $jamMulai = $order->departure_time;
        
        $tanggalSelesai = $order->estimated_finish ? $order->estimated_finish->format('Y-m-d') : $tanggalMulai;
        $jamSelesai = $order->estimated_finish ? $order->estimated_finish->format('H:i') : '23:59';

        // Bentrok Check
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

        // Create Jadwal
        $jadwal = null;
        try {
            \Illuminate\Support\Facades\DB::transaction(function () use ($order, $armadaId, $tanggalMulai, $jamMulai, $tanggalSelesai, $jamSelesai, &$jadwal) {
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

                $order->order_status = 'Terjadwal';
                $order->save();
            });
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Gagal membuat jadwal'
            ], 500);
        }

        return response()->json([
            'message' => 'Pesanan berhasil dikonfirmasi dan jadwal berhasil dibuat',
            'data' => [
                'order_id' => $order->id,
                'order_status' => $order->order_status,
                'schedule_created' => true,
                'jadwal_id' => $jadwal->id
            ]
        ]);
    }
}
