<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // User::factory(10)->create();

        User::updateOrCreate(
            ['email' => 'admin@sumberagungtrans.test'],
            [
                'name' => 'Admin Sumber Agung',
                'username' => 'admin',
                'role' => 'admin',
                'email_verified_at' => now(),
                'password' => \Illuminate\Support\Facades\Hash::make('password123'),
            ]
        );

        $this->command?->info('Admin user seeded or updated successfully.');

        $this->call([
            ArmadaSeeder::class,
        ]);
    }
}
