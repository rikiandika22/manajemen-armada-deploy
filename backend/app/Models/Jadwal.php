<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Jadwal extends Model
{
    use HasFactory;

    protected $table = 'jadwals';

    protected $fillable = [
        'armada_id',
        'order_id',
        'user_id',
        'kode_pesanan',
        'tanggal_mulai',
        'tanggal_selesai',
        'jam_berangkat',
        'jam_selesai',
        'lokasi_asal',
        'lokasi_tujuan',
        'detail_lokasi',
        'nama_pelanggan',
        'nomor_telepon',
        'keperluan',
        'status_jadwal',
        'jenis_jadwal',
        'keterangan',
    ];

    protected $casts = [
        'tanggal_mulai'   => 'date',
        'tanggal_selesai' => 'date',
    ];

    /**
     * Jadwal belongsTo Armada
     */
    public function armada(): BelongsTo
    {
        return $this->belongsTo(Armada::class, 'armada_id');
    }

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class, 'order_id');
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}
