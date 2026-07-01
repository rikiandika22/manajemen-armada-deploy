<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class AuthController extends Controller
{
    public function login(Request $request)
    {
        $identifier = $request->input('email') ?? $request->input('username') ?? $request->input('login');
        $password = $request->input('password');

        if (!$identifier || !$password) {
            return response()->json([
                'message' => 'Email/Username dan Password harus diisi'
            ], 400);
        }

        $user = \App\Models\User::where('email', $identifier)
            ->orWhere('username', $identifier)
            ->first();

        if (!$user || !\Illuminate\Support\Facades\Hash::check($password, $user->password)) {
            return response()->json([
                'message' => 'Email/Username atau Password salah'
            ], 401);
        }

        if ($user->role !== 'admin') {
            return response()->json([
                'message' => 'Akun tidak memiliki akses admin'
            ], 403);
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'Login berhasil',
            'token' => $token,
            'user' => $user
        ]);
    }

    public function me(Request $request)
    {
        return response()->json($request->user());
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'message' => 'Logout berhasil'
        ]);
    }
}
