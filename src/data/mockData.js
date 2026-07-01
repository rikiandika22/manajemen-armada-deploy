// ==========================================
// MOCK DATA - Sumber Agung Trans
// ==========================================

export const mockArmada = [
  { id: 'ARM-001', plat: 'H 1234 AA', jenis: 'Bus Medium', kapasitas: '30 Penumpang', status: 'Tersedia', keterangan: 'Kondisi baik, siap beroperasi' },
  { id: 'ARM-002', plat: 'H 5678 BB', jenis: 'Elf Long', kapasitas: '16 Penumpang', status: 'Dalam Perjalanan', keterangan: 'Rute Grobogan - Semarang' },
  { id: 'ARM-003', plat: 'H 9012 CC', jenis: 'Truk CDD Bak Terbuka', kapasitas: '5 Ton', status: 'Tersedia', keterangan: 'Siap untuk pengiriman logistik' },
  { id: 'ARM-004', plat: 'H 3456 DD', jenis: 'Truk CDD Bak Terbuka', kapasitas: '5 Ton', status: 'Perawatan', keterangan: 'Servis rutin di bengkel' },
  { id: 'ARM-005', plat: 'H 7890 EE', jenis: 'Truk CDD Bak Terbuka', kapasitas: '5 Ton', status: 'Dalam Perjalanan', keterangan: 'Pengiriman pasir area Grobogan' },
  { id: 'ARM-006', plat: 'H 2345 FF', jenis: 'Truk CDD Bak Terbuka', kapasitas: '5 Ton', status: 'Tersedia', keterangan: 'Siap beroperasi' },
];

export const mockJadwal = [
  { id: 'JDW-001', tanggal: '2026-05-20', jenis: 'Bus Medium', plat: 'H 1234 AA', rute: 'Grobogan → Semarang', sopir: 'Budi Santoso', status: 'Tersedia' },
  { id: 'JDW-002', tanggal: '2026-05-20', jenis: 'Elf Long', plat: 'H 5678 BB', rute: 'Grobogan → Yogyakarta', sopir: 'Agus Prasetyo', status: 'Dipesan' },
  { id: 'JDW-003', tanggal: '2026-05-21', jenis: 'Bus Medium', plat: 'H 1234 AA', rute: 'Grobogan → Solo', sopir: 'Budi Santoso', status: 'Tersedia' },
  { id: 'JDW-004', tanggal: '2026-05-21', jenis: 'Truk CDD Bak Terbuka', plat: 'H 9012 CC', rute: 'Pengiriman Pasir - Area Grobogan', sopir: 'Slamet Riyadi', status: 'Dalam Perjalanan' },
  { id: 'JDW-005', tanggal: '2026-05-22', jenis: 'Truk CDD Bak Terbuka', plat: 'H 7890 EE', rute: 'Pengiriman Palawija - Area Purwodadi', sopir: 'Heru Wibowo', status: 'Selesai' },
  { id: 'JDW-006', tanggal: '2026-05-22', jenis: 'Elf Long', plat: 'H 5678 BB', rute: 'Grobogan → Semarang', sopir: 'Agus Prasetyo', status: 'Tersedia' },
  { id: 'JDW-007', tanggal: '2026-05-23', jenis: 'Bus Medium', plat: 'H 1234 AA', rute: 'Grobogan → Yogyakarta', sopir: 'Budi Santoso', status: 'Dipesan' },
  { id: 'JDW-008', tanggal: '2026-05-23', jenis: 'Truk CDD Bak Terbuka', plat: 'H 3456 DD', rute: 'Pengiriman Material - Area Demak', sopir: 'Slamet Riyadi', status: 'Selesai' },
];

export const mockPemesanan = [
  { id: 'PMS-001', nama: 'Rizky Pratama', telepon: '081234567890', tanggal: '2026-05-20', jenis: 'Bus Medium', tujuan: 'Grobogan → Semarang', status: 'Diterima' },
  { id: 'PMS-002', nama: 'Dewi Rahayu', telepon: '082345678901', tanggal: '2026-05-21', jenis: 'Elf Long', tujuan: 'Grobogan → Yogyakarta', status: 'Menunggu Konfirmasi' },
  { id: 'PMS-003', nama: 'Ahmad Fauzi', telepon: '083456789012', tanggal: '2026-05-22', jenis: 'Truk CDD Bak Terbuka', tujuan: 'Pengiriman Pasir - Grobogan', status: 'Menunggu Konfirmasi' },
  { id: 'PMS-004', nama: 'Sari Indah', telepon: '084567890123', tanggal: '2026-05-20', jenis: 'Bus Medium', tujuan: 'Grobogan → Solo', status: 'Selesai' },
  { id: 'PMS-005', nama: 'Joko Susanto', telepon: '085678901234', tanggal: '2026-05-23', jenis: 'Elf Long', tujuan: 'Grobogan → Semarang', status: 'Ditolak' },
  { id: 'PMS-006', nama: 'Rina Kusuma', telepon: '086789012345', tanggal: '2026-05-24', jenis: 'Truk CDD Bak Terbuka', tujuan: 'Pengiriman Palawija - Purwodadi', status: 'Menunggu Konfirmasi' },
  { id: 'PMS-007', nama: 'Bagus Wicaksono', telepon: '087890123456', tanggal: '2026-05-25', jenis: 'Bus Medium', tujuan: 'Grobogan → Yogyakarta', status: 'Diterima' },
];

export const mockPembayaran = [
  { id: 'PAY-001', nama: 'Rizky Pratama', jenis: 'Bus Medium', tanggal: '2026-05-20', nominal: 'Rp 1.500.000', bukti: 'bukti_001.jpg', status: 'DP Diterima' },
  { id: 'PAY-002', nama: 'Dewi Rahayu', jenis: 'Elf Long', tanggal: '2026-05-21', nominal: 'Rp 750.000', bukti: '-', status: 'Menunggu Validasi' },
  { id: 'PAY-003', nama: 'Ahmad Fauzi', jenis: 'Truk CDD', tanggal: '2026-05-22', nominal: 'Rp 500.000', bukti: 'bukti_003.jpg', status: 'Menunggu Validasi' },
  { id: 'PAY-004', nama: 'Sari Indah', jenis: 'Bus Medium', tanggal: '2026-05-20', nominal: 'Rp 1.500.000', bukti: 'bukti_004.jpg', status: 'Lunas' },
  { id: 'PAY-005', nama: 'Joko Susanto', jenis: 'Elf Long', tanggal: '2026-05-23', nominal: 'Rp 750.000', bukti: '-', status: 'Belum Membayar' },
  { id: 'PAY-006', nama: 'Rina Kusuma', jenis: 'Truk CDD', tanggal: '2026-05-24', nominal: 'Rp 500.000', bukti: 'bukti_006.jpg', status: 'Menunggu Validasi' },
  { id: 'PAY-007', nama: 'Bagus Wicaksono', jenis: 'Bus Medium', tanggal: '2026-05-25', nominal: 'Rp 1.500.000', bukti: 'bukti_007.jpg', status: 'DP Diterima' },
];

export const mockSopir = [
  { id: 'SPR-001', nama: 'Budi Santoso', telepon: '081111222333', alamat: 'Jl. Pahlawan No. 12, Purwodadi', status: 'Aktif', armada: 'Bus Medium (H 1234 AA)' },
  { id: 'SPR-002', nama: 'Agus Prasetyo', telepon: '082222333444', alamat: 'Jl. Diponegoro No. 5, Grobogan', status: 'Aktif', armada: 'Elf Long (H 5678 BB)' },
  { id: 'SPR-003', nama: 'Slamet Riyadi', telepon: '083333444555', alamat: 'Jl. Merdeka No. 8, Purwodadi', status: 'Aktif', armada: 'Truk CDD (H 9012 CC)' },
  { id: 'SPR-004', nama: 'Heru Wibowo', telepon: '084444555666', alamat: 'Jl. Sudirman No. 15, Grobogan', status: 'Aktif', armada: 'Truk CDD (H 7890 EE)' },
  { id: 'SPR-005', nama: 'Eko Wahyudi', telepon: '085555666777', alamat: 'Jl. Ahmad Yani No. 3, Grobogan', status: 'Tidak Aktif', armada: '-' },
];

