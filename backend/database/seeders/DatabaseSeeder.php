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
                'password' => Hash::make('password123'),
                'role' => 'admin',
            ]
        );

        $this->call([
            ArmadaSeeder::class,
        ]);
    }
}
