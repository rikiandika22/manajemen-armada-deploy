<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Order extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'order_code',
        'service_type',
        'fleet_name',
        'fleet_type',
        'origin',
        'destination',
        'departure_date',
        'departure_time',
        'estimated_finish',
        'total_price',
        'payment_status',
        'order_status',
        'notes',
        'assigned_fleet_id',
        'truck_service_type',
        'canceled_at',
        'cancel_reason',
        'dp_amount',
        'remaining_payment',
        'price_note',
        'price_status',
        'price_sent_at',
        'origin_lat',
        'origin_lng',
        'destination_lat',
        'destination_lng',
        'truck_load_type',
        'truck_load_description',
        'truck_load_weight',
        'truck_load_weight_unit',
        'truck_load_quantity',
        'truck_load_quantity_unit',
        'truck_access_note',
        'truck_additional_note',
        'user_archived_at',
    ];

    protected $casts = [
        'departure_date' => 'date',
        'estimated_finish' => 'datetime',
        'total_price' => 'decimal:2',
        'dp_amount' => 'decimal:2',
        'remaining_payment' => 'decimal:2',
        'canceled_at' => 'datetime',
        'price_sent_at' => 'datetime',
        'user_archived_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function assignedFleet(): BelongsTo
    {
        return $this->belongsTo(Armada::class, 'assigned_fleet_id');
    }

    public function payment()
    {
        return $this->hasOne(Payment::class);
    }

    public function payments()
    {
        return $this->hasMany(Payment::class);
    }
}
