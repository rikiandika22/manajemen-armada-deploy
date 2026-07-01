<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Order;
use App\Models\Payment;
use App\Models\Armada;
use Barryvdh\DomPDF\Facade\Pdf;
use Carbon\Carbon;

class AdminReportController extends Controller
{
    /**
     * Get summary data for Laporan page
     */
    public function summary(Request $request)
    {
        $startDate = $request->query('start_date');
        $endDate = $request->query('end_date');
        $fleetType = $request->query('fleet_type');
        $status = $request->query('status');

        try {
            // 1. Total Pemesanan
            $ordersQuery = Order::query();
            if ($startDate && $endDate) {
                $ordersQuery->whereBetween('departure_date', [$startDate, $endDate]);
            }
            if ($fleetType && $fleetType !== 'Semua') {
                $ordersQuery->where('fleet_type', $fleetType);
            }
            if ($status && $status !== 'Semua') {
                $ordersQuery->where('order_status', $status);
            }
            $totalPemesanan = $ordersQuery->count();

            // 2. Total Pembayaran Masuk
            $paymentsQuery = Payment::whereIn('payment_status', ['Diterima', 'Lunas', 'diterima', 'lunas']);
            if ($startDate && $endDate) {
                // Use verified_at or updated_at
                $paymentsQuery->where(function ($q) use ($startDate, $endDate) {
                    $q->whereBetween('verified_at', [$startDate . ' 00:00:00', $endDate . ' 23:59:59'])
                      ->orWhereBetween('updated_at', [$startDate . ' 00:00:00', $endDate . ' 23:59:59']);
                });
            }
            if ($fleetType && $fleetType !== 'Semua') {
                $paymentsQuery->whereHas('order', function ($q) use ($fleetType) {
                    $q->where('fleet_type', $fleetType);
                });
            }
            if ($status && $status !== 'Semua') {
                $paymentsQuery->whereHas('order', function ($q) use ($status) {
                    $q->where('order_status', $status);
                });
            }
            $totalPembayaranMasuk = $paymentsQuery->sum('amount');

            // 3. Armada Aktif
            $armadaAktif = Armada::whereIn('status_operasional', ['Tersedia', 'Aktif', 'tersedia', 'aktif'])->count();

            return response()->json([
                'data' => [
                    'total_pemesanan' => $totalPemesanan,
                    'total_pembayaran_masuk' => (float) $totalPembayaranMasuk,
                    'armada_aktif' => $armadaAktif
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json(['message' => 'Gagal mengambil summary laporan', 'error' => $e->getMessage()], 500);
        }
    }

    /**
     * Get operational reports list
     */
    public function operational(Request $request)
    {
        try {
            $data = $this->getReportData($request);
            
            return response()->json([
                'data' => $data,
                'meta' => [
                    'total' => count($data)
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json(['message' => 'Gagal mengambil data operasional', 'error' => $e->getMessage()], 500);
        }
    }

    /**
     * Generate PDF Export
     */
    public function exportPdf(Request $request)
    {
        try {
            $data = $this->getReportData($request);
            
            if (empty($data)) {
                return response()->json(['message' => 'Tidak ada data untuk diekspor.'], 404);
            }

            $summary = json_decode($this->summary($request)->getContent(), true)['data'] ?? [];

            $pdf = Pdf::loadView('exports.report_pdf', [
                'data' => $data,
                'summary' => $summary,
                'start_date' => $request->query('start_date'),
                'end_date' => $request->query('end_date'),
                'fleet_type' => $request->query('fleet_type'),
                'now' => Carbon::now()->locale('id')->isoFormat('D MMMM Y')
            ]);
            
            $pdf->setPaper('a4', 'landscape');

            return $pdf->download('laporan_operasional_' . date('Ymd_His') . '.pdf');
        } catch (\Exception $e) {
            return response()->json(['message' => 'Gagal mengexport PDF', 'error' => $e->getMessage()], 500);
        }
    }

    /**
     * Generate Excel (CSV) Export
     */
    public function exportExcel(Request $request)
    {
        try {
            $data = $this->getReportData($request);
            
            if (empty($data)) {
                return response()->json(['message' => 'Tidak ada data untuk diekspor.'], 404);
            }

            $filename = 'laporan_operasional_' . date('Ymd_His') . '.csv';
            
            $headers = [
                "Content-type"        => "text/csv",
                "Content-Disposition" => "attachment; filename=$filename",
                "Pragma"              => "no-cache",
                "Cache-Control"       => "must-revalidate, post-check=0, pre-check=0",
                "Expires"             => "0"
            ];

            $columns = ['Kode Pesanan', 'Tanggal', 'Jenis Armada', 'Rute', 'Pelanggan', 'Pendapatan', 'Status'];

            $callback = function() use($data, $columns) {
                $file = fopen('php://output', 'w');
                fputcsv($file, $columns);

                foreach ($data as $row) {
                    fputcsv($file, [
                        $row['order_code'],
                        $row['date'],
                        $row['fleet_type'],
                        $row['route'],
                        $row['customer_name'],
                        $row['income'],
                        $row['status']
                    ]);
                }
                fclose($file);
            };

            return response()->stream($callback, 200, $headers);
        } catch (\Exception $e) {
            return response()->json(['message' => 'Gagal mengexport Excel', 'error' => $e->getMessage()], 500);
        }
    }

    /**
     * Helper to get report data
     */
    private function getReportData(Request $request)
    {
        $startDate = $request->query('start_date');
        $endDate = $request->query('end_date');
        $fleetType = $request->query('fleet_type');
        $status = $request->query('status');

        $query = Order::with(['user', 'payments' => function ($q) {
            $q->whereIn('payment_status', ['Diterima', 'Lunas', 'diterima', 'lunas']);
        }]);

        if ($startDate && $endDate) {
            $query->whereBetween('departure_date', [$startDate, $endDate]);
        }
        if ($fleetType && $fleetType !== 'Semua') {
            $query->where('fleet_type', $fleetType);
        }
        if ($status && $status !== 'Semua') {
            $query->where('order_status', $status);
        }

        $orders = $query->orderBy('departure_date', 'desc')->get();

        $data = [];
        foreach ($orders as $order) {
            // Hitung pendapatan hanya dari payment yang sudah diterima
            $income = $order->payments->sum('amount');

            // Format route
            $route = ($order->origin && $order->destination) 
                ? $order->origin . ' ke ' . $order->destination 
                : 'Rute belum tersedia';

            $customerName = $order->user ? $order->user->name : 'Tidak diketahui';

            $data[] = [
                'id' => $order->id,
                'report_code' => $order->order_code,
                'order_code' => $order->order_code,
                'date' => $order->departure_date,
                'fleet_type' => $order->fleet_type,
                'route' => $route,
                'customer_name' => $customerName,
                'income' => (float) $income,
                'status' => $order->payment_status // Use payment status or order status based on preference, instruction says "Status" usually it's payment_status or order_status. I'll use payment_status like the frontend mockup.
            ];
        }

        return $data;
    }
}
