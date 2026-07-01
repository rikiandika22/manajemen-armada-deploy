import { useState, useEffect } from 'react';
import { useSearchParams } from 'react-router-dom';
import {
  Search, Eye, X, CheckCircle, XCircle, ChevronDown,
  AlertTriangle, Loader2, Package, Clock, Ban, Check,
  Info, Phone, MapPin, Calendar, FileText, CreditCard, Truck, Download
} from 'lucide-react';
import Layout from '../components/Layout';
import Card from '../components/Card';
import Badge from '../components/Badge';
import ConfirmModal from '../components/ConfirmModal';
import AppSelect from '../components/AppSelect';
import api from '../services/api';
import { formatRupiah } from '../utils/format';
import { useNotifications } from '../contexts/NotificationContext';

// ─── Constants ──────────────────────────────────────────────
const STATUS_PEMESANAN_LABEL = {
  'Menunggu Konfirmasi': 'Menunggu Konfirmasi',
  'Menunggu Konfirmasi Admin': 'Menunggu Konfirmasi',
  'Diterima': 'Diterima',
  'Ditolak': 'Ditolak',
  'Selesai': 'Selesai',
  'Dibatalkan': 'Dibatalkan',
};

const statusColors = {
  'Menunggu Konfirmasi': 'bg-yellow-100 text-yellow-800',
  'Diterima': 'bg-indigo-100 text-indigo-800',
  'Ditolak': 'bg-red-100 text-red-800',
  'Selesai': 'bg-emerald-100 text-emerald-800',
  'Dibatalkan': 'bg-red-100 text-red-800',
  'Terjadwal': 'bg-blue-100 text-blue-800',
};

const STATUS_PEMBAYARAN_LABEL = {
  'Belum Membayar': 'Belum Membayar',
  'Menunggu Validasi': 'Menunggu Validasi',
  'DP Diterima': 'DP Diterima',
  'Lunas': 'Lunas',
  'Ditolak': 'Ditolak',
};

// ─── Helpers ────────────────────────────────────────────────
function formatDate(iso) {
  if (!iso) return '—';
  return new Date(iso).toLocaleDateString('id-ID', { day: 'numeric', month: 'long', year: 'numeric' });
}

function isTerminalStatus(status) {
  return ['Selesai', 'Ditolak', 'Dibatalkan'].includes(status);
}

// ─── Pemesanan Component ───────────────────────────────────────────
export default function Pemesanan() {
  const [data, setData] = useState([]);
  const [armadas, setArmadas] = useState([]);
  const [loading, setLoading] = useState(true);
  const { refreshNotifications } = useNotifications();
  
  // Filters
  const [searchParams] = useSearchParams();
  const initSearch = searchParams.get('search') || '';
  const [search, setSearch] = useState(initSearch);
  const [filterPemesanan, setFilterPemesanan] = useState('semua');
  const [filterPembayaran, setFilterPembayaran] = useState('semua');
  const [filterArmada, setFilterArmada] = useState('semua');

  // Modals
  const [showDetail, setShowDetail] = useState(false);
  const [selectedItem, setSelectedItem] = useState(null);
  
  const [confirmConfig, setConfirmConfig] = useState({ isOpen: false, action: '', id: null, type: 'default', title: '', message: '' });
  const [submitting, setSubmitting] = useState(false);
  
  // Assign Fleet State
  const [selectedFleetId, setSelectedFleetId] = useState('');
  const [assigningFleet, setAssigningFleet] = useState(false);

  // Set Price State (for Truk)
  const [priceEstimate, setPriceEstimate] = useState('');
  const [priceDp, setPriceDp] = useState('');
  const [priceNote, setPriceNote] = useState('');
  const [sendingPrice, setSendingPrice] = useState(false);
  
  // Toast
  const [toast, setToast] = useState(null);

  useEffect(() => {
    fetchData();
  }, []);

  useEffect(() => {
    if (toast) {
      const t = setTimeout(() => setToast(null), 3000);
      return () => clearTimeout(t);
    }
  }, [toast]);

  const fetchData = async () => {
    setLoading(true);
    try {
      const [resOrders, resArmadas] = await Promise.all([
        api.get('/orders'),
        api.get('/armadas')
      ]);
      setData(resOrders.data.data);
      setArmadas(resArmadas.data.data);
    } catch (error) {
      console.error('Error fetching data:', error);
      setToast({ message: 'Gagal memuat data', type: 'error' });
    } finally {
      setLoading(false);
    }
  };

  const showToast = (message, type = 'success') => setToast({ message, type });

  // ── Filters ──
  const filtered = data.filter((p) => {
    const q = search.toLowerCase();
    const nama = p.user?.name || '';
    const noTelp = p.user?.phone_number || '';
    const matchSearch = 
      p.order_code.toLowerCase().includes(q) ||
      nama.toLowerCase().includes(q) ||
      noTelp.includes(q) ||
      p.destination.toLowerCase().includes(q);
    
    const mappedStatus = p.order_status === 'Menunggu Konfirmasi Admin' ? 'Menunggu Konfirmasi' : p.order_status;
    const matchPemesanan = filterPemesanan === 'semua' || mappedStatus === filterPemesanan;
    const matchPembayaran = filterPembayaran === 'semua' || p.payment_status === filterPembayaran;
    
    let jenisArmadaGroup = 'Lainnya';
    if (p.fleet_type.toLowerCase().includes('bus')) jenisArmadaGroup = 'Bus';
    if (p.fleet_type.toLowerCase().includes('elf')) jenisArmadaGroup = 'Elf';
    if (p.fleet_type.toLowerCase().includes('truk')) jenisArmadaGroup = 'Truk';
    
    const matchArmada = filterArmada === 'semua' || jenisArmadaGroup === filterArmada;
    
    return matchSearch && matchPemesanan && matchPembayaran && matchArmada;
  });

  const stats = {
    menunggu: data.filter(p => ['Menunggu Konfirmasi', 'Menunggu Konfirmasi Admin'].includes(p.order_status)).length,
    diterima: data.filter(p => p.order_status === 'Diterima').length,
    total: data.length,
  };

  // ── Actions ──
  async function updateStatus(id, newStatus) {
    if (newStatus !== 'Diterima' && newStatus !== 'Terjadwal') {
      const updated = data.map(p =>
        p.id === id ? { ...p, order_status: newStatus } : p
      );
      setData(updated);

      const labels = {
        'Ditolak': 'ditolak',
        'Dibatalkan': 'dibatalkan',
      };
      showToast(`Pemesanan berhasil ${labels[newStatus]}`, 'success');
      setConfirmConfig({ isOpen: false });
      refreshNotifications();
      return;
    }

    setSubmitting(true);
    try {
      const res = await api.post(`/orders/${id}/confirm`);
      showToast(res.data.message || 'Pesanan berhasil dikonfirmasi dan jadwal armada berhasil dibuat.', 'success');
      await fetchData();
      refreshNotifications();
    } catch (error) {
      console.error('Error confirm order:', error);
      showToast(error.response?.data?.message || 'Gagal mengonfirmasi pesanan', 'error');
    } finally {
      setSubmitting(false);
      setConfirmConfig({ isOpen: false });
    }
  }

  function openConfirm(row, action) {
    if (action === 'Diterima') {
      setConfirmConfig({
        isOpen: true,
        action: 'Diterima',
        id: row.id,
        variant: 'success',
        title: 'Buat Jadwal Sekarang',
        message: 'Buat jadwal secara manual untuk data lama ini (hanya karena pembayaran sudah divalidasi)?',
        confirmText: 'Buat Jadwal'
      });
    } else if (action === 'Ditolak') {
      setConfirmConfig({
        isOpen: true,
        action: 'Ditolak',
        id: row.id,
        variant: 'danger',
        title: 'Tolak Pesanan',
        message: 'Tolak pesanan ini?'
      });
    } else if (action === 'Dibatalkan') {
      setConfirmConfig({
        isOpen: true,
        action: 'Dibatalkan',
        id: row.id,
        variant: 'danger',
        title: 'Batalkan Pesanan',
        message: 'Batalkan pesanan ini? Aksi tidak bisa diurungkan.'
      });
    }
  }

  const handleConfirm = () => {
    if (confirmConfig.action === 'send_price') {
      executeSetPrice();
    } else {
      updateStatus(confirmConfig.id, confirmConfig.action);
    }
  };

  const handleAssignFleet = async () => {
    if (!selectedFleetId) {
      showToast('Pilih unit armada terlebih dahulu', 'error');
      return;
    }

    setAssigningFleet(true);
    try {
      await api.put(`/orders/${selectedItem.id}/assign-fleet`, {
        assigned_fleet_id: selectedFleetId
      });
      showToast('Unit armada berhasil ditetapkan', 'success');
      await fetchData();
      refreshNotifications();
      const updatedRes = await api.get(`/orders/${selectedItem.id}`);
      setSelectedItem(updatedRes.data.data);
    } catch (error) {
      console.error('Error assign fleet:', error);
      showToast(error.response?.data?.message || 'Gagal menetapkan armada', 'error');
    } finally {
      setAssigningFleet(false);
    }
  };

  const promptSendPrice = () => {
    if (!priceEstimate || !priceDp) {
      showToast('Isi estimasi harga dan DP', 'error');
      return;
    }
    
    if (parseFloat(priceDp) > parseFloat(priceEstimate)) {
      showToast('Nominal DP tidak boleh lebih besar dari estimasi harga', 'error');
      return;
    }

    setConfirmConfig({
      isOpen: true,
      action: 'send_price',
      id: selectedItem.id,
      variant: 'default',
      title: 'Kirim Harga',
      message: 'Pastikan harga yang dimasukkan sudah benar. Harga akan dikirim ke pelanggan.'
    });
  };

  const executeSetPrice = async () => {
    setSendingPrice(true);
    try {
      const cleanPrice = priceEstimate.toString().replace(/[^0-9]/g, '');
      const cleanDp = priceDp.toString().replace(/[^0-9]/g, '');

      await api.post(`/orders/${selectedItem.id}/set-truck-price`, {
        total_price: cleanPrice,
        dp_amount: cleanDp,
        price_note: priceNote
      });
      showToast('Harga berhasil dikirim ke pelanggan', 'success');
      await fetchData();
      refreshNotifications();
      
      const updatedRes = await api.get(`/orders/${selectedItem.id}`);
      setSelectedItem(updatedRes.data.data);
    } catch (err) {
      showToast(err.response?.data?.message || 'Gagal mengirim harga', 'error');
    } finally {
      setSendingPrice(false);
      setConfirmConfig({ isOpen: false });
    }
  };

  // ── Render ──
  return (
    <Layout>
      {toast && (
        <div className="fixed bottom-4 right-4 bg-slate-800 text-white px-6 py-3 rounded-xl shadow-2xl z-50 flex items-center gap-3 animate-fade-in-up">
          {toast.type === 'success' ? <CheckCircle size={18} className="text-emerald-400" /> : <XCircle size={18} className="text-red-400" />}
          <span className="text-sm font-semibold">{toast.message}</span>
        </div>
      )}

      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-6 animate-fade-in-up" style={{ animationDelay: '0ms' }}>
        <div>
          <p className="text-sm text-slate-500 mt-0.5">Kelola permintaan pemesanan dari pelanggan</p>
        </div>
        
        {stats.menunggu > 0 && (
          <span className="flex items-center gap-2 text-xs font-semibold bg-amber-50 text-amber-600 border border-amber-200 px-3 py-2 rounded-xl">
            <Clock size={14} />
            {stats.menunggu} Menunggu Konfirmasi
          </span>
        )}
      </div>

      <div className={`transition-all duration-300 ease-in-out ${showDetail ? 'lg:flex lg:gap-6' : ''}`}>
        <div className={`flex-1 transition-all duration-300 ${showDetail ? 'hidden lg:block' : 'block'}`}>
          <Card className="p-4 mb-5 border-none shadow-sm bg-white/50 backdrop-blur-sm">
            <div className="flex flex-wrap gap-3 items-center">
              <div className="relative flex-1 min-w-52">
                <Search size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" />
                <input
                  type="text"
                  placeholder="Cari kode, nama, telepon..."
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  className="w-full pl-10 pr-4 py-2.5 border border-slate-200 rounded-xl text-sm bg-white text-slate-700 placeholder-slate-400 focus:outline-none focus:ring-2 focus:border-transparent transition-shadow"
                />
              </div>
              <AppSelect
                value={filterPemesanan}
                onChange={setFilterPemesanan}
                options={[
                  { value: 'semua', label: 'Semua Status Pesanan' },
                  ...Object.entries(STATUS_PEMESANAN_LABEL).map(([k, v]) => ({ value: k, label: v }))
                ]}
                className="w-full md:w-auto md:min-w-[180px]"
              />
              <AppSelect
                value={filterPembayaran}
                onChange={setFilterPembayaran}
                options={[
                  { value: 'semua', label: 'Semua Pembayaran' },
                  ...Object.entries(STATUS_PEMBAYARAN_LABEL).map(([k, v]) => ({ value: k, label: v }))
                ]}
                className="w-full md:w-auto md:min-w-[180px]"
              />
              <AppSelect
                value={filterArmada}
                onChange={setFilterArmada}
                options={[
                  { value: 'semua', label: 'Semua Armada' },
                  { value: 'Bus', label: 'Bus' },
                  { value: 'Elf', label: 'Elf' },
                  { value: 'Truk', label: 'Truk' }
                ]}
                className="w-full md:w-auto md:min-w-[160px]"
              />
            </div>
          </Card>

          <Card className="border-none shadow-sm overflow-hidden bg-white">
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead className="bg-white">
                  <tr className="border-b border-slate-200">
                    {['Kode Pesanan', 'Pelanggan', 'Tanggal Sewa', 'Armada', 'Status', 'Pembayaran', 'Aksi'].map(h => (
                      <th key={h} className="text-left text-[11px] font-bold text-slate-400 uppercase tracking-wider px-5 py-4">{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {filtered.map((p, index) => (
                    <tr 
                      key={p.id} 
                      className={`hover:bg-slate-50 transition-colors animate-fade-in-up ${selectedItem?.id === p.id ? 'bg-blue-50/50' : ''}`}
                      style={{ animationDelay: `${150 + (index * 50)}ms` }}
                    >
                      <td className="px-5 py-4 whitespace-nowrap text-sm font-bold text-slate-800">{p.order_code}</td>
                      <td className="px-5 py-4">
                        <div className="flex items-center gap-2.5">
                          <div
                            className="w-8 h-8 rounded-full flex items-center justify-center text-white text-xs font-bold flex-shrink-0"
                            style={{ background: 'linear-gradient(135deg, #a3e635, #65a30d)' }}
                          >
                            {(p.user?.name || 'U').charAt(0).toUpperCase()}
                          </div>
                          <div className="flex flex-col">
                            <span className="text-sm font-medium text-slate-800">{p.user?.name || 'Unknown'}</span>
                            {p.user?.phone_number && (
                              <span className="text-xs text-slate-500">{p.user.phone_number}</span>
                            )}
                          </div>
                        </div>
                      </td>
                      <td className="px-5 py-4 text-sm text-slate-700">
                        <div className="font-medium text-slate-800">{formatDate(p.departure_date)}</div>
                        <div className="text-xs text-slate-500">{p.departure_time || '—'}</div>
                      </td>
                      <td className="px-5 py-4 text-sm text-slate-700">
                        <div className="font-semibold text-slate-800">{p.fleet_type}</div>
                        {p.assigned_fleet && (
                          <div className="mt-1 inline-flex items-center px-2 py-0.5 rounded text-[10px] font-bold bg-slate-200 text-slate-700 w-fit">
                            {p.assigned_fleet.plat_nomor}
                          </div>
                        )}
                      </td>
                      <td className="px-5 py-4">
                        <Badge status={p.order_status === 'Menunggu Konfirmasi Admin' ? 'Menunggu Konfirmasi' : p.order_status} />
                      </td>
                      <td className="px-5 py-4">
                        <Badge status={p.payment_status} type="payment" />
                      </td>
                      <td className="px-5 py-4">
                        <div className="flex items-center gap-2">
                          <button
                            onClick={() => { 
                              setSelectedItem(p); 
                              setShowDetail(true); 
                              setSelectedFleetId(p.assigned_fleet_id || '');
                              setPriceEstimate(p.total_price || '');
                              setPriceDp(p.dp_amount || '');
                              setPriceNote(p.price_note || '');
                            }}
                            className="p-1.5 rounded-lg bg-blue-50 text-blue-600 hover:bg-blue-100 transition-colors"
                            title="Lihat Detail"
                          >
                            <Eye size={14} />
                          </button>
                          
                          {!isTerminalStatus(p.order_status) && (
                            <>
                              {['Menunggu Konfirmasi', 'Menunggu Konfirmasi Admin'].includes(p.order_status) && (
                                <button onClick={() => openConfirm(p, 'Ditolak')} className="p-1.5 rounded-lg bg-red-50 text-red-500 hover:bg-red-100 transition-colors" title="Tolak">
                                  <XCircle size={14} />
                                </button>
                              )}
                              {['DP Diterima', 'Lunas', 'Pembayaran Diterima'].includes(p.payment_status) && p.order_status !== 'Terjadwal' && (
                                <button onClick={() => openConfirm(p, 'Diterima')} className="p-1.5 rounded-lg text-xs font-semibold bg-indigo-50 text-indigo-600 hover:bg-indigo-100 transition-colors" title="Buat Jadwal">
                                  Buat Jadwal
                                </button>
                              )}
                              {p.order_status === 'Terjadwal' && (
                                <>
                                  <button onClick={() => openConfirm(p, 'Dibatalkan')} className="p-1.5 rounded-lg bg-red-50 text-red-500 hover:bg-red-100 transition-colors" title="Batalkan">
                                    <Ban size={14} />
                                  </button>
                                </>
                              )}
                            </>
                          )}
                        </div>
                      </td>
                    </tr>
                  ))}
                  {loading ? (
                    <tr>
                      <td colSpan="7" className="px-5 py-12 text-center">
                        <div className="flex flex-col items-center justify-center text-slate-400">
                          <Loader2 size={40} className="mx-auto mb-4 opacity-50 animate-spin text-blue-500" />
                          <p className="text-sm font-medium">Memuat data pemesanan...</p>
                        </div>
                      </td>
                    </tr>
                  ) : filtered.length === 0 ? (
                    <tr>
                      <td colSpan="7" className="px-5 py-12 text-center">
                        <div className="flex flex-col items-center justify-center text-slate-400 animate-fade-in">
                          <Package size={48} className="mb-4 text-slate-300" />
                          <p className="text-sm font-medium">Belum ada data pemesanan</p>
                        </div>
                      </td>
                    </tr>
                  ) : null}
                </tbody>
              </table>
            </div>
          </Card>
        </div>

        {/* ── Modal Detail Panel ── */}
        {showDetail && selectedItem && (
          <div className="w-full lg:w-[420px] flex-shrink-0 bg-white rounded-2xl shadow-xl overflow-hidden border border-slate-100 flex flex-col max-h-[85vh] animate-slide-in-right">
            <div className="flex items-center justify-between px-6 py-4 border-b border-slate-100 bg-slate-50/50">
              <h3 className="font-bold text-slate-800 flex items-center gap-2">
                <FileText size={18} className="text-blue-500" />
                Detail Pesanan
              </h3>
              <button
                onClick={() => setShowDetail(false)}
                className="p-2 text-slate-400 hover:bg-slate-100 hover:text-slate-600 rounded-full transition-colors"
              >
                <X size={18} />
              </button>
            </div>
            
            <div className="flex-1 overflow-y-auto">
              <div className="p-6 border-b border-slate-100 space-y-4">
                <div className="flex justify-between items-center">
                  <span className="text-sm font-bold text-slate-800">{selectedItem?.order_code || '-'}</span>
                  <Badge status={selectedItem?.order_status} />
                </div>
                
                <div>
                  <label className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-1 block">Pelanggan</label>
                  <p className="text-sm font-bold text-slate-700">{selectedItem?.user?.name || '-'}</p>
                  <p className="text-sm text-slate-500 flex items-center gap-1 mt-1"><Phone size={14}/> {selectedItem?.user?.phone_number || '-'}</p>
                </div>

                <div>
                  <label className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-1 block">Tujuan & Waktu</label>
                  <div className="flex flex-col gap-2 mt-2">
                    <div className="flex gap-2 items-start">
                      <MapPin size={16} className="text-slate-400 mt-0.5" />
                      <div className="flex-1">
                        <p className="text-sm font-semibold text-slate-700">{selectedItem?.origin || '-'} ➔ {selectedItem?.destination || '-'}</p>
                        <p className="text-xs text-slate-500 mt-0.5">{selectedItem?.service_type || '-'}</p>
                      </div>
                    </div>
                    <div className="flex gap-2 items-start">
                      <Calendar size={16} className="text-slate-400 mt-0.5" />
                      <div className="flex-1">
                        <p className="text-sm font-semibold text-slate-700">{formatDate(selectedItem?.departure_date)}</p>
                        <p className="text-xs text-slate-500 mt-0.5">{selectedItem?.departure_time || '-'}</p>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              {/* Detail Kebutuhan Truk (Khusus Truk) */}
              {(selectedItem?.fleet_type?.toLowerCase() === 'truk' || selectedItem?.service_type?.toLowerCase() === 'truk logistik') && (
                <div className="border-t border-slate-100 p-6 bg-white">
                  <h4 className="text-sm font-bold text-slate-800 mb-4 flex items-center gap-2">
                    <Package size={16} className="text-slate-500" />
                    Detail Kebutuhan Truk
                  </h4>
                  <div className="grid grid-cols-2 gap-y-4 gap-x-4">
                    {(() => {
                       const t = selectedItem.truck_service_type?.toLowerCase() || '';
                       const isTernak = t.includes('ternak');
                       const isMaterial = t.includes('pasir') || t.includes('abu') || t.includes('material');
                       
                       const lType = isTernak ? 'Jenis Ternak' : (isMaterial ? 'Jenis Material' : 'Jenis Muatan');
                       const lQty = isTernak ? 'Jumlah Ternak' : 'Jumlah Muatan';
                       const lWeight = isMaterial ? 'Estimasi Vol/Berat' : 'Estimasi Berat';
                       const lNotes = isTernak ? 'Catatan Ternak' : (isMaterial ? 'Catatan Material' : 'Catatan Tambahan');

                       return (
                         <>
                           <div>
                             <span className="text-xs font-semibold text-slate-500 block mb-1">Jenis Layanan</span>
                             <span className="text-sm font-medium text-slate-800">{selectedItem?.truck_service_type || '-'}</span>
                           </div>
                           <div>
                             <span className="text-xs font-semibold text-slate-500 block mb-1">{lType}</span>
                             <span className="text-sm font-medium text-slate-800">{selectedItem?.truck_load_type || 'Tidak diisi'}</span>
                           </div>
                           <div>
                             <span className="text-xs font-semibold text-slate-500 block mb-1">{lWeight}</span>
                             <span className="text-sm font-medium text-slate-800">{selectedItem?.truck_load_weight || 'Tidak diisi'}</span>
                           </div>
                           <div>
                             <span className="text-xs font-semibold text-slate-500 block mb-1">{lQty}</span>
                             <span className="text-sm font-medium text-slate-800">{selectedItem?.truck_load_quantity || 'Tidak diisi'}</span>
                           </div>
                           <div className="col-span-2">
                             <span className="text-xs font-semibold text-slate-500 block mb-1">Akses Lokasi</span>
                             <span className="text-sm font-medium text-slate-800">{selectedItem?.truck_access_note || 'Tidak diisi'}</span>
                           </div>
                           <div className="col-span-2">
                             <span className="text-xs font-semibold text-slate-500 block mb-1">{lNotes}</span>
                             <span className="text-sm font-medium text-slate-800">
                                {selectedItem?.truck_additional_note ? selectedItem.truck_additional_note : ''}
                                {selectedItem?.notes && selectedItem?.truck_additional_note ? ' | ' : ''}
                                {selectedItem?.notes ? selectedItem.notes : ''}
                                {!selectedItem?.notes && !selectedItem?.truck_additional_note ? 'Tidak diisi' : ''}
                             </span>
                           </div>
                         </>
                       );
                    })()}
                  </div>
                </div>
              )}

              {/* Assignment Armada */}
              <div className="p-6 bg-slate-50">
                <h4 className="text-sm font-bold text-slate-800 mb-4 flex items-center gap-2">
                  <Truck size={16} className="text-slate-500" />
                  Alokasi Armada
                </h4>
                
                <div className="space-y-4">
                  <div className="bg-white p-3 rounded-xl border border-slate-200">
                    <span className="text-xs font-semibold text-slate-500 block mb-1">Tipe Diminta</span>
                    <span className="text-sm font-bold text-slate-800">{selectedItem?.fleet_type || '-'}</span>
                  </div>

                  <div className="space-y-2">
                    <label className="text-xs font-semibold text-slate-600 block">
                      Pilih Unit {
                        selectedItem?.fleet_type?.toLowerCase().includes('bus') ? 'Bus' :
                        selectedItem?.fleet_type?.toLowerCase().includes('elf') ? 'Elf' : 'Truk'
                      }
                    </label>
                    <AppSelect
                      value={selectedFleetId}
                      onChange={setSelectedFleetId}
                      disabled={isTerminalStatus(selectedItem?.order_status) || selectedItem?.order_status === 'Terjadwal' || selectedItem?.order_status === 'Diterima'}
                      placeholder="-- Pilih Unit --"
                      options={armadas.filter(a => {
                        const orderTypeLower = selectedItem?.fleet_type?.toLowerCase() || '';
                        const armadaTypeLower = a.jenis_armada?.toLowerCase() || '';
                        
                        const orderIsBus = orderTypeLower.includes('bus');
                        const orderIsElf = orderTypeLower.includes('elf');
                        const orderIsTruk = orderTypeLower.includes('truk') || orderTypeLower.includes('truck');
                        
                        const armadaIsBus = armadaTypeLower.includes('bus');
                        const armadaIsElf = armadaTypeLower.includes('elf');
                        const armadaIsTruk = armadaTypeLower.includes('truk') || armadaTypeLower.includes('truck');
                        
                        if (orderIsBus && !armadaIsBus) return false;
                        if (orderIsElf && !armadaIsElf) return false;
                        if (orderIsTruk && !armadaIsTruk) return false;

                        const statusRaw = a.status_operasional ? a.status_operasional.toLowerCase() : '';
                        const isAvailable = statusRaw === 'aktif' || statusRaw === 'tersedia';
                        if (!isAvailable && a.id != selectedItem?.assigned_fleet_id) return false;

                        return true;
                      }).map(a => ({ value: String(a.id), label: `${a.plat_nomor} - ${a.nama_armada}` }))}
                      className="w-full"
                    />
                    <button
                      onClick={handleAssignFleet}
                      disabled={assigningFleet || isTerminalStatus(selectedItem?.order_status) || selectedItem?.order_status === 'Terjadwal' || selectedItem?.order_status === 'Diterima' || !selectedFleetId}
                      className="w-full flex items-center justify-center gap-2 py-2 text-sm font-semibold text-slate-700 bg-white border border-slate-200 rounded-lg hover:bg-slate-50 transition-all disabled:opacity-50"
                    >
                      {assigningFleet ? <Loader2 size={16} className="animate-spin" /> : <CheckCircle size={16} />}
                      {selectedItem?.assigned_fleet_id ? 'Ganti Unit' : 'Tetapkan Unit'}
                    </button>
                  </div>
                </div>

                {/* Penentuan Harga Truk */}
                {selectedItem?.fleet_type?.toLowerCase().includes('truk') ? (
                  <div className="mt-8 pt-6 border-t border-slate-200">
                    <h4 className="text-sm font-bold text-slate-800 mb-4 flex items-center gap-2">
                      <CreditCard size={16} className="text-slate-500" />
                      Penentuan Harga
                    </h4>
                    <div className="space-y-4">
                      <div>
                        <label className="block text-xs font-semibold text-slate-600 mb-1">Estimasi Harga (Total)</label>
                        <input
                          type="number"
                          value={priceEstimate}
                          onChange={(e) => setPriceEstimate(e.target.value)}
                          disabled={isTerminalStatus(selectedItem?.order_status) || selectedItem?.order_status === 'Diterima'}
                          className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:ring-2 focus:ring-blue-500/50 disabled:bg-slate-100 disabled:opacity-70"
                        />
                      </div>
                      <div>
                        <label className="block text-xs font-semibold text-slate-600 mb-1">Nominal DP</label>
                        <input
                          type="number"
                          value={priceDp}
                          onChange={(e) => setPriceDp(e.target.value)}
                          disabled={isTerminalStatus(selectedItem?.order_status) || selectedItem?.order_status === 'Diterima'}
                          className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:ring-2 focus:ring-blue-500/50 disabled:bg-slate-100 disabled:opacity-70"
                        />
                      </div>
                      <button
                        onClick={promptSendPrice}
                        disabled={sendingPrice || isTerminalStatus(selectedItem?.order_status) || selectedItem?.order_status === 'Diterima' || !selectedItem?.assigned_fleet_id || !priceEstimate || !priceDp}
                        className="w-full flex items-center justify-center gap-2 py-2 text-sm font-semibold text-white bg-blue-600 rounded-lg hover:bg-blue-700 transition-all disabled:opacity-50"
                      >
                        {sendingPrice ? <Loader2 size={16} className="animate-spin" /> : <Package size={16} />}
                        {selectedItem?.total_price ? 'Ubah Harga' : 'Kirim Harga'}
                      </button>
                    </div>
                  </div>
                ) : (
                  <div className="mt-8 pt-6 border-t border-slate-200">
                    <h4 className="text-sm font-bold text-slate-800 mb-4 flex items-center gap-2">
                      <CreditCard size={16} className="text-slate-500" />
                      Ringkasan Estimasi Harga
                    </h4>
                    <div className="space-y-3">
                      <div className="flex justify-between items-center">
                        <span className="text-xs font-semibold text-slate-500">Estimasi Harga</span>
                        <span className="text-sm font-bold text-slate-800">{formatRupiah(selectedItem?.total_price)}</span>
                      </div>
                      <div className="flex justify-between items-center">
                        <span className="text-xs font-semibold text-slate-500">Nominal DP</span>
                        <span className="text-sm font-bold text-slate-800">{formatRupiah(selectedItem?.dp_amount)}</span>
                      </div>
                      <div className="pt-2 border-t border-slate-200 flex justify-between items-center">
                        <span className="text-xs font-bold text-slate-700">Sisa Pembayaran</span>
                        <span className="text-sm font-bold text-emerald-600">{formatRupiah(selectedItem?.remaining_payment)}</span>
                      </div>
                    </div>
                  </div>
                )}
              </div>
            </div>
            
            <div className="p-4 border-t border-slate-100 bg-white">
              <button
                onClick={() => setShowDetail(false)}
                className="w-full py-2.5 bg-slate-100 hover:bg-slate-200 text-slate-700 font-semibold rounded-xl transition-colors"
              >
                Tutup Panel
              </button>
            </div>
          </div>
        )}
      </div>

      <ConfirmModal
        isOpen={confirmConfig.isOpen}
        title={confirmConfig.title}
        message={confirmConfig.message}
        confirmText={confirmConfig.confirmText || "Lanjutkan"}
        variant={confirmConfig.variant}
        isLoading={submitting || sendingPrice}
        onConfirm={handleConfirm}
        onCancel={() => setConfirmConfig({ isOpen: false, action: '', id: null, type: 'default', title: '', message: '' })}
      />
    </Layout>
  );
}
