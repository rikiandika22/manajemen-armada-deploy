<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Sopir extends Model
{
    use HasFactory;

    protected $table = 'sopirs';

    protected $fillable = [
        'kode_sopir',
        'nama',
        'telepon',
        'alamat',
        'status',
        'foto',
        'keterangan',
    ];

    /**
     * Accessor: URL foto profil lengkap.
     * Ditambahkan otomatis ke JSON response via $appends.
     */
    protected $appends = ['foto_url'];

    public function getFotoUrlAttribute(): ?string
    {
        if (!$this->foto) return null;

        // Jika sudah URL lengkap, kembalikan apa adanya
        if (str_starts_with($this->foto, 'http')) return $this->foto;

        return asset('storage/' . $this->foto);
    }
}
