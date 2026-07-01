# Deployment Railway (Backend)

Dokumentasi ini menjelaskan cara men-deploy dan mengatur environment variables untuk backend Laravel di Railway.

## Environment Variables di Railway

Untuk Railway backend service, gunakan ENV berikut (konfigurasi di dashboard Railway bagian Variables):

```env
APP_ENV=production
APP_DEBUG=false
APP_KEY=base64:... (isikan dengan output php artisan key:generate)
APP_URL=https://domain-backend.up.railway.app (sesuaikan dengan domain dari Railway)

DB_CONNECTION=mysql
DB_HOST=${{MySQL.MYSQLHOST}}
DB_PORT=${{MySQL.MYSQLPORT}}
DB_DATABASE=${{MySQL.MYSQLDATABASE}}
DB_USERNAME=${{MySQL.MYSQLUSER}}
DB_PASSWORD=${{MySQL.MYSQLPASSWORD}}
```

**Penting:**
- `DB_HOST` dengan nilai `mysql.railway.internal` (yang dihasilkan secara default oleh Railway internal host) hanya boleh dipakai **di dalam service Railway**.
- Jangan pernah memasukkan `mysql.railway.internal` ke dalam `.env` di laptop lokal Anda, karena jaringan internal Railway tidak bisa diakses langsung dari luar.

## Command Database & Seeder

### 1. Local Development
Pastikan `.env` lokal Anda menggunakan koneksi database lokal (misal: MySQL dari XAMPP, Herd, atau Docker).
Contoh:
```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=database_lokal
DB_USERNAME=root
DB_PASSWORD=
```
Kemudian jalankan:
```bash
php artisan migrate
php artisan db:seed
```
*Jangan menjalankan command ini jika `.env` lokal masih mengarah ke database Railway.*

### 2. Railway Production
Untuk melakukan migrate dan seed di database Railway, pastikan Anda menjalankannya di **environment Railway** (misalnya melalui Railway CLI atau tab "Execute Command" di dashboard Railway).
Gunakan perintah dengan flag `--force`:
```bash
php artisan migrate --force
php artisan db:seed --force
```

**Catatan Penting Seeder di Railway:**
- Jika memakai Railway, seed harus dijalankan di environment Railway atau dengan variable database production yang benar.
- Jangan menganggap file seeder di GitHub otomatis mengisi database. Seeder hanya berjalan jika command `db:seed` dieksekusi secara manual.
- Login admin default:
  - email: `admin@sumberagungtrans.test`
  - username: `admin`
  - password: `password123`
- Setelah login berhasil, pastikan untuk **menghapus endpoint `debug-admin-check` dan `debug-admin-password-check`** di `routes/api.php` demi keamanan.

Jika Anda ingin mengakses database Railway dari laptop lokal (misalnya menggunakan TablePlus atau command artisan lokal), gunakan koneksi **TCP Proxy (Public Database URL)** dari Railway, bukan host internal.

## Pengecekan Koneksi Database

Jika ada error terkait `nodename nor servname provided` saat seeder, pastikan Anda tidak menjalankan seeder dari laptop dengan koneksi mengarah ke `.internal`.

---

## 3. Cloudinary Setup (Penyimpanan Media)
Saat ini sistem backend telah dimigrasi untuk menggunakan **Cloudinary** sebagai media penyimpanan utama untuk gambar armada dan bukti pembayaran, tidak lagi menggunakan storage lokal server.

### Cara Pengaturan:
1. Buat akun di [Cloudinary](https://cloudinary.com/).
2. Ambil **Cloudinary Environment Variable (`CLOUDINARY_URL`)** dari halaman Dashboard Console Anda.
3. Tambahkan Variabel tersebut ke Railway pada service backend (di bagian Variables):
   - **`CLOUDINARY_URL`** = `cloudinary://API_KEY:API_SECRET@CLOUD_NAME`
4. **Catatan:** Jangan pernah meng-commit kredensial/API Key Cloudinary ke GitHub. Semua konfigurasi hanya diatur via Railway Variables.
5. Setelah menambahkan variable tersebut, lakukan **redeploy** pada service backend di Railway.

### Pengujian Cloudinary:
Setelah redeploy selesai, pastikan koneksi berjalan dengan baik:
- Coba **upload gambar armada** dari Web Admin Vercel.
- Coba **upload bukti pembayaran** dari Mobile App (Flutter).
- Pastikan gambar berhasil tersimpan dan Anda dapat melihat file baru masuk di Cloudinary Media Library pada folder `sumber-agung/armada` atau `sumber-agung/payment-proofs`.
- Gambar lama yang diupload sebelumnya (local storage) tetap akan tampil sebagai fallback dengan sistem yang baru.

Jika Anda ingin melihat konfigurasi database yang sedang aktif (tanpa menampilkan password) untuk memastikan tidak salah koneksi, Anda bisa menggunakan command custom (jika tersedia):
```bash
php artisan app:check-db-config
```
Atau menggunakan tinker:
```bash
php artisan tinker
> echo env('APP_ENV');
> echo config('database.connections.mysql.host');
> DB::connection()->getPdo(); // Akan error jika koneksi gagal
```
