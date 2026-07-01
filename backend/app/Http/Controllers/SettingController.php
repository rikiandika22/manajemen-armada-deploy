<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\BusinessSetting;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class SettingController extends Controller
{
    public function updateProfile(Request $request)
    {
        $user = Auth::user();

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users,email,' . $user->id,
        ]);

        $user->name = $validated['name'];
        $user->email = $validated['email'];
        $user->save();

        return response()->json([
            'message' => 'Profil berhasil diperbarui',
            'user' => $user
        ]);
    }

    public function getBusinessSetting()
    {
        // Get the first record, or create a default one if it doesn't exist
        $setting = BusinessSetting::first();
        if (!$setting) {
            $setting = BusinessSetting::create([
                'business_name' => 'Sumber Agung Trans',
                'business_phone' => '0812-3456-7890',
                'business_address' => 'Jl. Raya Grobogan No. 45, Purwodadi, Grobogan, Jawa Tengah',
            ]);
        }

        return response()->json($setting);
    }

    public function updateBusinessSetting(Request $request)
    {
        $validated = $request->validate([
            'business_name' => 'required|string|max:255',
            'business_phone' => 'required|string|max:50',
            'business_address' => 'required|string',
        ]);

        $setting = BusinessSetting::first();
        if (!$setting) {
            $setting = new BusinessSetting();
        }

        $setting->fill($validated);
        $setting->save();

        return response()->json([
            'message' => 'Informasi usaha berhasil diperbarui',
            'setting' => $setting
        ]);
    }

    public function changePassword(Request $request)
    {
        $validated = $request->validate([
            'old_password' => 'required|string',
            'new_password' => 'required|string|min:8|confirmed',
        ]);

        $user = Auth::user();

        if (!Hash::check($validated['old_password'], $user->password)) {
            throw ValidationException::withMessages([
                'old_password' => ['Password lama tidak sesuai'],
            ]);
        }

        $user->password = Hash::make($validated['new_password']);
        $user->save();

        return response()->json([
            'message' => 'Password berhasil diperbarui'
        ]);
    }
}
