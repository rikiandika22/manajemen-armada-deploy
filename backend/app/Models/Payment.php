<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Payment extends Model
{
    protected $fillable = [
        'order_id',
        'payment_type',
        'user_id',
        'bank_name',
        'bank_account_number',
        'bank_account_name',
        'amount',
        'payment_proof_path',
        'payment_status',
        'verified_by',
        'verified_at',
        'rejected_reason',
    ];

    protected $appends = ['payment_proof_url'];

    public function getPaymentProofUrlAttribute()
    {
        return asset('storage/' . $this->payment_proof_path);
    }

    public function order()
    {
        return $this->belongsTo(Order::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
