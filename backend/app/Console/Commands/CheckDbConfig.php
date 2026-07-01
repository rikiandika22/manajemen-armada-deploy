<?php

namespace App\Console\Commands;

use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;

#[Signature('app:check-db-config')]
    #[Description('Check the active database configuration and test connection')]
    class CheckDbConfig extends Command
    {
        /**
         * Execute the console command.
         */
        public function handle()
        {
            $this->info('Database Configuration Check');
            $this->line('----------------------------');
            
            $this->line('APP_ENV       : ' . env('APP_ENV'));
            $this->line('DB_CONNECTION : ' . env('DB_CONNECTION'));
            
            $connection = env('DB_CONNECTION', 'mysql');
            $config = config("database.connections.{$connection}");
            
            if ($config) {
                $this->line('DB_HOST       : ' . ($config['host'] ?? env('DB_HOST')));
                $this->line('DB_PORT       : ' . ($config['port'] ?? env('DB_PORT')));
                $this->line('DB_DATABASE   : ' . ($config['database'] ?? env('DB_DATABASE')));
                $this->line('DB_USERNAME   : ' . ($config['username'] ?? env('DB_USERNAME')));
            }
            
            $this->line('----------------------------');
            $this->info('Testing connection...');
            
            try {
                \Illuminate\Support\Facades\DB::connection()->getPdo();
                $this->info('✅ Connection successful!');
            } catch (\Exception $e) {
                $this->error('❌ Connection failed: ' . $e->getMessage());
            }
        }
    }
