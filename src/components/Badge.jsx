// Badge component for status display
const statusConfig = {
  // Armada (dari API - lowercase)
  'aktif': { bg: '#dcfce7', text: '#16a34a', dot: '#22c55e' },
  'tersedia': { bg: '#dcfce7', text: '#16a34a', dot: '#22c55e' },
  'dipesan': { bg: '#fce7f3', text: '#9d174d', dot: '#ec4899' },
  'dalam_perjalanan': { bg: '#dbeafe', text: '#1d4ed8', dot: '#3b82f6' },
  'perawatan': { bg: '#fef9c3', text: '#a16207', dot: '#eab308' },
  'selesai': { bg: '#dcfce7', text: '#16a34a', dot: '#22c55e' },
  'dibatalkan': { bg: '#fee2e2', text: '#dc2626', dot: '#ef4444' },
  'tidak_aktif': { bg: '#f1f5f9', text: '#64748b', dot: '#94a3b8' },
  'terjadwal': { bg: '#e0e7ff', text: '#4338ca', dot: '#6366f1' },
  // Pemesanan (lowercase)
  'menunggu_konfirmasi': { bg: '#fef9c3', text: '#a16207', dot: '#eab308' },
  'diterima': { bg: '#dcfce7', text: '#16a34a', dot: '#22c55e' },
  'ditolak': { bg: '#fee2e2', text: '#dc2626', dot: '#ef4444' },
  // Pembayaran (lowercase)
  'belum_membayar': { bg: '#f1f5f9', text: '#64748b', dot: '#94a3b8' },
  'menunggu_validasi': { bg: '#fef9c3', text: '#a16207', dot: '#eab308' },
  'dp_diterima': { bg: '#dbeafe', text: '#1d4ed8', dot: '#3b82f6' },
  'lunas': { bg: '#dcfce7', text: '#16a34a', dot: '#22c55e' },
  // Armada (display - Title Case)
  'Tersedia': { bg: '#dcfce7', text: '#16a34a', dot: '#22c55e' },
  'Dalam Perjalanan': { bg: '#dbeafe', text: '#1d4ed8', dot: '#3b82f6' },
  'Perawatan': { bg: '#fef9c3', text: '#a16207', dot: '#eab308' },
  'Tidak Aktif': { bg: '#f1f5f9', text: '#64748b', dot: '#94a3b8' },
  // Jadwal
  'Dipesan': { bg: '#fce7f3', text: '#9d174d', dot: '#ec4899' },
  'Selesai': { bg: '#dcfce7', text: '#16a34a', dot: '#22c55e' },
  'Terjadwal': { bg: '#e0e7ff', text: '#4338ca', dot: '#6366f1' },
  // Pemesanan (Title Case)
  'Menunggu Konfirmasi': { bg: '#fef9c3', text: '#a16207', dot: '#eab308' },
  'Diterima': { bg: '#dcfce7', text: '#16a34a', dot: '#22c55e' },
  'Ditolak': { bg: '#fee2e2', text: '#dc2626', dot: '#ef4444' },
  // Pembayaran (Title Case)
  'Belum Membayar': { bg: '#f1f5f9', text: '#64748b', dot: '#94a3b8' },
  'Menunggu Validasi': { bg: '#fef9c3', text: '#a16207', dot: '#eab308' },
  'DP Diterima': { bg: '#dbeafe', text: '#1d4ed8', dot: '#3b82f6' },
  'Lunas': { bg: '#dcfce7', text: '#16a34a', dot: '#22c55e' },
  // Sopir
  'Aktif': { bg: '#dcfce7', text: '#16a34a', dot: '#22c55e' },
  // General
  'Pending': { bg: '#fef9c3', text: '#a16207', dot: '#eab308' },
  'Total': { bg: '#dcfce7', text: '#16a34a', dot: '#22c55e' },
  'Active': { bg: '#dbeafe', text: '#1d4ed8', dot: '#3b82f6' },
  'New': { bg: '#fce7f3', text: '#9d174d', dot: '#ec4899' },
};

export default function Badge({ status }) {
  const config = statusConfig[status] || { bg: '#f1f5f9', text: '#64748b', dot: '#94a3b8' };
  return (
    <span
      className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium animate-scale-bounce"
      style={{ backgroundColor: config.bg, color: config.text }}
    >
      <span
        className="w-1.5 h-1.5 rounded-full flex-shrink-0"
        style={{ backgroundColor: config.dot }}
      />
      {status}
    </span>
  );
}
