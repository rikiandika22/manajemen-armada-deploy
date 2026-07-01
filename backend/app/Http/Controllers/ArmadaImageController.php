<?php

namespace App\Http\Controllers;

use App\Models\Armada;
use App\Models\ArmadaImage;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class ArmadaImageController extends Controller
{
    public function store(Request $request, Armada $armada)
    {
        $request->validate([
            'image' => 'required|image|mimes:jpeg,png,jpg,webp|max:2048'
        ]);

        if ($armada->images()->count() >= 5) {
            return response()->json([
                'message' => 'Maksimal 5 foto per armada'
            ], 422);
        }

        $path = $request->file('image')->store('armada', 'public');
        
        $isFirst = $armada->images()->count() === 0;

        $image = $armada->images()->create([
            'image_path' => $path,
            'is_primary' => $isFirst,
            'sort_order' => $armada->images()->count()
        ]);

        return response()->json([
            'message' => 'Foto berhasil diunggah',
            'data' => $image
        ]);
    }

    public function destroy(ArmadaImage $image)
    {
        if (Storage::disk('public')->exists($image->image_path)) {
            Storage::disk('public')->delete($image->image_path);
        }
        
        $armada = $image->armada;
        $image->delete();

        // if the deleted image was primary and there are other images, set the first one as primary
        if ($image->is_primary && $armada->images()->count() > 0) {
            $firstImage = $armada->images()->first();
            $firstImage->update(['is_primary' => true]);
        }

        return response()->json([
            'message' => 'Foto berhasil dihapus'
        ]);
    }

    public function setPrimary(ArmadaImage $image)
    {
        $armada = $image->armada;
        
        $armada->images()->update(['is_primary' => false]);
        $image->update(['is_primary' => true]);

        return response()->json([
            'message' => 'Foto utama berhasil diubah',
            'data' => $image
        ]);
    }
}
