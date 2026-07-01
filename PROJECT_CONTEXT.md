# PROJECT_CONTEXT

## 1. Identitas Project

Nama sistem adalah Sistem Informasi Reservasi dan Penjadwalan Armada Sumber Agung Trans.

Project ini digunakan untuk membantu pengelolaan armada, jadwal, pemesanan, pembayaran, data sopir, laporan, dan pengaturan sistem pada Sumber Agung Trans.

Sumber Agung Trans adalah usaha transportasi keluarga di Grobogan yang melayani penyewaan armada penumpang dan angkutan logistik.

Armada yang dikelola terdiri dari satu Bus Medium, satu Elf Long, dan empat Truk CDD Bak Terbuka.

## 2. Struktur Project

Frontend React Vite berada langsung di root project.

Backend Laravel berada di folder backend.

Jangan membuat folder frontend baru.

Jangan memindahkan file frontend dari root project.

Jangan mengubah struktur besar project tanpa instruksi khusus.

Jika perlu mengubah frontend, ubah file yang sudah ada di root project seperti src, package.json, vite.config.js, index.html, dan file terkait lainnya.

Jika perlu mengubah backend, ubah file yang berada di folder backend.

## 3. Teknologi Yang Digunakan

Frontend website admin menggunakan React, Vite, dan Tailwind CSS.

Backend menggunakan Laravel sebagai REST API.

Autentikasi menggunakan Laravel Sanctum.

Database menggunakan MySQL.

Request dari frontend ke backend menggunakan service API yang berada di src/services/api.js.

Jangan membuat service API baru jika src/services/api.js sudah tersedia dan berfungsi.

## 4. Arsitektur Sistem

Website admin React berkomunikasi dengan backend Laravel melalui REST API.

Backend Laravel mengelola validasi data, autentikasi, logika bisnis, dan koneksi ke database MySQL.

Database MySQL menyimpan data user admin, armada, jadwal, sopir, pembayaran, pemesanan, dan data operasional lainnya.

Frontend tidak boleh langsung mengakses database.

Semua operasi data harus melalui API Laravel.

## 5. Role Pengguna

Sistem memiliki dua role utama.

Pertama, admin atau pengelola.

Admin menggunakan website untuk mengelola data operasional.

Kedua, pelanggan.

Pelanggan menggunakan aplikasi mobile untuk melihat informasi armada dan mengecek jadwal.

Sopir bukan role login.

Sopir hanya data operasional yang dikelola oleh admin.

Jangan membuat fitur login sopir.

Jangan membuat dashboard sopir.

Jangan membuat fitur sopir melaporkan kendala.

## 6. Batasan Fitur

Fokus utama sistem adalah pengelolaan data armada, jadwal armada, pemesanan, pembayaran, data sopir, laporan operasional, dan pengaturan.

Jangan membuat fitur optimasi rute cerdas.

Jangan membuat fitur GPS tracking.

Jangan membuat fitur pelacakan posisi armada waktu nyata.

Jika ada fitur peta, posisikan sebagai visualisasi rute berdasarkan jadwal, bukan tracking GPS.

Jangan membuat fitur di luar scope tanpa instruksi khusus.

## 7. Gaya Desain Frontend

Gunakan desain dashboard modern yang sudah ada.

Pertahankan sidebar gelap.

Pertahankan aksen hijau lime.

Pertahankan background abu muda.

Pertahankan card putih dengan rounded corner besar.

Pertahankan shadow halus.

Pertahankan tabel yang bersih dan mudah dibaca.

Pertahankan style topbar, sidebar, badge, button, modal, dan form yang sudah konsisten.

Jangan merusak desain dashboard, login page, halaman Armada, halaman Jadwal, halaman Sopir, atau halaman lain yang sudah dibuat.

Jika membuat modal baru, ikuti style modal Tambah Sopir yang sudah ada.

## 8. Aturan API Frontend

Gunakan src/services/api.js untuk semua request API.

Jangan hardcode URL backend langsung di komponen halaman.

Base URL API harus berasal dari environment variable VITE_API_BASE_URL.

Token login harus tetap dikirim melalui konfigurasi API yang sudah ada.

Jika request memakai upload file, gunakan FormData.

Jangan set Content Type manual ketika memakai FormData.

Untuk update file di Laravel, gunakan POST dengan field _method bernilai PUT jika PUT multipart bermasalah.

## 9. Aturan Data Armada

Data armada disimpan di tabel armadas.

Kode armada dibuat otomatis oleh backend.

Kode armada tidak boleh diinput manual oleh admin.

Kode armada harus unique.

Kode armada tidak boleh berubah saat data diedit.

Format kode armada adalah BUS001 untuk Bus Medium, ELF001 untuk Elf Long, dan TRK001 untuk Truk CDD Bak Terbuka.

Page Armada hanya menyimpan kondisi dasar kendaraan melalui status_operasional.

Nilai status_operasional adalah aktif, perawatan, dan tidak_aktif.

Status dipesan dan dalam_perjalanan tidak boleh diinput manual dari page Armada.

Status dipesan dan dalam_perjalanan harus berasal dari data Jadwal.

## 10. Aturan Data Jadwal

Data jadwal disimpan di tabel jadwals.

Jadwal harus berelasi dengan armada melalui armada_id.

Status jadwal disimpan di field status_jadwal.

Nilai status_jadwal adalah dipesan, dalam_perjalanan, selesai, dan dibatalkan.

Status ketersediaan armada dihitung dari kombinasi status_operasional armada dan status_jadwal.

Jika status_operasional perawatan, maka status ketersediaan adalah perawatan.

Jika status_operasional tidak_aktif, maka status ketersediaan adalah tidak_aktif.

Jika armada aktif dan memiliki jadwal dipesan pada tanggal aktif, maka status ketersediaan adalah dipesan.

Jika armada aktif dan memiliki jadwal dalam_perjalanan pada tanggal aktif, maka status ketersediaan adalah dalam_perjalanan.

Jika armada aktif dan tidak memiliki jadwal aktif, maka status ketersediaan adalah tersedia.

Jangan izinkan jadwal bentrok untuk armada yang sama pada rentang tanggal yang sama.

## 11. Aturan Data Sopir

Data sopir disimpan di tabel sopirs.

Kode sopir dibuat otomatis oleh backend.

Format kode sopir adalah SPR001, SPR002, dan seterusnya.

Kode sopir tidak boleh diinput manual oleh admin.

Sopir boleh memiliki foto profil.

Upload foto profil hanya menerima JPG, JPEG, PNG, dan WEBP.

Ukuran foto profil maksimal 2 MB.

Setelah foto dipilih di frontend, tampilkan preview foto di dalam modal sebelum disimpan.

Jika data sopir diedit dan foto baru diupload, hapus foto lama dari storage jika ada.

Jika data sopir dihapus, hapus foto profil dari storage jika ada.

## 12. Aturan Form Dan Modal

Semua input harus menjadi controlled component.

Nilai default form harus jelas.

Saat modal tambah dibuka, form harus kosong.

Saat modal edit dibuka, form harus terisi data yang dipilih.

Saat modal ditutup, form harus reset.

Error validasi harus hilang ketika modal ditutup.

Error validasi harus hilang setelah input diperbaiki.

Submit button harus disabled ketika proses submit berjalan.

Jangan sampai data lama tertinggal ketika membuka modal tambah setelah edit.

## 13. Animasi UI

Tambahkan animasi ringan agar halaman tidak terlihat statis.

Gunakan Framer Motion jika sudah tersedia.

Jika tidak tersedia, boleh memakai CSS atau Tailwind transition.

Animasi yang disarankan adalah fade in, slide up, scale modal, fade overlay, hover transition pada button, dan animasi halus pada baris tabel.

Jangan membuat animasi terlalu ramai.

## 14. Deploy

Frontend React Vite dideploy ke Vercel dari root project.

Build command frontend adalah npm run build.

Output directory frontend adalah dist.

Backend Laravel dideploy ke Railway dari folder backend.

Root Directory backend di Railway adalah backend.

Database menggunakan MySQL Railway.

Frontend Vercel harus memakai environment variable VITE_API_BASE_URL yang mengarah ke domain backend Laravel dengan akhiran api.

Jangan arahkan frontend ke domain MySQL.

Jangan arahkan frontend ke 127.0.0.1 untuk production.

## 15. Catatan Keamanan

Jangan memasukkan file .env ke GitHub.

Jangan memasukkan APP_KEY asli ke repository.

Jangan memasukkan password database ke repository.

Jangan menampilkan kredensial database pada file frontend.

Jangan menyimpan kredensial database di Vercel frontend.

Kredensial database hanya boleh berada di environment backend.

## 16. Instruksi Untuk Model Koding

Sebelum mengubah kode, baca file ini terlebih dahulu.

Ikuti struktur project yang sudah ada.

Jangan membuat ulang project dari awal.

Jangan membuat folder frontend baru.

Jangan memindahkan frontend ke folder lain.

Jangan mengubah desain besar tanpa instruksi khusus.

Kerjakan hanya task yang diminta.

Setelah selesai, berikan ringkasan file yang dibuat atau diubah, endpoint yang terdampak, cara menjalankan migration jika ada, dan cara mengetes fitur.
