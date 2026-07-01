<?php

namespace App\Http\Controllers;

use App\Models\Armada;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class ArmadaController extends Controller
{
    /**
     * Display a listing of the resource.
     * status_ketersediaan otomatis disertakan via model $appends.
     */
    public function index()
    {
        $armadas = Armada::with('images')->orderBy('created_at', 'desc')->get();

        return response()->json([
            'message' => 'Data armada berhasil diambil',
            'data'    => $armadas,
        ]);
    }

    /**
     * Store a newly created resource in storage.
     * kode_armada dibuat otomatis oleh backend.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'nama_armada'        => 'required|string',
            'plat_nomor'         => 'required|string|unique:armadas,plat_nomor',
            'jenis_armada'       => 'required|string|in:Bus Medium,Elf Long,Truk CDD Bak Terbuka',
            'kapasitas'          => 'required|numeric|min:0.1',
            'satuan_kapasitas'   => 'required|string',
            'status_operasional' => 'required|string|in:Tersedia,Perawatan,Tidak Aktif',
            'harga_sewa'         => 'nullable|numeric|min:0',
            'gambar'             => 'nullable|string',
            'keterangan'         => 'nullable|string',
        ], [
            'status_operasional.in' => 'Status operasional tidak valid. Pilih status yang tersedia.'
        ]);

        $validated['kode_armada'] = $this->generateKodeArmada($validated['jenis_armada']);
        
        if (stripos($validated['jenis_armada'], 'truk') !== false || stripos($validated['jenis_armada'], 'truck') !== false) {
            $validated['satuan_kapasitas'] = 'Ton';
        }

        $armada = Armada::create($validated);

        if ($request->hasFile('images')) {
            $cloudinary = app(\App\Services\CloudinaryUploadService::class);
            $sortOrder = 0;
            foreach ($request->file('images') as $index => $file) {
                if ($sortOrder >= 5) break; // Maksimal 5 foto

                $uploadResult = $cloudinary->uploadImage($file, 'sumber-agung/armada');
                
                if ($uploadResult) {
                    $armada->images()->create([
                        'image_path' => $uploadResult['secure_url'],
                        'cloudinary_public_id' => $uploadResult['public_id'],
                        'is_primary' => $sortOrder === 0, // Gambar pertama otomatis jadi primary
                        'sort_order' => $sortOrder
                    ]);
                    $sortOrder++;
                } else {
                    // Fallback to local storage if Cloudinary fails
                    $path = $file->store('armada', 'public');
                    $armada->images()->create([
                        'image_path' => $path,
                        'is_primary' => $sortOrder === 0,
                        'sort_order' => $sortOrder
                    ]);
                    $sortOrder++;
                }
            }
        }
        
        $armada->load('images');

        return response()->json([
            'message' => 'Data armada berhasil disimpan',
            'data'    => $armada,
        ], 201);
    }

    /**
     * Display the specified resource.
     */
    public function show(Armada $armada)
    {
        $armada->load('images');
        return response()->json([
            'message' => 'Data armada berhasil diambil',
            'data'    => $armada,
        ]);
    }

    /**
     * Update the specified resource in storage.
     * kode_armada tidak pernah diupdate.
     */
    public function update(Request $request, Armada $armada)
    {
        $validated = $request->validate([
            'nama_armada'        => 'required|string',
            'plat_nomor'         => ['required', 'string', Rule::unique('armadas', 'plat_nomor')->ignore($armada->id)],
            'jenis_armada'       => 'required|string|in:Bus Medium,Elf Long,Truk CDD Bak Terbuka',
            'kapasitas'          => 'required|numeric|min:0.1',
            'satuan_kapasitas'   => 'required|string',
            'status_operasional' => 'required|string|in:Tersedia,Perawatan,Tidak Aktif',
            'harga_sewa'         => 'nullable|numeric|min:0',
            'gambar'             => 'nullable|string',
            'keterangan'         => 'nullable|string',
        ], [
            'status_operasional.in' => 'Status operasional tidak valid. Pilih status yang tersedia.'
        ]);

        unset($validated['kode_armada']);

        if (stripos($validated['jenis_armada'], 'truk') !== false || stripos($validated['jenis_armada'], 'truck') !== false) {
            $validated['satuan_kapasitas'] = 'Ton';
        }

        $armada->update($validated);

        return response()->json([
            'message' => 'Data armada berhasil diperbarui',
            'data'    => $armada->fresh(),
        ]);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Armada $armada)
    {
        $cloudinary = app(\App\Services\CloudinaryUploadService::class);
        foreach ($armada->images as $image) {
            if ($image->cloudinary_public_id) {
                $cloudinary->deleteByPublicId($image->cloudinary_public_id);
            }
            if (\Illuminate\Support\Facades\Storage::disk('public')->exists($image->image_path)) {
                \Illuminate\Support\Facades\Storage::disk('public')->delete($image->image_path);
            }
        }
        $armada->delete();

        return response()->json([
            'message' => 'Data armada berhasil dihapus',
        ]);
    }

    /**
     * Generate kode armada otomatis.
     */
    private function generateKodeArmada(string $jenisArmada): string
    {
        $prefixMap = [
            'Bus Medium'           => 'BUS',
            'Elf Long'             => 'ELF',
            'Truk CDD Bak Terbuka' => 'TRK',
        ];

        $prefix = $prefixMap[$jenisArmada] ?? 'ARM';

        $last = Armada::where('kode_armada', 'like', $prefix . '%')
            ->orderBy('kode_armada', 'desc')
            ->first();

        if ($last) {
            $lastNumber = (int) substr($last->kode_armada, strlen($prefix));
            $nextNumber = $lastNumber + 1;
        } else {
            $nextNumber = 1;
        }

        return $prefix . str_pad($nextNumber, 3, '0', STR_PAD_LEFT);
    }
}
