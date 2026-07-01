<?php

namespace App\Http\Controllers;

use App\Models\Armada;
use Illuminate\Http\Request;
use Carbon\Carbon;

class MobileFleetController extends Controller
{
    /**
     * Tampilkan semua daftar armada untuk mobile (bukan dummy).
     */
    public function index()
    {
        $armadas = Armada::with('images')->orderBy('created_at', 'desc')->get();

        $data = $armadas->map(function ($armada) {
            $images = $armada->images->map(function ($img) {
                return [
                    'id' => $img->id,
                    'url' => $img->url,
                    'is_primary' => $img->is_primary,
                ];
            });

            $imageUrl = null;
            if ($images->count() > 0) {
                $primary = $images->firstWhere('is_primary', true) ?? $images->first();
                $imageUrl = $primary['url'];
            }

            return [
                'id' => $armada->id,
                'fleet_code' => $armada->kode_armada,
                'fleet_name' => $armada->nama_armada,
                'fleet_type' => $armada->jenis_armada,
                'capacity' => $armada->kapasitas . ' ' . $armada->satuan_kapasitas,
                'license_plate' => $armada->plat_nomor,
                'status' => $this->mapStatusToMobile($armada->display_status),
                'price' => (float) ($armada->harga_sewa ?? 0),
                'description' => $armada->keterangan,
                'image_url' => $imageUrl,
                'images' => $images,
            ];
        });

        return response()->json([
            'message' => 'Data armada berhasil diambil',
            'data' => $data,
        ]);
    }

    /**
     * Detail satu armada.
     */
    public function show($id)
    {
        $armada = Armada::with('images')->find($id);

        if (!$armada) {
            return response()->json([
                'message' => 'Armada tidak ditemukan',
            ], 404);
        }

        $images = $armada->images->map(function ($img) {
            return [
                'id' => $img->id,
                'url' => $img->url,
                'is_primary' => $img->is_primary,
            ];
        });

        $imageUrl = null;
        if ($images->count() > 0) {
            $primary = $images->firstWhere('is_primary', true) ?? $images->first();
            $imageUrl = $primary['url'];
        }

        return response()->json([
            'message' => 'Detail armada berhasil diambil',
            'data' => [
                'id' => $armada->id,
                'fleet_code' => $armada->kode_armada,
                'fleet_name' => $armada->nama_armada,
                'fleet_type' => $armada->jenis_armada,
                'capacity' => $armada->kapasitas . ' ' . $armada->satuan_kapasitas,
                'license_plate' => $armada->plat_nomor,
                'status' => $this->mapStatusToMobile($armada->display_status),
                'price' => (float) ($armada->harga_sewa ?? 0),
                'description' => $armada->keterangan,
                'image_url' => $imageUrl,
                'images' => $images,
            ]
        ]);
    }

    /**
     * Get availability schedule for a fleet or all trucks.
     */
    public function availability(Request $request, $id)
    {
        $month = $request->query('month', date('n'));
        $year = $request->query('year', date('Y'));
        
        $startDate = Carbon::create($year, $month, 1)->startOfDay();
        $endDate = $startDate->copy()->endOfMonth()->endOfDay();
        
        $isAllTrucks = ($id === 'truck-all');
        $unitId = $request->query('unit_id');
        
        $armadas = collect();
        if ($isAllTrucks) {
            $query = Armada::where(function($q) {
                $q->where('jenis_armada', 'like', '%truk%')
                  ->orWhere('jenis_armada', 'like', '%truck%');
            });
            if ($unitId && $unitId !== 'all') {
                $query->where('id', $unitId);
            }
            $armadas = $query->get();
        } else {
            $armada = Armada::find($id);
            if (!$armada) {
                return response()->json(['message' => 'Armada tidak ditemukan'], 404);
            }
            $armadas->push($armada);
        }
        
        if ($armadas->isEmpty()) {
            return response()->json(['message' => 'Armada tidak ditemukan'], 404);
        }
        
        $mainStatus = 'Tersedia';
        if ($armadas->count() === 1) {
            $statusOp = strtolower($armadas->first()->status_operasional);
            if (in_array($statusOp, ['perawatan', 'tidak_aktif', 'tidak aktif'])) {
                $mainStatus = $this->mapStatusToMobile($statusOp);
            }
        } else {
            $activeCount = $armadas->filter(function($a) {
                return !in_array(strtolower($a->status_operasional), ['perawatan', 'tidak_aktif', 'tidak aktif']);
            })->count();
            if ($activeCount === 0) {
                $mainStatus = 'Tidak Aktif';
            }
        }
        
        $jadwals = \App\Models\Jadwal::whereIn('armada_id', $armadas->pluck('id'))
            ->whereIn('status_jadwal', ['Terjadwal', 'terjadwal', 'dipesan', 'Dipesan', 'dalam_perjalanan', 'Dalam Perjalanan'])
            ->where(function($q) use ($startDate, $endDate) {
                $q->whereBetween('tanggal_mulai', [$startDate->format('Y-m-d'), $endDate->format('Y-m-d')])
                  ->orWhereBetween('tanggal_selesai', [$startDate->format('Y-m-d'), $endDate->format('Y-m-d')])
                  ->orWhere(function($sub) use ($startDate, $endDate) {
                      $sub->where('tanggal_mulai', '<=', $startDate->format('Y-m-d'))
                          ->where('tanggal_selesai', '>=', $endDate->format('Y-m-d'));
                  });
            })
            ->get();
            
        $dates = [];
        $daysInMonth = $startDate->daysInMonth;
        
        for ($i = 1; $i <= $daysInMonth; $i++) {
            $currentDate = Carbon::create($year, $month, $i);
            $dateString = $currentDate->format('Y-m-d');
            
            $bookedUnits = 0;
            $totalUnits = $armadas->count();
            
            foreach ($armadas as $armada) {
                // If the armada itself is under maintenance or inactive generally, it counts as unavailable for that date?
                // The instruction says: "Jika armada Perawatan atau Tidak Aktif secara umum, tampilkan informasi bahwa armada tidak tersedia. Jangan tampilkan titik oranye per tanggal."
                // So if it's inactive globally, does it count as booked? 
                // "Jika status operasional armada adalah Perawatan: Jangan tampilkan titik oranye per tanggal. Tampilkan card informasi..."
                // But for "Semua Unit" truck, maybe one truck is in maintenance, so it's not available.
                $statusOp = strtolower($armada->status_operasional);
                if (in_array($statusOp, ['perawatan', 'tidak_aktif', 'tidak aktif'])) {
                    $bookedUnits++; // Treat as unavailable
                    continue;
                }
                
                $isBooked = false;
                foreach ($jadwals->where('armada_id', $armada->id) as $jadwal) {
                    $jadwalStart = Carbon::parse($jadwal->tanggal_mulai)->startOfDay();
                    $jadwalEnd = $jadwal->tanggal_selesai 
                        ? Carbon::parse($jadwal->tanggal_selesai)->endOfDay() 
                        : $jadwalStart->copy()->endOfDay();
                        
                    if ($currentDate->between($jadwalStart, $jadwalEnd)) {
                        $isBooked = true;
                        break;
                    }
                }
                if ($isBooked) {
                    $bookedUnits++;
                }
            }
            
            $statusTanggal = 'Tersedia';
            if ($totalUnits > 0 && $bookedUnits >= $totalUnits) {
                $statusTanggal = 'Dipesan';
            }
            
            $dates[] = [
                'date' => $dateString,
                'status' => $statusTanggal,
                'booked_units' => $bookedUnits,
                'available_units' => $totalUnits - $bookedUnits,
            ];
        }
        
        $unitsResponse = $armadas->map(function($a) {
            return [
                'id' => $a->id,
                'code' => $a->kode_armada,
                'name' => $a->nama_armada,
                'status_operasional' => $this->mapStatusToMobile($a->status_operasional)
            ];
        })->values();
        
        return response()->json([
            'armada_id' => $isAllTrucks ? 'truck-all' : $id,
            'month' => (int)$month,
            'year' => (int)$year,
            'status_operasional' => $mainStatus,
            'dates' => $dates,
            'units' => $unitsResponse
        ]);
    }

    /**
     * Agregasi status truk, bus, dan elf untuk halaman mobile.
     */
    public function summary()
    {
        $allArmadas = Armada::all();

        $summary = [
            'bus' => $this->calculateSummary($allArmadas->where('jenis_armada', 'Bus Medium')),
            'elf' => $this->calculateSummary($allArmadas->where('jenis_armada', 'Elf Long')),
            'truck' => $this->calculateSummary($allArmadas->filter(function ($armada) {
                return stripos($armada->jenis_armada, 'truk') !== false || stripos($armada->jenis_armada, 'truck') !== false;
            })),
        ];

        return response()->json([
            'message' => 'Ringkasan armada berhasil diambil',
            'data' => $summary,
        ]);
    }

    /**
     * Hitung agregasi summary berdasarkan collection armada.
     */
    private function calculateSummary($armadas)
    {
        $total = $armadas->count();
        $available = 0;
        $booked = 0;
        $maintenance = 0;
        $inactive = 0;

        foreach ($armadas as $armada) {
            $status = strtolower($armada->display_status); // Menggunakan accessor display_status
            if ($status === 'tersedia') $available++;
            elseif ($status === 'dipesan' || $status === 'dalam_perjalanan' || $status === 'terjadwal') $booked++;
            elseif ($status === 'perawatan') $maintenance++;
            elseif ($status === 'tidak_aktif' || $status === 'tidak aktif') $inactive++;
        }

        $minCapacity = null;
        $maxCapacity = null;
        $capacityUnit = null;
        
        $validCapacities = $armadas->filter(function($armada) {
            return !empty($armada->kapasitas) && !empty($armada->satuan_kapasitas);
        });
        
        if ($validCapacities->count() > 0) {
            $minCapacity = $validCapacities->min('kapasitas');
            $maxCapacity = $validCapacities->max('kapasitas');
            // Assuming all units of same type have same capacity unit (e.g., Ton). Take the first one.
            $capacityUnit = $validCapacities->first()->satuan_kapasitas;
        }

        $mainStatus = 'Tidak Aktif';
        if ($total > 0) {
            if ($available > 0) {
                $mainStatus = 'Tersedia';
            } elseif ($booked > 0) {
                $mainStatus = 'Dipesan';
            } elseif ($maintenance == $total) {
                $mainStatus = 'Perawatan';
            }
        }

        return [
            'total_unit' => $total,
            'available_unit' => $available,
            'booked_unit' => $booked,
            'maintenance_unit' => $maintenance,
            'inactive_unit' => $inactive,
            'min_capacity' => $minCapacity,
            'max_capacity' => $maxCapacity,
            'capacity_unit' => $capacityUnit,
            'status' => $mainStatus,
        ];
    }

    /**
     * Get data for specific truck units to display in Spesifikasi Truk section.
     */
    public function truckUnits()
    {
        $armadas = Armada::with('images')
            ->where('jenis_armada', 'like', '%truk%')
            ->orWhere('jenis_armada', 'like', '%truck%')
            ->orderBy('created_at', 'desc')
            ->get();

        $data = $armadas->map(function ($armada) {
            $images = $armada->images->map(function ($img) {
                return [
                    'id' => $img->id,
                    'url' => $img->url,
                    'is_primary' => $img->is_primary,
                ];
            });

            $imageUrl = null;
            if ($images->count() > 0) {
                $primary = $images->firstWhere('is_primary', true) ?? $images->first();
                $imageUrl = $primary['url'];
            }

            return [
                'id' => $armada->id,
                'fleet_code' => $armada->kode_armada,
                'fleet_name' => $armada->nama_armada,
                'fleet_type' => $armada->jenis_armada,
                'vehicle_type' => $armada->jenis_armada, // fallback to jenis_armada since there is no vehicle_type
                'capacity' => $armada->kapasitas . ' ' . $armada->satuan_kapasitas,
                'license_plate' => $armada->plat_nomor,
                'year' => null, // fallback since no year column
                'status' => $this->mapStatusToMobile($armada->display_status),
                'condition' => ucfirst(str_replace('_', ' ', $armada->status_operasional)),
                'price' => (float) ($armada->harga_sewa ?? 0),
                'image_url' => $imageUrl,
                'images' => $images,
            ];
        });

        return response()->json([
            'message' => 'Data spesifikasi truk berhasil diambil',
            'data' => $data,
        ]);
    }

    /**
     * Map status internal backend ke label string yang gampang dibaca mobile.
     */
    private function mapStatusToMobile($internalStatus)
    {
        $internalStatus = strtolower($internalStatus);
        $map = [
            'tersedia' => 'Tersedia',
            'dipesan' => 'Dipesan',
            'dalam_perjalanan' => 'Dalam Perjalanan',
            'terjadwal' => 'Terjadwal',
            'perawatan' => 'Perawatan',
            'tidak_aktif' => 'Tidak Aktif',
            'tidak aktif' => 'Tidak Aktif',
        ];

        return $map[$internalStatus] ?? 'Tersedia';
    }
}
