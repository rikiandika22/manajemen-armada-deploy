<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Order;
use App\Models\Payment;
use App\Models\Jadwal;
use App\Models\Armada;

class AdminGlobalSearchController extends Controller
{
    public function search(Request $request)
    {
        $q = trim($request->query('q', ''));
        
        if (strlen($q) < 2) {
            return response()->json([
                'data' => [
                    'orders' => [],
                    'payments' => [],
                    'fleets' => [],
                    'schedules' => []
                ],
                'meta' => [
                    'total' => 0
                ]
            ]);
        }

        // Search Orders
        $orders = Order::with(['user'])
            ->where(function($query) use ($q) {
                $query->where('order_code', 'LIKE', "%{$q}%")
                      ->orWhere('service_type', 'LIKE', "%{$q}%")
                      ->orWhere('fleet_type', 'LIKE', "%{$q}%")
                      ->orWhere('origin', 'LIKE', "%{$q}%")
                      ->orWhere('destination', 'LIKE', "%{$q}%")
                      ->orWhere('order_status', 'LIKE', "%{$q}%")
                      ->orWhere('payment_status', 'LIKE', "%{$q}%")
                      ->orWhereHas('user', function($u) use ($q) {
                          $u->where('name', 'LIKE', "%{$q}%")
                            ->orWhere('phone', 'LIKE', "%{$q}%");
                      });
            })
            ->orderBy('created_at', 'desc')
            ->take(5)
            ->get();

        $orderResults = $orders->map(function($order) {
            $customerName = $order->user ? $order->user->name : 'Unknown';
            return [
                'id' => $order->id,
                'type' => 'order',
                'title' => $order->order_code,
                'subtitle' => "{$customerName}, {$order->fleet_type}, {$order->payment_status}",
                'description' => "{$order->origin} ke {$order->destination}",
                'target_page' => 'pemesanan',
                'target_id' => $order->id,
                'order_code' => $order->order_code
            ];
        });

        // Search Payments
        $payments = Payment::with(['order', 'order.user'])
            ->where(function($query) use ($q) {
                $query->where('bank_name', 'LIKE', "%{$q}%")
                      ->orWhere('payment_type', 'LIKE', "%{$q}%")
                      ->orWhere('payment_status', 'LIKE', "%{$q}%")
                      ->orWhere('amount', 'LIKE', "%{$q}%")
                      ->orWhereHas('order', function($o) use ($q) {
                          $o->where('order_code', 'LIKE', "%{$q}%")
                            ->orWhereHas('user', function($u) use ($q) {
                                $u->where('name', 'LIKE', "%{$q}%");
                            });
                      });
            })
            ->orderBy('created_at', 'desc')
            ->take(5)
            ->get();

        $paymentResults = $payments->map(function($payment) {
            $orderCode = $payment->order ? $payment->order->order_code : 'Unknown';
            $nominal = 'Rp ' . number_format((float)$payment->amount, 0, ',', '.');
            return [
                'id' => $payment->id,
                'type' => 'payment',
                'title' => $orderCode,
                'subtitle' => "{$payment->payment_type}, {$this->normalizeStatus($payment->payment_status)}",
                'description' => "{$payment->bank_name}, {$nominal}",
                'target_page' => 'pembayaran',
                'target_id' => $payment->id,
                'order_code' => $orderCode
            ];
        });

        // Search Armadas
        $fleets = Armada::where(function($query) use ($q) {
                $query->where('kode_armada', 'LIKE', "%{$q}%")
                      ->orWhere('nama_armada', 'LIKE', "%{$q}%")
                      ->orWhere('plat_nomor', 'LIKE', "%{$q}%")
                      ->orWhere('jenis_armada', 'LIKE', "%{$q}%")
                      ->orWhere('status_operasional', 'LIKE', "%{$q}%");
            })
            ->orderBy('created_at', 'desc')
            ->take(5)
            ->get();

        $fleetResults = $fleets->map(function($fleet) {
            return [
                'id' => $fleet->id,
                'type' => 'fleet',
                'title' => $fleet->kode_armada,
                'subtitle' => "{$fleet->plat_nomor}, {$fleet->jenis_armada}",
                'description' => "Status {$this->normalizeStatus($fleet->status_operasional)}",
                'target_page' => 'armada',
                'target_id' => $fleet->id,
                'kode_armada' => $fleet->kode_armada
            ];
        });

        // Search Jadwals
        $schedules = Jadwal::with(['order', 'armada', 'order.user'])
            ->where(function($query) use ($q) {
                $query->where('lokasi_asal', 'LIKE', "%{$q}%")
                      ->orWhere('lokasi_tujuan', 'LIKE', "%{$q}%")
                      ->orWhere('status_jadwal', 'LIKE', "%{$q}%")
                      ->orWhereHas('order', function($o) use ($q) {
                          $o->where('order_code', 'LIKE', "%{$q}%")
                            ->orWhereHas('user', function($u) use ($q) {
                                $u->where('name', 'LIKE', "%{$q}%");
                            });
                      })
                      ->orWhereHas('armada', function($a) use ($q) {
                          $a->where('nama_armada', 'LIKE', "%{$q}%")
                            ->orWhere('plat_nomor', 'LIKE', "%{$q}%");
                      });
            })
            ->orderBy('created_at', 'desc')
            ->take(5)
            ->get();

        $scheduleResults = $schedules->map(function($schedule) {
            $orderCode = $schedule->order ? $schedule->order->order_code : 'Tanpa Pesanan';
            $armadaName = $schedule->armada ? $schedule->armada->nama_armada : 'Armada Belum Diisi';
            $rute = ($schedule->lokasi_asal && $schedule->lokasi_tujuan) ? "{$schedule->lokasi_asal} ke {$schedule->lokasi_tujuan}" : 'Rute belum tersedia';

            return [
                'id' => $schedule->id,
                'type' => 'schedule',
                'title' => $orderCode,
                'subtitle' => "{$armadaName}, {$this->normalizeStatus($schedule->status_jadwal)}",
                'description' => $rute,
                'target_page' => 'jadwal',
                'target_id' => $schedule->id,
                'order_code' => $orderCode
            ];
        });

        return response()->json([
            'data' => [
                'orders' => $orderResults,
                'payments' => $paymentResults,
                'fleets' => $fleetResults,
                'schedules' => $scheduleResults
            ],
            'meta' => [
                'total' => count($orderResults) + count($paymentResults) + count($fleetResults) + count($scheduleResults)
            ]
        ]);
    }

    private function normalizeStatus($status)
    {
        $statusStr = str_replace('_', ' ', strtolower((string)$status));
        return ucwords($statusStr);
    }
}
