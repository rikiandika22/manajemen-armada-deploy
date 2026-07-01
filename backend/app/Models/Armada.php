<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Carbon\Carbon;

class Armada extends Model
{
    use HasFactory;

    protected $table = 'armadas';

    protected $fillable = [
        'kode_armada',
        'nama_armada',
        'plat_nomor',
        'jenis_armada',
        'kapasitas',
        'satuan_kapasitas',
        'status_operasional',
        'harga_sewa',
        'gambar',
        'keterangan',
    ];

    protected $casts = [
        'kapasitas' => 'float',
        'harga_sewa' => 'float',
    ];

    /**
     * Selalu sertakan status_ketersediaan dan display_status pada JSON response.
     */
    protected $appends = ['status_ketersediaan', 'display_status'];

    /**
     * Armada hasMany Jadwal
     */
    public function jadwals(): HasMany
    {
        return $this->hasMany(Jadwal::class, 'armada_id');
    }

    /**
     * Accessor: Status Dinamis Armada berdasarkan jadwal (Real-time display status)
     */
    public function getDisplayStatusAttribute(): string
    {
        $status = strtolower($this->status_operasional);
        if ($status === 'perawatan') return 'Perawatan';
        if ($status === 'tidak_aktif' || $status === 'tidak aktif') return 'Tidak Aktif';

        $now = Carbon::now('Asia/Jakarta');

        $jadwals = Jadwal::where('armada_id', $this->id)
            ->whereIn('status_jadwal', ['Terjadwal', 'terjadwal', 'dalam_perjalanan', 'dipesan'])
            ->where('tanggal_mulai', '<=', $now->format('Y-m-d'))
            ->where('tanggal_selesai', '>=', $now->format('Y-m-d'))
            ->get();

        foreach ($jadwals as $jadwal) {
            $jamMulai = $jadwal->jam_berangkat ?? '00:00:00';
            $jamSelesai = $jadwal->jam_selesai ?? '23:59:59';
            
            try {
                $start = Carbon::parse($jadwal->tanggal_mulai->format('Y-m-d') . ' ' . $jamMulai, 'Asia/Jakarta');
                $end = Carbon::parse($jadwal->tanggal_selesai->format('Y-m-d') . ' ' . $jamSelesai, 'Asia/Jakarta');
                
                if ($now->betweenIncluded($start, $end)) {
                    return 'Terjadwal';
                }
            } catch (\Exception $e) {
                // If parsing fails, skip
            }
        }

        return 'Tersedia';
    }

    /**
     * Armada hasMany ArmadaImage
     */
    public function images(): HasMany
    {
        return $this->hasMany(ArmadaImage::class, 'armada_id')->orderBy('sort_order')->orderBy('id');
    }

    /**
     * Accessor: hitung status ketersediaan berdasarkan status_operasional + jadwal aktif hari ini.
     *
     *  - tersedia         → jika aktif & tidak ada jadwal aktif hari ini
     */
    public function getStatusKetersediaanAttribute(): string
    {
        $status = strtolower($this->status_operasional);
        if ($status === 'perawatan') return 'Perawatan';
        if ($status === 'tidak_aktif' || $status === 'tidak aktif') return 'Tidak Aktif';

        $today = Carbon::today();

        // Cek dalam_perjalanan dulu (prioritas lebih tinggi)
        $dalamPerjalanan = Jadwal::where('armada_id', $this->id)
            ->where('status_jadwal', 'dalam_perjalanan')
            ->where('tanggal_mulai', '<=', $today)
            ->where('tanggal_selesai', '>=', $today)
            ->exists();

        if ($dalamPerjalanan) return 'Dalam Perjalanan';

        // Cek dipesan
        $dipesan = Jadwal::where('armada_id', $this->id)
            ->where('status_jadwal', 'dipesan')
            ->where('tanggal_mulai', '<=', $today)
            ->where('tanggal_selesai', '>=', $today)
            ->exists();

        if ($dipesan) return 'Dipesan';

        return 'Tersedia';
    }

    /**
     * Accessor: mapping status operasional ke format baku
     */
    public function getStatusOperasionalAttribute($value): string
    {
        $val = strtolower($value);
        if ($val === 'aktif' || $val === 'tersedia') return 'Tersedia';
        if ($val === 'perawatan') return 'Perawatan';
        if ($val === 'tidak_aktif' || $val === 'tidak aktif') return 'Tidak Aktif';
        if ($val === 'dipesan') return 'Dipesan';
        return ucfirst($val);
    }
}
