import { useState, useEffect } from 'react';
import { Search, Filter, Eye, CheckCircle, XCircle, ImageIcon, Loader2, AlertTriangle, X, Download } from 'lucide-react';
import { useSearchParams } from 'react-router-dom';
import Layout from '../components/Layout';
import Card from '../components/Card';
import Badge from '../components/Badge';
import AppSelect from '../components/AppSelect';
import api from '../services/api';
import ConfirmModal from '../components/ConfirmModal';
import { formatRupiah } from '../utils/format';
import { useNotifications } from '../contexts/NotificationContext';

export default function Pembayaran() {
  const [pembayaran, setPembayaran] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const { refreshNotifications } = useNotifications();
  
  const [searchParams] = useSearchParams();
  const initSearch = searchParams.get('search') || '';
  const [search, setSearch] = useState(initSearch);
  const [filterStatus, setFilterStatus] = useState('Semua');

  const [toast, setToast] = useState(null);

  // Modals state
  const [showDetail, setShowDetail] = useState(false);
  const [selectedItem, setSelectedItem] = useState(null);
  const [showImagePreview, setShowImagePreview] = useState(false);
  const [previewUrl, setPreviewUrl] = useState('');

  // Single modal confirm state
  const [confirmConfig, setConfirmConfig] = useState({ isOpen: false, action: '', id: null });
  const [rejectReason, setRejectReason] = useState('');

  const [submitting, setSubmitting] = useState(false);

  const statusOptions = ['Semua', 'Belum Membayar', 'Menunggu Validasi', 'DP Diterima', 'Lunas', 'Ditolak'];

  // Helper function to resolve file URL correctly
  const resolveFileUrl = (url) => {
    if (!url) return null;
    if (url.startsWith('http')) return url;
    
    // Fallback if the backend sends a relative URL instead of absolute
    const baseUrl = import.meta.env.VITE_API_BASE_URL?.replace('/api', '') || 'http://localhost:8000';
    if (url.startsWith('/storage')) return `${baseUrl}${url}`;
    if (url.startsWith('storage')) return `${baseUrl}/${url}`;
    
    return url; // Default fallback
  };

  useEffect(() => {
    fetchPayments();
  }, []);

  const fetchPayments = async () => {
    try {
      setLoading(true);
      const res = await api.get('/admin/payments');
      setPembayaran(res.data.data);
      setError('');
    } catch (err) {
      setError('Gagal mengambil data pembayaran.');
    } finally {
      setLoading(false);
    }
  };

  const handleApprove = async () => {
    try {
      setSubmitting(true);
      await api.post(`/admin/payments/${confirmConfig.id}/approve`);
      showToast('Pembayaran berhasil diterima', 'success');
      fetchPayments();
      refreshNotifications();
      if (showDetail) {
        setShowDetail(false);
      }
      setConfirmConfig({ isOpen: false, action: '', id: null });
    } catch (err) {
      showToast(err.response?.data?.message || 'Gagal menerima pembayaran', 'error');
    } finally {
      setSubmitting(false);
    }
  };

  const openApproveModal = (id) => {
    setConfirmConfig({ isOpen: true, action: 'approve', id });
  };

  const openRejectModal = (id) => {
    setConfirmConfig({ isOpen: true, action: 'reject', id });
    setRejectReason('');
  };

  const handleReject = async () => {
    if (!rejectReason.trim()) {
      showToast('Alasan penolakan wajib diisi', 'error');
      return;
    }
    try {
      setSubmitting(true);
      await api.post(`/admin/payments/${confirmConfig.id}/reject`, { rejected_reason: rejectReason });
      showToast('Pembayaran berhasil ditolak', 'success');
      setConfirmConfig({ isOpen: false, action: '', id: null });
      fetchPayments();
      refreshNotifications();
      if (showDetail) {
        setShowDetail(false);
      }
    } catch (err) {
      showToast(err.response?.data?.message || 'Gagal menolak pembayaran', 'error');
    } finally {
      setSubmitting(false);
    }
  };

  const showToast = (msg, type) => {
    setToast({ message: msg, type });
    setTimeout(() => setToast(null), 3000);
  };

  const fetchDetail = async (id) => {
    try {
      setLoading(true);
      const res = await api.get(`/admin/payments/${id}`);
      setSelectedItem(res.data.data);
      setShowDetail(true);
    } catch (err) {
      showToast('Gagal memuat detail', 'error');
    } finally {
      setLoading(false);
    }
  };

  const filtered = pembayaran.filter((p) => {
    const matchSearch = p.customer_name.toLowerCase().includes(search.toLowerCase()) || p.order_code.toLowerCase().includes(search.toLowerCase());
    const matchStatus = filterStatus === 'Semua' || p.payment_status === filterStatus;
    return matchSearch && matchStatus;
  });

  return (
    <Layout>

      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-6 animate-fade-in-up" style={{ animationDelay: '0ms' }}>
        <div>
          <h1 className="text-2xl font-bold text-slate-800">Pembayaran</h1>
          <p className="text-sm text-slate-500 mt-1">Kelola dan validasi pembayaran dari pelanggan</p>
        </div>
        <div className="flex items-center gap-2">
          <span className="text-xs bg-yellow-50 text-yellow-700 border border-yellow-200 px-3 py-1.5 rounded-full font-medium">
            {pembayaran.filter(p => p.payment_status === 'Menunggu Validasi').length} Menunggu Validasi
          </span>
        </div>
      </div>

      {/* Summary mini cards */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 mb-5 animate-fade-in-up" style={{ animationDelay: '100ms' }}>
        {[
          { label: 'Belum Membayar', count: pembayaran.filter(p => p.payment_status === 'Belum Membayar').length, color: '#64748b', bg: '#f1f5f9' },
          { label: 'Menunggu Validasi', count: pembayaran.filter(p => p.payment_status === 'Menunggu Validasi').length, color: '#a16207', bg: '#fef9c3' },
          { label: 'DP Diterima', count: pembayaran.filter(p => p.payment_status === 'DP Diterima').length, color: '#1d4ed8', bg: '#dbeafe' },
          { label: 'Lunas', count: pembayaran.filter(p => p.payment_status === 'Lunas').length, color: '#16a34a', bg: '#dcfce7' },
        ].map((s) => (
          <Card key={s.label} className="p-4 text-center">
            <p className="text-2xl font-bold" style={{ color: s.color }}>{s.count}</p>
            <p className="text-xs text-slate-500 mt-1">{s.label}</p>
          </Card>
        ))}
      </div>

      {/* Filters */}
      <Card className="p-4 mb-5 animate-fade-in-up" style={{ animationDelay: '200ms' }}>
        <div className="flex flex-wrap gap-3 items-center">
          <div className="relative flex-1 min-w-52">
            <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
            <input
              type="text"
              placeholder="Cari Kode Pesanan atau Nama Pelanggan..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full pl-9 pr-4 py-2.5 border border-slate-200 rounded-xl text-sm bg-white text-slate-700 placeholder-slate-400 focus:outline-none focus:ring-2"
            />
          </div>
          <div className="flex items-center gap-2">
            <Filter size={15} className="text-slate-400" />
            <AppSelect
              value={filterStatus}
              onChange={setFilterStatus}
              options={statusOptions.map(o => ({ value: o, label: o }))}
              className="w-full md:w-auto md:min-w-[180px]"
            />
          </div>
        </div>
      </Card>

      {/* Table */}
      <Card className="animate-fade-in-up" style={{ animationDelay: '300ms' }}>
        <div className="overflow-x-auto">
          {loading && pembayaran.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-20 text-slate-400">
              <Loader2 size={36} className="animate-spin mb-3" style={{ color: '#a3e635' }} />
              <p className="text-sm font-medium">Memuat data pembayaran...</p>
            </div>
          ) : error ? (
            <div className="flex flex-col items-center justify-center py-20 text-red-400">
              <AlertTriangle size={40} className="mb-3 opacity-60" />
              <p className="text-sm font-medium text-center">{error}</p>
              <button onClick={fetchPayments} className="mt-4 px-4 py-2 text-xs font-semibold rounded-lg bg-red-50 text-red-600">Coba lagi</button>
            </div>
          ) : (
            <table className="w-full">
              <thead className="bg-white">
                <tr className="border-b border-slate-200">
                  {['Kode Pesanan', 'Nama Customer', 'Armada', 'Jenis', 'Bank', 'Nominal', 'Bukti', 'Status', 'Aksi'].map((h) => (
                    <th key={h} className="text-left text-[11px] font-bold text-slate-400 uppercase tracking-wider px-5 py-4">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {filtered.map((row, index) => (
                  <tr 
                    key={row.id} 
                    className="odd:bg-white even:bg-slate-50 hover:bg-slate-100/50 transition-colors animate-fade-in-up"
                    style={{ animationDelay: `${400 + (index * 50)}ms` }}
                  >
                    <td className="px-5 py-4 text-sm font-mono font-bold text-slate-800">{row.order_code}</td>
                    <td className="px-5 py-4">
                      <div className="flex items-center gap-2.5">
                        <div
                          className="w-8 h-8 rounded-full flex items-center justify-center text-white text-xs font-bold flex-shrink-0"
                          style={{ background: 'linear-gradient(135deg, #a3e635, #65a30d)' }}
                        >
                          {row.customer_name?.charAt(0) || '?'}
                        </div>
                        <span className="text-sm font-medium text-slate-800">{row.customer_name}</span>
                      </div>
                    </td>
                    <td className="px-5 py-4 text-sm text-slate-700">
                      <div className="font-semibold text-slate-800">{row.fleet_name}</div>
                      <div className="text-xs text-slate-500">{row.service_type}</div>
                    </td>
                    <td className="px-5 py-4">
                      <span className={`px-2.5 py-1 text-xs font-bold rounded-full ${row.payment_type === 'Pelunasan' ? 'bg-purple-100 text-purple-700' : 'bg-slate-100 text-slate-700'}`}>
                        {row.payment_type || 'DP'}
                      </span>
                    </td>
                    <td className="px-5 py-4">
                      <div className="text-sm font-bold text-slate-800">{row.bank_name}</div>
                      {row.bank_account_number && (
                        <div className="text-xs font-mono text-slate-500 mt-0.5">{row.bank_account_number}</div>
                      )}
                    </td>
                    <td className="px-5 py-4">
                      <div className="font-semibold text-slate-700">
                        {formatRupiah(row.amount)}
                      </div>
                    </td>
                    <td className="px-5 py-4">
                      {row.payment_proof_url ? (
                        <button 
                          onClick={() => {
                            console.log('Raw URL:', row.payment_proof_url);
                            console.log('Resolved URL:', resolveFileUrl(row.payment_proof_url));
                            setPreviewUrl(row.payment_proof_url);
                            setShowImagePreview(true);
                          }}
                          className="flex items-center gap-1.5 text-xs text-blue-600 hover:text-blue-700 font-medium bg-blue-50 px-2.5 py-1 rounded-lg transition-colors"
                        >
                          <ImageIcon size={12} />
                          Buka Gambar
                        </button>
                      ) : (
                        <span className="text-xs text-slate-400">Belum ada</span>
                      )}
                    </td>
                    <td className="px-5 py-4"><Badge status={row.payment_status} /></td>
                    <td className="px-5 py-4">
                      <div className="flex items-center gap-2">
                        <button onClick={() => fetchDetail(row.id)} className="p-1.5 rounded-lg bg-blue-50 text-blue-600 hover:bg-blue-100 transition-colors" title="Lihat Detail">
                          <Eye size={14} />
                        </button>
                        {row.payment_status === 'Menunggu Validasi' && (
                          <button onClick={() => openApproveModal(row.id)} disabled={submitting} className="p-1.5 rounded-lg bg-emerald-50 text-emerald-600 hover:bg-emerald-100 transition-colors disabled:opacity-50" title="Terima">
                            <CheckCircle size={16} />
                          </button>
                        )}
                        {(row.payment_status === 'Menunggu Validasi' || row.payment_status === 'DP Diterima' || row.payment_status === 'Belum Membayar') && (
                          <button onClick={() => openRejectModal(row.id)} disabled={submitting} className="p-1.5 rounded-lg bg-red-50 text-red-500 hover:bg-red-100 transition-colors disabled:opacity-50" title="Tolak">
                            <XCircle size={14} />
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
          {!loading && !error && filtered.length === 0 && (
            <div className="text-center py-16 text-slate-400">
              <Search size={40} className="mx-auto mb-3 opacity-30" />
              <p className="text-sm font-medium">Tidak ada data pembayaran</p>
            </div>
          )}
        </div>
      </Card>

      {/* Modal Detail */}
      {showDetail && selectedItem && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/40 backdrop-blur-sm">
          <div className="bg-white rounded-2xl w-full max-w-2xl max-h-[90vh] overflow-y-auto shadow-xl">
            <div className="flex items-center justify-between p-5 border-b border-slate-100 sticky top-0 bg-white/80 backdrop-blur-md z-10">
              <h3 className="text-lg font-bold text-slate-800">Detail Pembayaran</h3>
              <button onClick={() => setShowDetail(false)} className="text-slate-400 hover:text-slate-600 transition-colors">
                <X size={20} />
              </button>
            </div>
            <div className="p-6">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
                <div className="space-y-3">
                  <h4 className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">Informasi Pesanan</h4>
                  <div className="flex justify-between"><span className="text-sm text-slate-500">Kode Pesanan</span><span className="text-sm font-medium text-slate-800">{selectedItem.order_code}</span></div>
                  <div className="flex justify-between"><span className="text-sm text-slate-500">Armada</span><span className="text-sm font-medium text-slate-800">{selectedItem.fleet_name}</span></div>
                  <div className="flex justify-between"><span className="text-sm text-slate-500">Layanan</span><span className="text-sm font-medium text-slate-800">{selectedItem.service_type}</span></div>
                  <div className="flex justify-between"><span className="text-sm text-slate-500">Rute</span><span className="text-sm font-medium text-slate-800 text-right">{selectedItem.origin} <br/>ke {selectedItem.destination}</span></div>
                  <div className="flex justify-between"><span className="text-sm text-slate-500">Keberangkatan</span><span className="text-sm font-medium text-slate-800">{selectedItem.departure_date}</span></div>
                </div>
                <div className="space-y-3">
                  <h4 className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">Informasi Pelanggan</h4>
                  <div className="flex justify-between"><span className="text-sm text-slate-500">Nama</span><span className="text-sm font-medium text-slate-800">{selectedItem.customer_name}</span></div>
                  <div className="flex justify-between"><span className="text-sm text-slate-500">Email</span><span className="text-sm font-medium text-slate-800">{selectedItem.customer_email}</span></div>
                  <div className="flex justify-between"><span className="text-sm text-slate-500">Nomor HP</span><span className="text-sm font-medium text-slate-800">{selectedItem.customer_phone}</span></div>
                </div>
              </div>
              
              <div className="bg-slate-50 p-4 rounded-xl border border-slate-100 mb-6">
                <h4 className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-3">Rincian Transfer</h4>
                <div className="grid grid-cols-2 gap-4">
                  <div className="col-span-2 sm:col-span-1">
                    <span className="text-xs text-slate-500 block mb-1">Bank Tujuan</span>
                    <div className="text-sm font-bold text-slate-800">{selectedItem.bank_name || '-'}</div>
                    {selectedItem.bank_account_number && (
                      <div className="text-xs text-slate-500 font-mono mt-0.5">
                        {selectedItem.bank_account_number} a.n {selectedItem.bank_account_name || '-'}
                      </div>
                    )}
                  </div>
                  <div className="col-span-2 sm:col-span-1 flex justify-between items-center bg-slate-50 p-3 rounded-lg border border-slate-100">
                    <span className="text-xs font-semibold text-slate-500 uppercase tracking-wide">Nominal Transfer</span>
                    <span className="text-sm font-bold text-lime-600">{formatRupiah(selectedItem.amount)}</span>
                  </div>
                  <div>
                    <span className="text-xs text-slate-500 block mb-1">Status Pembayaran</span>
                    <Badge status={selectedItem.payment_status} />
                  </div>
                  <div>
                    <span className="text-xs text-slate-500 block mb-1">Waktu Upload</span>
                    <span className="text-sm font-medium text-slate-800">{selectedItem.created_at}</span>
                  </div>
                </div>
                {selectedItem.payment_status === 'Ditolak' && selectedItem.rejected_reason && (
                  <div className="mt-4 p-3 bg-red-50 rounded-lg border border-red-100">
                    <span className="text-xs text-red-500 font-bold block mb-1">Alasan Penolakan:</span>
                    <span className="text-sm text-red-700">{selectedItem.rejected_reason}</span>
                  </div>
                )}
              </div>

              <div className="mb-6">
                <h4 className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-3">Bukti Pembayaran</h4>
                {selectedItem.payment_proof_url ? (
                  <div className="border border-slate-200 rounded-xl overflow-hidden relative group cursor-pointer" onClick={() => { 
                    setPreviewUrl(selectedItem.payment_proof_url); 
                    setShowImagePreview(true); 
                  }}>
                    <div className="absolute inset-0 bg-slate-900/30 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
                      <span className="bg-white text-slate-800 text-sm font-bold px-4 py-2 rounded-full flex items-center gap-2">
                        <Eye size={16}/> Buka Penuh
                      </span>
                    </div>
                    {selectedItem.payment_proof_url.toLowerCase().endsWith('.pdf') ? (
                       <div className="w-full h-48 bg-slate-100 flex flex-col items-center justify-center text-slate-500">
                         <div className="w-12 h-12 bg-red-100 text-red-500 flex items-center justify-center rounded-lg mb-2 font-bold">PDF</div>
                         <span className="text-sm font-medium">Klik untuk buka dokumen</span>
                       </div>
                    ) : (
                       <img src={resolveFileUrl(selectedItem.payment_proof_url)} alt="Bukti Transfer" className="w-full h-48 object-cover" />
                    )}
                  </div>
                ) : (
                  <div className="p-6 bg-slate-50 rounded-xl border border-dashed border-slate-300 text-center text-slate-400 text-sm font-medium">
                    Bukti pembayaran belum tersedia
                  </div>
                )}
              </div>

              <div className="flex items-center gap-3 pt-4 border-t border-slate-100">
                {selectedItem.payment_status === 'Menunggu Validasi' && (
                  <button onClick={() => { setShowDetail(false); openApproveModal(selectedItem.id); }} disabled={submitting} className="flex-1 py-3 bg-emerald-500 hover:bg-emerald-600 text-white font-bold rounded-xl transition-colors disabled:opacity-50 flex items-center justify-center gap-2">
                    <CheckCircle size={18} /> Terima Pembayaran
                  </button>
                )}
                {(selectedItem.payment_status === 'Menunggu Validasi' || selectedItem.payment_status === 'DP Diterima' || selectedItem.payment_status === 'Belum Membayar') && (
                  <button onClick={() => { setShowDetail(false); openRejectModal(selectedItem.id); }} disabled={submitting} className="flex-1 py-3 bg-red-50 hover:bg-red-100 text-red-600 font-bold rounded-xl transition-colors disabled:opacity-50">
                    Tolak Pembayaran
                  </button>
                )}
              </div>
            </div>
          </div>
        </div>
      )}

      <ConfirmModal
        isOpen={confirmConfig.isOpen && confirmConfig.action === 'approve'}
        title={pembayaran.find(p => p.id === confirmConfig.id)?.payment_type === 'Pelunasan' ? "Terima Pelunasan" : "Terima Pembayaran DP"}
        message={
          pembayaran.find(p => p.id === confirmConfig.id)?.payment_type === 'Pelunasan' 
            ? "Pelunasan akan diterima dan status pembayaran pesanan akan berubah menjadi Lunas."
            : "Pembayaran DP akan diterima. Sistem akan membuat jadwal otomatis jika unit armada sudah ditetapkan."
        }
        confirmText={pembayaran.find(p => p.id === confirmConfig.id)?.payment_type === 'Pelunasan' ? "Terima Pelunasan" : "Terima DP"}
        variant="success"
        isLoading={submitting}
        onConfirm={handleApprove}
        onCancel={() => setConfirmConfig({ isOpen: false, action: '', id: null })}
      />

      <ConfirmModal
        isOpen={confirmConfig.isOpen && confirmConfig.action === 'reject'}
        title="Tolak Pembayaran"
        message="Pembayaran ini akan ditandai sebagai ditolak. Pastikan keputusan sudah sesuai."
        confirmText="Tolak Pembayaran"
        variant="danger"
        isLoading={submitting}
        onConfirm={handleReject}
        onCancel={() => setConfirmConfig({ isOpen: false, action: '', id: null })}
      >
        <textarea
          value={rejectReason}
          onChange={(e) => setRejectReason(e.target.value)}
          className="w-full border border-slate-200 rounded-xl p-3 text-sm focus:outline-none focus:ring-2 focus:ring-red-500/20 focus:border-red-500"
          rows="3"
          placeholder="Alasan penolakan (opsional jika sekadar batal)"
        />
      </ConfirmModal>

      {/* Modal Image Preview */}
      {showImagePreview && (
        <div className="fixed inset-0 z-[60] flex flex-col items-center justify-center p-4 bg-slate-900/90 backdrop-blur-md">
          <div className="w-full max-w-4xl flex justify-end gap-3 mb-4">
            <button onClick={() => window.open(resolveFileUrl(previewUrl), '_blank')} className="flex items-center gap-2 px-4 py-2 bg-white/10 hover:bg-white/20 text-white rounded-xl transition-colors font-medium text-sm">
              <Eye size={16} /> Buka Bukti
            </button>
            <a href={resolveFileUrl(previewUrl)} download target="_blank" rel="noreferrer" className="flex items-center gap-2 px-4 py-2 bg-white/10 hover:bg-white/20 text-white rounded-xl transition-colors font-medium text-sm">
              <Download size={16} /> Download Bukti
            </a>
            <button onClick={() => setShowImagePreview(false)} className="p-2 bg-white/10 hover:bg-white/20 text-white rounded-xl transition-colors">
              <X size={20} />
            </button>
          </div>
          <div className="relative max-h-[80vh] w-full max-w-4xl flex items-center justify-center bg-transparent">
            {!previewUrl ? (
              <div className="text-white text-center">
                <AlertTriangle size={48} className="mx-auto mb-4 opacity-50" />
                <p>Bukti pembayaran tidak dapat ditampilkan</p>
                <button onClick={() => window.open(resolveFileUrl(previewUrl), '_blank')} className="mt-4 px-4 py-2 bg-white/20 rounded-lg text-sm">Coba buka di tab baru</button>
              </div>
            ) : previewUrl.toLowerCase().endsWith('.pdf') ? (
              <div className="bg-white p-8 rounded-2xl flex flex-col items-center max-w-sm w-full text-center">
                <div className="w-20 h-20 bg-red-100 text-red-600 rounded-2xl flex items-center justify-center mb-4">
                  <span className="font-bold text-xl">PDF</span>
                </div>
                <h3 className="font-bold text-slate-800 mb-2">Dokumen PDF</h3>
                <p className="text-sm text-slate-500 mb-6">Bukti pembayaran diunggah dalam format PDF.</p>
                <div className="flex gap-3 w-full">
                  <button onClick={() => window.open(resolveFileUrl(previewUrl), '_blank')} className="flex-1 py-2.5 bg-blue-50 text-blue-600 font-semibold rounded-xl hover:bg-blue-100 transition-colors">
                    Buka PDF
                  </button>
                  <a href={resolveFileUrl(previewUrl)} download target="_blank" rel="noreferrer" className="flex-1 py-2.5 bg-slate-900 text-white font-semibold rounded-xl hover:bg-slate-800 transition-colors flex items-center justify-center gap-2">
                    <Download size={16} /> Download
                  </a>
                </div>
              </div>
            ) : (
              <img 
                src={resolveFileUrl(previewUrl)} 
                alt="Preview Bukti Transfer" 
                className="max-w-full max-h-full object-contain rounded-lg shadow-2xl" 
                onError={(e) => {
                  e.target.onerror = null;
                  e.target.style.display = 'none';
                  e.target.parentElement.innerHTML = `
                    <div class="text-white text-center">
                      <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="mx-auto mb-4 opacity-50"><path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3Z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>
                      <p>Gagal menampilkan bukti pembayaran</p>
                      <p class="text-sm opacity-70 mt-1">Pastikan file masih tersedia di server</p>
                      <button onclick="window.open('${resolveFileUrl(previewUrl)}', '_blank')" class="mt-4 px-4 py-2 bg-white/20 rounded-lg text-sm hover:bg-white/30 transition-colors">Coba buka di tab baru</button>
                    </div>
                  `;
                }}
              />
            )}
          </div>
        </div>
      )}

      {/* ── Toast ── */}
      {toast && (
        <Toast
          message={toast.message}
          type={toast.type}
          onClose={() => setToast(null)}
        />
      )}
    </Layout>
  );
}

// ─── Toast Component ─────────────────────────────────────────
function Toast({ message, type, onClose }) {
  useEffect(() => {
    const t = setTimeout(onClose, 3500);
    return () => clearTimeout(t);
  }, [onClose]);

  const isSuccess = type === 'success';
  const toastStyle = isSuccess
    ? { backgroundColor: '#dcfce7', color: '#15803d', border: '1px solid #bbf7d0' }
    : { backgroundColor: '#fee2e2', color: '#dc2626', border: '1px solid #fecaca' };
    
  return (
    <div
      className="fixed bottom-6 right-6 z-[100] flex items-center gap-3 px-5 py-3.5 rounded-2xl shadow-xl text-sm font-semibold animate-in slide-in-from-bottom-4 fade-in duration-300"
      style={toastStyle}
    >
      {isSuccess ? <CheckCircle size={18} /> : <AlertTriangle size={18} />}
      {message}
      <button onClick={onClose} className="ml-2 opacity-60 hover:opacity-100 transition-opacity">
        <X size={15} />
      </button>
    </div>
  );
}
