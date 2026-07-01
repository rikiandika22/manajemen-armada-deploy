<?php

namespace App\Http\Controllers;

use App\Models\Sopir;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class SopirController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        $sopirs = Sopir::orderBy('created_at', 'desc')->get();

        return response()->json([
            'message' => 'Data sopir berhasil diambil',
            'data'    => $sopirs,
        ]);
    }

    /**
     * Store a newly created resource in storage.
     * Menerima multipart/form-data karena ada upload foto.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'nama'       => 'required|string|max:255',
            'telepon'    => 'required|string|max:20',
            'alamat'     => 'nullable|string',
            'status'     => 'required|string|in:aktif,tidak_aktif',
            'foto'       => 'nullable|image|mimes:jpg,jpeg,png,webp|max:2048',
            'keterangan' => 'nullable|string',
        ]);

        // Generate kode sopir otomatis
        $validated['kode_sopir'] = $this->generateKodeSopir();

        // Handle upload foto
        if ($request->hasFile('foto')) {
            $validated['foto'] = $request->file('foto')->store('sopir', 'public');
        }

        $sopir = Sopir::create($validated);

        return response()->json([
            'message' => 'Data sopir berhasil disimpan',
            'data'    => $sopir,
        ], 201);
    }

    /**
     * Display the specified resource.
     */
    public function show(Sopir $sopir)
    {
        return response()->json([
            'message' => 'Data sopir berhasil diambil',
            'data'    => $sopir,
        ]);
    }

    /**
     * Update the specified resource in storage.
     * Menggunakan POST + _method=PUT karena multipart/form-data.
     */
    public function update(Request $request, Sopir $sopir)
    {
        $validated = $request->validate([
            'nama'       => 'required|string|max:255',
            'telepon'    => 'required|string|max:20',
            'alamat'     => 'nullable|string',
            'status'     => 'required|string|in:aktif,tidak_aktif',
            'foto'       => 'nullable|image|mimes:jpg,jpeg,png,webp|max:2048',
            'keterangan' => 'nullable|string',
        ]);

        // kode_sopir tidak boleh diubah
        unset($validated['kode_sopir']);

        // Handle upload foto baru — hapus foto lama jika ada
        if ($request->hasFile('foto')) {
            if ($sopir->foto && Storage::disk('public')->exists($sopir->foto)) {
                Storage::disk('public')->delete($sopir->foto);
            }
            $validated['foto'] = $request->file('foto')->store('sopir', 'public');
        }

        $sopir->update($validated);

        return response()->json([
            'message' => 'Data sopir berhasil diperbarui',
            'data'    => $sopir->fresh(),
        ]);
    }

    /**
     * Remove the specified resource from storage.
     * Hapus foto dari storage jika ada.
     */
    public function destroy(Sopir $sopir)
    {
        if ($sopir->foto && Storage::disk('public')->exists($sopir->foto)) {
            Storage::disk('public')->delete($sopir->foto);
        }

        $sopir->delete();

        return response()->json([
            'message' => 'Data sopir berhasil dihapus',
        ]);
    }

    /**
     * Generate kode sopir otomatis: SPR001, SPR002, ...
     */
    private function generateKodeSopir(): string
    {
        $prefix = 'SPR';

        $last = Sopir::where('kode_sopir', 'like', $prefix . '%')
            ->orderBy('kode_sopir', 'desc')
            ->first();

        if ($last) {
            $lastNumber = (int) substr($last->kode_sopir, strlen($prefix));
            $nextNumber = $lastNumber + 1;
        } else {
            $nextNumber = 1;
        }

        return $prefix . str_pad($nextNumber, 3, '0', STR_PAD_LEFT);
    }
}
