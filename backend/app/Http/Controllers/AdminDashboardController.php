<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Order;
use App\Models\Payment;
use App\Models\Jadwal;
use App\Models\Armada;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class AdminDashboardController extends Controller
{
    public function dashboard(Request $request)
    {
        $incomePeriod = $request->query('income_period', 'Bulan Ini');
        $statsPeriod = $request->query('stats_period', 'Mingguan');
        $month = $request->query('month', date('n'));
        $year = $request->query('year', date('Y'));

        try {
            // 1. Summary
            $summary = [
                'total_pendapatan' => $this->getTotalPendapatan($incomePeriod),
                'total_armada' => Armada::count(),
                'jadwal_aktif' => Jadwal::where('status_jadwal', 'Terjadwal')->count(),
                'permintaan_jadwal' => Order::where('order_status', 'Menunggu Konfirmasi')->count(),
                'pembayaran_menunggu' => Payment::where('payment_status', 'Menunggu Validasi')->count(),
            ];

            // 2. Booking Statistics
            $bookingStatistics = $this->getBookingStatistics($statsPeriod);

            // 3. Calendar Data
            $calendar = $this->getCalendarData($month, $year);

            // 4. Recent Activities
            $recentActivities = $this->getRecentActivities();

            // 5. Latest Schedules
            $latestSchedules = $this->getLatestSchedules();

            return response()->json([
                'data' => [
                    'summary' => $summary,
                    'booking_statistics' => $bookingStatistics,
                    'calendar' => $calendar,
                    'recent_activities' => $recentActivities,
                    'latest_schedules' => $latestSchedules
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Gagal mengambil data dashboard',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    private function getTotalPendapatan($period)
    {
        $query = Payment::whereIn('payment_status', ['Diterima', 'Lunas', 'diterima', 'lunas']);

        $now = Carbon::now();
        if ($period === 'Hari Ini') {
            $query->where(function($q) use ($now) {
                $q->whereDate('verified_at', $now->toDateString())
                  ->orWhereDate('updated_at', $now->toDateString());
            });
        } elseif ($period === 'Minggu Ini') {
            $query->where(function($q) use ($now) {
                $q->whereBetween('verified_at', [$now->startOfWeek()->toDateString(), $now->endOfWeek()->toDateString()])
                  ->orWhereBetween('updated_at', [$now->startOfWeek()->toDateString(), $now->endOfWeek()->toDateString()]);
            });
        } elseif ($period === 'Bulan Ini') {
            $query->where(function($q) use ($now) {
                $q->whereMonth('verified_at', $now->month)->whereYear('verified_at', $now->year)
                  ->orWhere(function($sub) use ($now) {
                      $sub->whereMonth('updated_at', $now->month)->whereYear('updated_at', $now->year);
                  });
            });
        } elseif ($period === 'Tahun Ini') {
            $query->where(function($q) use ($now) {
                $q->whereYear('verified_at', $now->year)
                  ->orWhereYear('updated_at', $now->year);
            });
        }

        return (float) $query->sum('amount');
    }

    private function getBookingStatistics($period)
    {
        $now = Carbon::now();
        $stats = [];

        if ($period === 'Mingguan') {
            $startOfWeek = $now->copy()->startOfWeek(Carbon::SUNDAY); // Min
            
            for ($i = 0; $i < 7; $i++) {
                $date = $startOfWeek->copy()->addDays($i);
                $dateString = $date->toDateString();
                
                $orders = Order::whereDate('departure_date', $dateString)->get();
                
                $stats[] = [
                    'hari' => $this->getIndonesianDay($date->dayOfWeek),
                    'busMedium' => $this->countFleetType($orders, 'Bus'),
                    'elfLong' => $this->countFleetType($orders, 'Elf'),
                    'trukCDD' => $this->countFleetType($orders, 'Truk'),
                ];
            }
        } elseif ($period === 'Bulanan') {
            // Data per minggu di bulan berjalan
            $startOfMonth = $now->copy()->startOfMonth();
            $endOfMonth = $now->copy()->endOfMonth();
            
            $weeksInMonth = (int) ceil($endOfMonth->day / 7);
            
            for ($i = 1; $i <= $weeksInMonth; $i++) {
                $weekStart = $startOfMonth->copy()->addDays(($i - 1) * 7);
                $weekEnd = $i === $weeksInMonth ? $endOfMonth : $weekStart->copy()->addDays(6);
                
                $orders = Order::whereBetween('departure_date', [$weekStart->toDateString(), $weekEnd->toDateString()])->get();
                
                $stats[] = [
                    'hari' => 'Mg ' . $i,
                    'busMedium' => $this->countFleetType($orders, 'Bus'),
                    'elfLong' => $this->countFleetType($orders, 'Elf'),
                    'trukCDD' => $this->countFleetType($orders, 'Truk'),
                ];
            }
        } elseif ($period === 'Tahunan') {
            for ($i = 1; $i <= 12; $i++) {
                $orders = Order::whereYear('departure_date', $now->year)
                               ->whereMonth('departure_date', $i)
                               ->get();
                
                $stats[] = [
                    'hari' => $this->getIndonesianShortMonth($i),
                    'busMedium' => $this->countFleetType($orders, 'Bus'),
                    'elfLong' => $this->countFleetType($orders, 'Elf'),
                    'trukCDD' => $this->countFleetType($orders, 'Truk'),
                ];
            }
        }

        return $stats;
    }

    private function getIndonesianDay($dayOfWeek)
    {
        $days = [0 => 'Min', 1 => 'Sen', 2 => 'Sel', 3 => 'Rab', 4 => 'Kam', 5 => 'Jum', 6 => 'Sab'];
        return $days[$dayOfWeek] ?? '';
    }

    private function getIndonesianShortMonth($month)
    {
        $months = [1 => 'Jan', 2 => 'Feb', 3 => 'Mar', 4 => 'Apr', 5 => 'Mei', 6 => 'Jun', 7 => 'Jul', 8 => 'Ags', 9 => 'Sep', 10 => 'Okt', 11 => 'Nov', 12 => 'Des'];
        return $months[$month] ?? '';
    }

    private function countFleetType($orders, $type)
    {
        return $orders->filter(function($order) use ($type) {
            return stripos($order->fleet_type, $type) !== false;
        })->count();
    }

    private function getCalendarData($month, $year)
    {
        $jadwals = Jadwal::whereMonth('tanggal_mulai', $month)
                         ->whereYear('tanggal_mulai', $year)
                         ->select('tanggal_mulai', DB::raw('count(*) as count'))
                         ->groupBy('tanggal_mulai')
                         ->get();

        return $jadwals->map(function($jadwal) {
            return [
                'date' => Carbon::parse($jadwal->tanggal_mulai)->format('Y-m-d'),
                'count' => $jadwal->count
            ];
        });
    }

    private function getRecentActivities()
    {
        $activities = collect([]);

        // 1. Orders
        $orders = Order::orderBy('created_at', 'desc')->take(5)->get();
        foreach ($orders as $order) {
            $activities->push([
                'type' => 'order',
                'title' => 'Pesanan Baru',
                'description' => "Pesanan {$order->order_code} dari " . ($order->user ? $order->user->name : 'Pelanggan'),
                'timestamp' => $order->created_at,
                'color' => 'blue'
            ]);
        }

        // 2. Payments (Menunggu Validasi)
        $paymentsPending = Payment::where('payment_status', 'Menunggu Validasi')->orderBy('updated_at', 'desc')->take(5)->get();
        foreach ($paymentsPending as $payment) {
            $activities->push([
                'type' => 'payment_pending',
                'title' => 'Pembayaran Menunggu Validasi',
                'description' => "Pesanan " . ($payment->order ? $payment->order->order_code : 'Unknown') . " membutuhkan validasi",
                'timestamp' => $payment->updated_at,
                'color' => 'orange'
            ]);
        }

        // 3. Payments (Diterima)
        $paymentsAccepted = Payment::whereIn('payment_status', ['Diterima', 'Lunas'])->orderBy('updated_at', 'desc')->take(5)->get();
        foreach ($paymentsAccepted as $payment) {
            $activities->push([
                'type' => 'payment_accepted',
                'title' => 'Pembayaran Diterima',
                'description' => "Pembayaran pesanan " . ($payment->order ? $payment->order->order_code : 'Unknown') . " telah divalidasi",
                'timestamp' => $payment->updated_at,
                'color' => 'green'
            ]);
        }

        // 4. Jadwals
        $jadwals = Jadwal::orderBy('created_at', 'desc')->take(5)->get();
        foreach ($jadwals as $jadwal) {
            $activities->push([
                'type' => 'jadwal',
                'title' => 'Jadwal Dibuat',
                'description' => "Jadwal untuk armada {$jadwal->armada->nama_armada} telah dibuat",
                'timestamp' => $jadwal->created_at,
                'color' => 'purple'
            ]);
        }

        // Sort by timestamp desc and take 5
        return $activities->sortByDesc('timestamp')->take(5)->map(function($act, $index) {
            // Helper relative time
            $diffForHumans = Carbon::parse($act['timestamp'])->locale('id')->diffForHumans();
            return [
                'id' => $index + 1,
                'type' => $act['type'],
                'title' => $act['title'],
                'description' => $act['description'],
                'time' => strtoupper($diffForHumans),
                'color' => $act['color']
            ];
        })->values();
    }

    private function getLatestSchedules()
    {
        $jadwals = Jadwal::with(['armada'])->orderBy('created_at', 'desc')->take(5)->get();
        
        return $jadwals->map(function($jadwal) {
            return [
                'tanggal' => Carbon::parse($jadwal->tanggal_mulai)->locale('id')->isoFormat('DD MMMM') . ', ' . ($jadwal->jam_berangkat ?: '00:00'),
                'armada' => $jadwal->armada ? $jadwal->armada->nama_armada : 'Tidak Diketahui',
                'plat' => $jadwal->armada ? $jadwal->armada->plat_nomor : 'Plat belum diisi',
                'rute' => ($jadwal->lokasi_asal && $jadwal->lokasi_tujuan) ? $jadwal->lokasi_asal . ' → ' . $jadwal->lokasi_tujuan : 'Rute belum tersedia',
                'status' => $jadwal->status_jadwal
            ];
        });
    }

    public function calendar(Request $request)
    {
        $month = $request->query('month', date('n'));
        $year = $request->query('year', date('Y'));

        try {
            $jadwals = Jadwal::with(['order', 'armada'])
                ->whereMonth('tanggal_mulai', $month)
                ->whereYear('tanggal_mulai', $year)
                ->get();

            $groupedByDate = $jadwals->groupBy(function($item) {
                return Carbon::parse($item->tanggal_mulai)->format('Y-m-d');
            });

            $datesData = [];

            foreach ($groupedByDate as $date => $dayJadwals) {
                $statusSummary = [
                    'terjadwal' => 0,
                    'perlu_diselesaikan' => 0,
                    'selesai' => 0,
                    'dibatalkan' => 0
                ];
                
                $items = [];

                foreach ($dayJadwals as $jadwal) {
                    $order = $jadwal->order;
                    $armada = $jadwal->armada;

                    $isPerluDiselesaikan = false;
                    $isSelesai = false;
                    $isDibatalkan = false;
                    $isTerjadwal = false;

                    if ($jadwal->status_jadwal === 'Selesai' || ($order && $order->order_status === 'Selesai')) {
                        $isSelesai = true;
                    } elseif ($jadwal->status_jadwal === 'Dibatalkan' || ($order && $order->order_status === 'Dibatalkan')) {
                        $isDibatalkan = true;
                    } elseif ($jadwal->status_jadwal === 'Terjadwal') {
                        $now = Carbon::now();
                        $endTime = null;

                        if ($order && $order->estimated_finish) {
                            $endTime = Carbon::parse($order->estimated_finish);
                        } elseif ($jadwal->tanggal_selesai) {
                            $timeStr = $jadwal->jam_selesai ?: '23:59:59';
                            $endTime = Carbon::parse($jadwal->tanggal_selesai->format('Y-m-d') . ' ' . $timeStr);
                        }

                        if ($endTime && $endTime->isPast() && $order && $order->payment_status === 'Lunas' && !in_array($order->order_status, ['Selesai', 'Dibatalkan'])) {
                            $isPerluDiselesaikan = true;
                        } else {
                            $isTerjadwal = true;
                        }
                    }

                    if ($isPerluDiselesaikan) {
                        $statusSummary['perlu_diselesaikan']++;
                    } elseif ($isTerjadwal) {
                        $statusSummary['terjadwal']++;
                    } elseif ($isSelesai) {
                        $statusSummary['selesai']++;
                    } elseif ($isDibatalkan) {
                        $statusSummary['dibatalkan']++;
                    }

                    $items[] = [
                        'id' => $jadwal->id,
                        'jadwal_id' => $jadwal->id,
                        'order_id' => $order ? $order->id : null,
                        'order_code' => $jadwal->kode_pesanan,
                        'fleet_name' => $armada ? $armada->nama_armada : 'Armada belum ditetapkan',
                        'fleet_type' => $armada ? $armada->jenis_armada : null,
                        'plate_number' => $armada ? $armada->plat_nomor : null,
                        'customer_name' => $jadwal->nama_pelanggan,
                        'route' => ($jadwal->lokasi_asal && $jadwal->lokasi_tujuan) ? $jadwal->lokasi_asal . ' ke ' . $jadwal->lokasi_tujuan : 'Rute belum tersedia',
                        'start_time' => $jadwal->jam_berangkat ? Carbon::parse($jadwal->jam_berangkat)->format('H.i') : 'Jam belum tersedia',
                        'status_jadwal' => $jadwal->status_jadwal,
                        'order_status' => $order ? $order->order_status : null,
                        'payment_status' => $order ? $order->payment_status : null,
                    ];
                }

                $datesData[] = [
                    'date' => $date,
                    'total' => $dayJadwals->count(),
                    'status_summary' => $statusSummary,
                    'items' => $items
                ];
            }

            return response()->json([
                'data' => [
                    'month' => (int) $month,
                    'year' => (int) $year,
                    'dates' => $datesData
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Gagal mengambil data kalender',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
