<?php

namespace App\Http\Controllers;

use App\Models\Order;
use Illuminate\Http\Request;

class MobileOrderController extends Controller
{
    /**
     * Display a listing of the resource for the authenticated mobile user.
     */
    public function index(Request $request)
    {
        $orders = Order::with(['assignedFleet.images', 'payment'])
            ->where('user_id', $request->user()->id)
            ->whereNull('user_archived_at')
            ->orderBy('created_at', 'desc')
            ->get()
            ->map(function ($order) {
                // Ensure correct formatting for mobile
                return [
                    'id' => $order->id,
                    'order_code' => $order->order_code,
                    'service_type' => $order->service_type,
                    'fleet_name' => $order->fleet_name,
                    'fleet_type' => $order->fleet_type,
                    'origin' => $order->origin,
                    'destination' => $order->destination,
                    'departure_date' => $order->departure_date ? $order->departure_date->format('Y-m-d') : null,
                    'departure_time' => $order->departure_time,
                    'estimated_finish' => $order->estimated_finish ? $order->estimated_finish->format('Y-m-d H:i') : null,
                    'total_price' => $order->total_price ? (float) $order->total_price : null,
                    'payment_status' => $order->payment_status,
                    'order_status' => $order->order_status,
                    'truck_service_type' => $order->truck_service_type,
                    'assigned_fleet_id' => $order->assigned_fleet_id,
                    'assigned_fleet_code' => $order->assignedFleet ? $order->assignedFleet->kode_armada : null,
                    'assigned_fleet_name' => $order->assignedFleet ? $order->assignedFleet->nama_armada : null,
                    'assigned_fleet_plate' => $order->assignedFleet ? $order->assignedFleet->plat_nomor : null,
                    'assigned_fleet_image_url' => $order->assignedFleet && $order->assignedFleet->images->isNotEmpty() 
                        ? $order->assignedFleet->images->where('is_primary', true)->first()?->url 
                          ?? $order->assignedFleet->images->first()->url 
                        : null,
                    'service_cover_image_url' => url('storage/armada/truck_cover.jpg'),
                    'display_image_url' => $order->assigned_fleet_id 
                        ? ($order->assignedFleet && $order->assignedFleet->images->isNotEmpty() 
                            ? ($order->assignedFleet->images->where('is_primary', true)->first()?->url ?? $order->assignedFleet->images->first()->url)
                            : url('storage/armada/truck_cover.jpg'))
                        : url('storage/armada/truck_cover.jpg'),
                    'created_at' => $order->created_at->toIso8601String(),
                    'proof_payment_url' => $order->payment ? $order->payment->payment_proof_url : null,
                    'rejected_reason' => $order->payment ? $order->payment->rejected_reason : null,
                    'dp_amount' => $order->dp_amount ? (float) $order->dp_amount : null,
                    'remaining_payment' => $order->remaining_payment ? (float) $order->remaining_payment : null,
                    'price_status' => $order->price_status,
                    'price_note' => $order->price_note,
                    'price_sent_at' => $order->price_sent_at ? $order->price_sent_at->toIso8601String() : null,
                    'customer_note' => $order->notes,
                    'truck_load_type' => $order->truck_load_type,
                    'truck_load_description' => $order->truck_load_description,
                    'truck_load_weight' => $order->truck_load_weight,
                    'truck_load_weight_unit' => $order->truck_load_weight_unit,
                    'truck_load_quantity' => $order->truck_load_quantity,
                    'truck_load_quantity_unit' => $order->truck_load_quantity_unit,
                    'truck_access_note' => $order->truck_access_note,
                    'truck_additional_note' => $order->truck_additional_note,
                ];
            });

        return response()->json([
            'message' => 'Data pesanan berhasil diambil',
            'data' => $orders
        ]);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'service_type' => 'required|string',
            'fleet_name' => 'required|string',
            'fleet_type' => 'required|string',
            'origin' => 'required|string',
            'destination' => 'required|string',
            'departure_date' => 'required|date',
            'departure_time' => 'required',
            'estimated_finish' => 'nullable|date',
            'total_price' => 'nullable|numeric',
            'notes' => 'nullable|string',
            'truck_service_type' => 'nullable|string',
            'origin_lat' => 'nullable|numeric',
            'origin_lng' => 'nullable|numeric',
            'destination_lat' => 'nullable|numeric',
            'destination_lng' => 'nullable|numeric',
            'truck_load_type' => 'nullable|string',
            'truck_load_description' => 'nullable|string',
            'truck_load_weight' => 'nullable|string',
            'truck_load_weight_unit' => 'nullable|string',
            'truck_load_quantity' => 'nullable|string',
            'truck_load_quantity_unit' => 'nullable|string',
            'truck_access_note' => 'nullable|string',
            'truck_additional_note' => 'nullable|string',
        ]);

        // Generate simple order code
        $lastOrder = Order::latest('id')->first();
        $nextId = $lastOrder ? $lastOrder->id + 1 : 1;
        $orderCode = 'PSN ' . str_pad($nextId, 4, '0', STR_PAD_LEFT);

        try {
        $isTruk = (strtolower($validated['fleet_type']) === 'truk' || strtolower($validated['service_type']) === 'truk logistik');

        if ($isTruk && empty($validated['truck_load_type'])) {
            return response()->json([
                'message' => 'Jenis muatan wajib diisi untuk pesanan truk.',
            ], 422);
        }

        if (!$isTruk) {
            // Check for required dates
            if (empty($validated['estimated_finish'])) {
                return response()->json([
                    'message' => 'Perkiraan selesai wajib diisi untuk menghitung durasi penyewaan Bus dan Elf.',
                ], 422);
            }

            // Hitung estimasi harga
            $priceData = $this->calculateBusElfEstimatedPrice($validated);
            
            $calculatedTotalPrice = $priceData['total_price'];
            $calculatedDpAmount = $priceData['dp_amount'];
            $calculatedRemaining = $priceData['remaining_payment'];
            $priceStatus = 'Estimasi Harga';
            $paymentStatus = 'Menunggu Validasi'; // Jika DP langsung diupload nanti
        } else {
            $calculatedTotalPrice = null;
            $calculatedDpAmount = null;
            $calculatedRemaining = null;
            $priceStatus = 'Menunggu Harga';
            $paymentStatus = 'Belum Membayar';
        }

        $order = Order::create([
            'user_id' => $request->user()->id,
            'order_code' => $orderCode,
            'service_type' => $validated['service_type'],
            'fleet_name' => $validated['fleet_name'],
            'fleet_type' => $validated['fleet_type'],
            'origin' => $validated['origin'],
            'destination' => $validated['destination'],
            'departure_date' => $validated['departure_date'],
            'departure_time' => $validated['departure_time'],
            'estimated_finish' => $validated['estimated_finish'] ?? null,
            'total_price' => $calculatedTotalPrice,
            'dp_amount' => $calculatedDpAmount,
            'remaining_payment' => $calculatedRemaining,
            'payment_status' => $paymentStatus,
            'order_status' => 'Menunggu Konfirmasi',
            'notes' => $validated['notes'] ?? null,
            'truck_service_type' => $validated['truck_service_type'] ?? null,
            'price_status' => $priceStatus,
            'origin_lat' => $validated['origin_lat'] ?? null,
            'origin_lng' => $validated['origin_lng'] ?? null,
            'destination_lat' => $validated['destination_lat'] ?? null,
            'destination_lng' => $validated['destination_lng'] ?? null,
            'truck_load_type' => $validated['truck_load_type'] ?? null,
            'truck_load_description' => $validated['truck_load_description'] ?? null,
            'truck_load_weight' => $validated['truck_load_weight'] ?? null,
            'truck_load_weight_unit' => $validated['truck_load_weight_unit'] ?? null,
            'truck_load_quantity' => $validated['truck_load_quantity'] ?? null,
            'truck_load_quantity_unit' => $validated['truck_load_quantity_unit'] ?? null,
            'truck_access_note' => $validated['truck_access_note'] ?? null,
            'truck_additional_note' => $validated['truck_additional_note'] ?? null,
        ]);

        if ($request->hasFile('payment_proof')) {
            $request->validate([
                'payment_account_id' => 'required|exists:payment_accounts,id',
            ], [
                'payment_account_id.required' => 'Pilih rekening tujuan terlebih dahulu.',
            ]);

            $file = $request->file('payment_proof');
            
            $cloudinary = app(\App\Services\CloudinaryUploadService::class);
            $uploadResult = $cloudinary->uploadImage($file, 'sumber-agung/payment-proofs');
            
            $path = $uploadResult ? $uploadResult['secure_url'] : $file->store('payment_proofs', 'public');
            $publicId = $uploadResult ? $uploadResult['public_id'] : null;
            
            $paymentAccount = \App\Models\PaymentAccount::findOrFail($request->payment_account_id);
            
            $order->payment()->create([
                'user_id' => $request->user()->id,
                'payment_type' => 'DP',
                'payment_account_id' => $paymentAccount->id,
                'bank_name' => $paymentAccount->bank_name,
                'bank_account_number' => $paymentAccount->account_number,
                'bank_account_name' => $paymentAccount->account_holder_name,
                'amount' => $calculatedDpAmount ?? $calculatedTotalPrice ?? 0,
                'payment_proof_path' => $path,
                'cloudinary_public_id' => $publicId,
                'payment_status' => 'Menunggu Validasi',
            ]);
        }

        return response()->json([
            'message' => 'Pesanan berhasil dibuat',
            'data' => $order
        ], 201);
        } catch (\Exception $e) {
            \Log::error('Error creating mobile order: ' . $e->getMessage());
            return response()->json([
                'message' => 'Gagal membuat reservasi. Periksa kelengkapan data dan coba lagi.',
            ], 500);
        }
    }

    /**
     * Hitung estimasi harga untuk Bus dan Elf.
     */
    private function calculateBusElfEstimatedPrice(array $data): array
    {
        $fleetType = strtolower($data['fleet_type']);
        $isBus = str_contains($fleetType, 'bus');
        
        // 1. Dapatkan Harga Dasar
        $armada = \App\Models\Armada::where('nama_armada', $data['fleet_name'])->first();
        $hargaDasar = $armada ? $armada->harga_sewa : ($isBus ? 2500000 : 1500000);

        // 2. Hitung Durasi (Minimal 1 Hari)
        $durasiHari = $this->calculateRentalDays($data['departure_date'], $data['departure_time'], $data['estimated_finish']);
        
        // 3. Hitung Jarak
        $jarakTotalKm = 0;
        if (!empty($data['origin_lat']) && !empty($data['origin_lng']) && !empty($data['destination_lat']) && !empty($data['destination_lng'])) {
            $jarakSatuArah = $this->calculateDistanceKm(
                $data['origin_lat'], $data['origin_lng'],
                $data['destination_lat'], $data['destination_lng']
            );
            
            // Asumsi selalu pulang pergi jika jarak dihitung
            $jarakTotalKm = $jarakSatuArah * 2;
        }

        // 4. Hitung Tarif per KM
        $tarifPerKm = $isBus ? 10000 : 7000;

        // 5. Total
        $biayaDurasi = $hargaDasar * $durasiHari;
        $biayaJarak = $jarakTotalKm * $tarifPerKm;

        $totalPrice = $biayaDurasi + $biayaJarak;

        // 6. DP
        $dpAmount = $this->calculateDpAmount($totalPrice);
        $remainingPayment = $totalPrice - $dpAmount;

        return [
            'total_price' => $totalPrice,
            'dp_amount' => $dpAmount,
            'remaining_payment' => $remainingPayment,
        ];
    }

    /**
     * Hitung durasi penyewaan dalam hitungan hari, minimal 1 hari.
     */
    private function calculateRentalDays($startDateStr, $startTimeStr, $endDateStr): int
    {
        try {
            $start = \Carbon\Carbon::parse($startDateStr . ' ' . $startTimeStr);
            $end = \Carbon\Carbon::parse($endDateStr);
            
            $diffHours = $start->diffInHours($end);
            
            // Minimal 1 hari
            if ($diffHours <= 24) return 1;
            
            return ceil($diffHours / 24);
        } catch (\Exception $e) {
            return 1;
        }
    }

    /**
     * Hitung jarak dua koordinat menggunakan formula Haversine.
     */
    private function calculateDistanceKm($lat1, $lon1, $lat2, $lon2): float
    {
        $earthRadiusKm = 6371;

        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);

        $lat1 = deg2rad($lat1);
        $lat2 = deg2rad($lat2);

        $a = sin($dLat / 2) * sin($dLat / 2) +
             sin($dLon / 2) * sin($dLon / 2) * cos($lat1) * cos($lat2); 
        $c = 2 * atan2(sqrt($a), sqrt(1 - $a)); 
        
        return $earthRadiusKm * $c;
    }

    /**
     * Hitung nominal DP (20%).
     */
    private function calculateDpAmount($totalPrice): float
    {
        // Default 20%
        $percentage = 20; 
        
        // Coba ambil dari BusinessSetting jika ada
        if (class_exists(\App\Models\BusinessSetting::class)) {
            $setting = \App\Models\BusinessSetting::first();
            if ($setting && $setting->dp_percentage) {
                $percentage = $setting->dp_percentage;
            }
        }
        
        $dp = $totalPrice * ($percentage / 100);
        
        // Pembulatan ke 1000 terdekat agar rapi
        return round($dp / 1000) * 1000;
    }

    /**
     * Display the specified resource for the authenticated user.
     */
    public function show(Request $request, $id)
    {
        $order = Order::with(['assignedFleet.images', 'payment', 'payments'])
            ->where('user_id', $request->user()->id)
            ->where('id', $id)
            ->firstOrFail();

        $dpPayment = $order->payments->where('payment_type', 'DP')->last();
        $settlementPayment = $order->payments->where('payment_type', 'Pelunasan')->last();

        $formattedOrder = [
            'id' => $order->id,
            'order_code' => $order->order_code,
            'service_type' => $order->service_type,
            'fleet_name' => $order->fleet_name,
            'fleet_type' => $order->fleet_type,
            'origin' => $order->origin,
            'destination' => $order->destination,
            'departure_date' => $order->departure_date ? $order->departure_date->format('Y-m-d') : null,
            'departure_time' => $order->departure_time,
            'estimated_finish' => $order->estimated_finish ? $order->estimated_finish->format('Y-m-d H:i') : null,
            'total_price' => $order->total_price ? (float) $order->total_price : null,
            'payment_status' => $order->payment_status,
            'order_status' => $order->order_status,
            'truck_service_type' => $order->truck_service_type,
            'assigned_fleet_id' => $order->assigned_fleet_id,
            'assigned_fleet_code' => $order->assignedFleet ? $order->assignedFleet->kode_armada : null,
            'assigned_fleet_name' => $order->assignedFleet ? $order->assignedFleet->nama_armada : null,
            'assigned_fleet_plate' => $order->assignedFleet ? $order->assignedFleet->plat_nomor : null,
            'assigned_fleet_image_url' => $order->assignedFleet && $order->assignedFleet->images->isNotEmpty() 
                ? $order->assignedFleet->images->where('is_primary', true)->first()?->url 
                  ?? $order->assignedFleet->images->first()->url 
                : null,
            'service_cover_image_url' => url('storage/armada/truck_cover.jpg'),
            'display_image_url' => $order->assigned_fleet_id 
                ? ($order->assignedFleet && $order->assignedFleet->images->isNotEmpty() 
                    ? ($order->assignedFleet->images->where('is_primary', true)->first()?->url ?? $order->assignedFleet->images->first()->url)
                    : url('storage/armada/truck_cover.jpg'))
                : url('storage/armada/truck_cover.jpg'),
            'created_at' => $order->created_at->toIso8601String(),
            'canceled_at' => $order->canceled_at ? $order->canceled_at->toIso8601String() : null,
            'cancel_reason' => $order->cancel_reason,
            'proof_payment_url' => $dpPayment ? $dpPayment->payment_proof_url : ($order->payment ? $order->payment->payment_proof_url : null),
            'settlement_proof_url' => $settlementPayment ? $settlementPayment->payment_proof_url : null,
            'rejected_reason' => $order->payment ? $order->payment->rejected_reason : null,
            'dp_amount' => $order->dp_amount ? (float) $order->dp_amount : null,
            'remaining_payment' => $order->remaining_payment ? (float) $order->remaining_payment : null,
            'price_status' => $order->price_status,
            'price_note' => $order->price_note,
            'price_sent_at' => $order->price_sent_at ? $order->price_sent_at->toIso8601String() : null,
            'customer_note' => $order->notes,
            'truck_load_type' => $order->truck_load_type,
            'truck_load_description' => $order->truck_load_description,
            'truck_load_weight' => $order->truck_load_weight,
            'truck_load_weight_unit' => $order->truck_load_weight_unit,
            'truck_load_quantity' => $order->truck_load_quantity,
            'truck_load_quantity_unit' => $order->truck_load_quantity_unit,
            'truck_access_note' => $order->truck_access_note,
            'truck_additional_note' => $order->truck_additional_note,
        ];

        return response()->json([
            'message' => 'Detail pesanan berhasil diambil',
            'data' => $formattedOrder
        ]);
    }

    /**
     * Cancel an order.
     */
    public function cancel(Request $request, $id)
    {
        $order = Order::where('user_id', $request->user()->id)->findOrFail($id);

        $allowedStatuses = [
            'Menunggu Konfirmasi',
            'Menunggu Konfirmasi Admin',
            'Menunggu Pembayaran',
            'Menunggu Validasi Pembayaran'
        ];

        if (!in_array($order->order_status, $allowedStatuses)) {
            return response()->json([
                'message' => 'Pesanan tidak dapat dibatalkan pada status ini'
            ], 422);
        }

        $order->order_status = 'Dibatalkan';
        $order->canceled_at = now();
        if ($request->has('reason')) {
            $order->cancel_reason = $request->reason;
        }
        $order->save();

        return response()->json([
            'message' => 'Pesanan berhasil dibatalkan',
            'data' => $order
        ]);
    }

    /**
     * Upload payment proof for an existing order (e.g., truck orders after admin sets price).
     */
    public function uploadPaymentProof(Request $request, $id)
    {
        $order = Order::with('payment')->where('user_id', $request->user()->id)->findOrFail($id);

        // Validate: price must have been set
        if ($order->total_price === null) {
            return response()->json([
                'message' => 'Harga belum ditentukan oleh admin. Tunggu admin mengirim harga terlebih dahulu.'
            ], 422);
        }

        // Validate: order should not be in terminal state
        if (in_array($order->order_status, ['Selesai', 'Dibatalkan', 'Ditolak'])) {
            return response()->json([
                'message' => 'Pesanan tidak dapat diproses pada status ini'
            ], 422);
        }

        $request->validate([
            'payment_proof' => 'required|file|mimes:jpg,jpeg,png,pdf|max:5120',
            'payment_account_id' => 'required|exists:payment_accounts,id',
        ], [
            'payment_account_id.required' => 'Pilih rekening tujuan terlebih dahulu.',
            'payment_account_id.exists' => 'Rekening tujuan tidak valid.',
        ]);

        try {
            $file = $request->file('payment_proof');
            $cloudinary = app(\App\Services\CloudinaryUploadService::class);
            $uploadResult = $cloudinary->uploadImage($file, 'sumber-agung/payment-proofs');
            
            $path = $uploadResult ? $uploadResult['secure_url'] : $file->store('payment_proofs', 'public');
            $publicId = $uploadResult ? $uploadResult['public_id'] : null;

            $paymentAccount = \App\Models\PaymentAccount::findOrFail($request->payment_account_id);

            // Delete existing payment if any, then create new one
            if ($order->payment) {
                $order->payment->update([
                    'payment_type' => 'DP',
                    'payment_account_id' => $paymentAccount->id,
                    'bank_name' => $paymentAccount->bank_name,
                    'bank_account_number' => $paymentAccount->account_number,
                    'bank_account_name' => $paymentAccount->account_holder_name,
                    'amount' => $order->dp_amount ?? $order->total_price,
                    'payment_proof_path' => $path,
                    'cloudinary_public_id' => $publicId,
                    'payment_status' => 'Menunggu Validasi',
                    'rejected_reason' => null,
                ]);
            } else {
                $order->payment()->create([
                    'user_id' => $request->user()->id,
                    'payment_type' => 'DP',
                    'payment_account_id' => $paymentAccount->id,
                    'bank_name' => $paymentAccount->bank_name,
                    'bank_account_number' => $paymentAccount->account_number,
                    'bank_account_name' => $paymentAccount->account_holder_name,
                    'amount' => $order->dp_amount ?? $order->total_price,
                    'payment_proof_path' => $path,
                    'cloudinary_public_id' => $publicId,
                    'payment_status' => 'Menunggu Validasi',
                ]);
            }

            $order->payment_status = 'Menunggu Validasi DP';
            // Fallback for older orders or other places relying on generic status
            if ($order->payment_status == 'Menunggu Pembayaran' || $order->payment_status == 'Menunggu Validasi') {
                 $order->payment_status = 'Menunggu Validasi DP';
            }
            $order->save();

            return response()->json([
                'message' => 'Bukti pembayaran berhasil diunggah',
                'data' => $order->fresh(['payments'])
            ]);
        } catch (\Exception $e) {
            \Log::error('Error uploading payment proof: ' . $e->getMessage());
            return response()->json([
                'message' => 'Gagal mengirim pembayaran. Coba lagi beberapa saat.'
            ], 500);
        }
    }

    /**
     * Upload settlement payment proof (Pelunasan).
     */
    public function uploadSettlementProof(Request $request, $id)
    {
        $order = Order::with('payments')->where('user_id', $request->user()->id)->findOrFail($id);

        if ($order->payment_status !== 'DP Diterima') {
            if ($order->payment_status === 'Menunggu Validasi DP' || $order->payment_status === 'Belum Membayar') {
                return response()->json([
                    'message' => 'DP belum diterima admin.'
                ], 422);
            }
        }

        if ($order->payment_status === 'Lunas') {
            return response()->json([
                'message' => 'Pesanan sudah lunas.'
            ], 422);
        }

        if (in_array($order->order_status, ['Dibatalkan', 'Ditolak'])) {
            return response()->json([
                'message' => 'Pesanan tidak dapat diproses pada status ini'
            ], 422);
        }

        if (!$order->remaining_payment || $order->remaining_payment <= 0) {
            return response()->json([
                'message' => 'Tidak ada sisa pembayaran.'
            ], 422);
        }

        // Check if there's already a pending settlement
        $existingSettlement = $order->payments()->where('payment_type', 'Pelunasan')->orderBy('id', 'desc')->first();
        if ($existingSettlement) {
            if ($existingSettlement->payment_status === 'Menunggu Validasi') {
                return response()->json([
                    'message' => 'Bukti pelunasan sedang menunggu validasi admin.'
                ], 422);
            }
            if ($existingSettlement->payment_status === 'Diterima') {
                return response()->json([
                    'message' => 'Pesanan sudah lunas.'
                ], 422);
            }
        }

        $request->validate([
            'payment_proof' => 'required|file|mimes:jpg,jpeg,png,pdf|max:5120',
            'payment_account_id' => 'required|exists:payment_accounts,id',
        ], [
            'payment_account_id.required' => 'Pilih rekening tujuan terlebih dahulu.',
            'payment_account_id.exists' => 'Rekening tujuan tidak valid.',
        ]);

        try {
            $file = $request->file('payment_proof');
            $cloudinary = app(\App\Services\CloudinaryUploadService::class);
            $uploadResult = $cloudinary->uploadImage($file, 'sumber-agung/settlement-proofs');
            
            $path = $uploadResult ? $uploadResult['secure_url'] : $file->store('payment_proofs', 'public');
            $publicId = $uploadResult ? $uploadResult['public_id'] : null;
            
            $paymentAccount = \App\Models\PaymentAccount::findOrFail($request->payment_account_id);

            $order->payments()->create([
                'user_id' => $request->user()->id,
                'payment_type' => 'Pelunasan',
                'payment_account_id' => $paymentAccount->id,
                'bank_name' => $paymentAccount->bank_name,
                'bank_account_number' => $paymentAccount->account_number,
                'bank_account_name' => $paymentAccount->account_holder_name,
                'amount' => $order->remaining_payment,
                'payment_proof_path' => $path,
                'settlement_cloudinary_public_id' => $publicId, // Or we could just use cloudinary_public_id since it's a polymorphic relation essentially but we are storing in the same table. Wait, actually we added both to payments table!
                'payment_status' => 'Menunggu Validasi',
            ]);

            $order->payment_status = 'Menunggu Validasi Pelunasan';
            $order->save();

            return response()->json([
                'message' => 'Bukti pelunasan berhasil dikirim dan menunggu validasi admin.',
                'data' => $order->fresh(['payments'])
            ]);
        } catch (\Exception $e) {
            \Log::error('Error uploading settlement proof: ' . $e->getMessage());
            return response()->json([
                'message' => 'Gagal mengirim pelunasan. Coba lagi beberapa saat.'
            ], 500);
        }
    }

    /**
     * Archive an order for the mobile user.
     */
    public function archive(Request $request, $id)
    {
        $order = Order::where('user_id', $request->user()->id)->findOrFail($id);

        $allowedStatuses = ['Selesai', 'Dibatalkan'];

        if (!in_array($order->order_status, $allowedStatuses)) {
            return response()->json([
                'message' => 'Pesanan hanya bisa diarsipkan setelah selesai atau dibatalkan.'
            ], 422);
        }

        if ($order->user_archived_at) {
            return response()->json([
                'message' => 'Pesanan berhasil diarsipkan',
                'data' => [
                    'order_id' => $order->id,
                    'user_archived_at' => $order->user_archived_at->toIso8601String()
                ]
            ]);
        }

        $order->user_archived_at = now();
        $order->save();

        return response()->json([
            'message' => 'Pesanan berhasil diarsipkan',
            'data' => [
                'order_id' => $order->id,
                'user_archived_at' => $order->user_archived_at->toIso8601String()
            ]
        ]);
    }

    /**
     * Display a listing of archived orders for the authenticated mobile user.
     */
    public function archived(Request $request)
    {
        $orders = Order::with(['assignedFleet.images', 'payment'])
            ->where('user_id', $request->user()->id)
            ->whereNotNull('user_archived_at')
            ->orderBy('user_archived_at', 'desc')
            ->get()
            ->map(function ($order) {
                // Ensure correct formatting for mobile
                return [
                    'id' => $order->id,
                    'order_code' => $order->order_code,
                    'service_type' => $order->service_type,
                    'fleet_name' => $order->fleet_name,
                    'fleet_type' => $order->fleet_type,
                    'origin' => $order->origin,
                    'destination' => $order->destination,
                    'departure_date' => $order->departure_date ? $order->departure_date->format('Y-m-d') : null,
                    'departure_time' => $order->departure_time,
                    'estimated_finish' => $order->estimated_finish ? $order->estimated_finish->format('Y-m-d H:i') : null,
                    'total_price' => $order->total_price ? (float) $order->total_price : null,
                    'payment_status' => $order->payment_status,
                    'order_status' => $order->order_status,
                    'truck_service_type' => $order->truck_service_type,
                    'assigned_fleet_id' => $order->assigned_fleet_id,
                    'assigned_fleet_code' => $order->assignedFleet ? $order->assignedFleet->kode_armada : null,
                    'assigned_fleet_name' => $order->assignedFleet ? $order->assignedFleet->nama_armada : null,
                    'assigned_fleet_plate' => $order->assignedFleet ? $order->assignedFleet->plat_nomor : null,
                    'assigned_fleet_image_url' => $order->assignedFleet && $order->assignedFleet->images->isNotEmpty() 
                        ? $order->assignedFleet->images->where('is_primary', true)->first()?->url 
                          ?? $order->assignedFleet->images->first()->url 
                        : null,
                    'service_cover_image_url' => url('storage/armada/truck_cover.jpg'),
                    'display_image_url' => $order->assigned_fleet_id 
                        ? ($order->assignedFleet && $order->assignedFleet->images->isNotEmpty() 
                            ? ($order->assignedFleet->images->where('is_primary', true)->first()?->url ?? $order->assignedFleet->images->first()->url)
                            : url('storage/armada/truck_cover.jpg'))
                        : url('storage/armada/truck_cover.jpg'),
                    'created_at' => $order->created_at->toIso8601String(),
                    'proof_payment_url' => $order->payment ? $order->payment->payment_proof_url : null,
                    'rejected_reason' => $order->payment ? $order->payment->rejected_reason : null,
                    'dp_amount' => $order->dp_amount ? (float) $order->dp_amount : null,
                    'remaining_payment' => $order->remaining_payment ? (float) $order->remaining_payment : null,
                    'price_status' => $order->price_status,
                    'price_note' => $order->price_note,
                    'price_sent_at' => $order->price_sent_at ? $order->price_sent_at->toIso8601String() : null,
                    'customer_note' => $order->notes,
                    'truck_load_type' => $order->truck_load_type,
                    'truck_load_description' => $order->truck_load_description,
                    'truck_load_weight' => $order->truck_load_weight,
                    'truck_load_weight_unit' => $order->truck_load_weight_unit,
                    'truck_load_quantity' => $order->truck_load_quantity,
                    'truck_load_quantity_unit' => $order->truck_load_quantity_unit,
                    'truck_access_note' => $order->truck_access_note,
                    'truck_additional_note' => $order->truck_additional_note,
                    'user_archived_at' => $order->user_archived_at ? $order->user_archived_at->toIso8601String() : null,
                ];
            });

        return response()->json([
            'message' => 'Berhasil mengambil pesanan yang diarsipkan',
            'data' => $orders
        ]);
    }

    /**
     * Unarchive an order for the mobile user.
     */
    public function unarchive(Request $request, $id)
    {
        $order = Order::where('user_id', $request->user()->id)->findOrFail($id);

        if (!$order->user_archived_at) {
            return response()->json([
                'message' => 'Pesanan berhasil dipulihkan',
                'data' => [
                    'order_id' => $order->id,
                    'user_archived_at' => null
                ]
            ]);
        }

        $order->user_archived_at = null;
        $order->save();

        return response()->json([
            'message' => 'Pesanan berhasil dipulihkan',
            'data' => [
                'order_id' => $order->id,
                'user_archived_at' => null
            ]
        ]);
    }
}
