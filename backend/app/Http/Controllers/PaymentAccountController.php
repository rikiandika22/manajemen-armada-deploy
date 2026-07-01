<?php

namespace App\Http\Controllers;

use App\Models\PaymentAccount;
use Illuminate\Http\Request;

class PaymentAccountController extends Controller
{
    /**
     * Display a listing of the resource for Admin.
     */
    public function index()
    {
        $accounts = PaymentAccount::orderBy('sort_order', 'asc')->orderBy('bank_name', 'asc')->get();
        return response()->json([
            'message' => 'Berhasil mengambil daftar rekening',
            'data' => $accounts
        ]);
    }

    /**
     * Display active accounts for Mobile.
     */
    public function mobileIndex()
    {
        $accounts = PaymentAccount::active()->ordered()->get();
        return response()->json([
            'message' => 'Berhasil mengambil daftar rekening aktif',
            'data' => $accounts
        ]);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'bank_name' => 'required|string|max:255',
            'account_number' => 'required|string|max:50',
            'account_holder_name' => 'required|string|max:255',
            'is_active' => 'boolean',
            'sort_order' => 'numeric',
            'notes' => 'nullable|string'
        ]);

        $account = PaymentAccount::create($validated);

        return response()->json([
            'message' => 'Rekening berhasil ditambahkan',
            'data' => $account
        ], 201);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, $id)
    {
        $account = PaymentAccount::findOrFail($id);

        $validated = $request->validate([
            'bank_name' => 'required|string|max:255',
            'account_number' => 'required|string|max:50',
            'account_holder_name' => 'required|string|max:255',
            'is_active' => 'boolean',
            'sort_order' => 'numeric',
            'notes' => 'nullable|string'
        ]);

        $account->update($validated);

        return response()->json([
            'message' => 'Rekening berhasil diperbarui',
            'data' => $account
        ]);
    }

    /**
     * Toggle the active status.
     */
    public function toggle($id)
    {
        $account = PaymentAccount::findOrFail($id);
        $account->is_active = !$account->is_active;
        $account->save();

        return response()->json([
            'message' => $account->is_active ? 'Rekening diaktifkan' : 'Rekening dinonaktifkan',
            'data' => $account
        ]);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy($id)
    {
        $account = PaymentAccount::findOrFail($id);

        // Periksa apakah rekening ini sudah dipakai di pembayaran
        $isUsed = \App\Models\Payment::where('payment_account_id', $id)->exists();

        if ($isUsed) {
            return response()->json([
                'message' => 'Rekening sudah pernah digunakan pada pembayaran. Nonaktifkan rekening ini sebagai gantinya.'
            ], 422);
        }

        $account->delete();

        return response()->json([
            'message' => 'Rekening berhasil dihapus permanen'
        ]);
    }
}
