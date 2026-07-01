import { useState, useEffect, useRef } from 'react';
import {
  Search, Plus, Filter, Calendar, Eye, Edit2, Trash2, Truck,
  X, ChevronDown, AlertTriangle, CheckCircle, Loader2,
  MapPin, Clock, User, Phone, FileText, Tag, Info
} from 'lucide-react';
import { useSearchParams } from 'react-router-dom';
import Layout from '../components/Layout';
import Card from '../components/Card';
import Badge from '../components/Badge';
import ConfirmModal from '../components/ConfirmModal';
import AppSelect from '../components/AppSelect';
import AppDateInput from '../components/AppDateInput';
import { getJadwalSummary } from '../services/api';
import api from '../services/api';
import { useNotifications } from '../contexts/NotificationContext';

// ─── Helpers ──────────────────────────────────────────────────
const STATUS_LABEL = {
  tersedia: 'Tersedia', dipesan: 'Dipesan', dalam_perjalanan: 'Dalam Perjalanan',
  perawatan: 'Perawatan', tidak_aktif: 'Tidak Aktif',
  selesai: 'Selesai', dibatalkan: 'Dibatalkan', terjadwal: 'Terjadwal', aktif: 'Aktif',
  Terjadwal: 'Terjadwal', Aktif: 'Aktif',
};

const STATUS_JADWAL_OPTIONS = ['tersedia', 'dipesan', 'Terjadwal', 'dalam_perjalanan', 'selesai', 'dibatalkan'];
const JENIS_JADWAL_OPTIONS = ['Pesanan Mobile', 'Pesanan Manual', 'Reservasi', 'Perawatan', 'Blokir Armada'];
const JENIS_OPTIONS = ['Bus Medium', 'Elf Long', 'Truk CDD Bak Terbuka'];

const EMPTY_FORM = {
  armada_id: '', tanggal_mulai: '', tanggal_selesai: '', jam_berangkat: '',
  lokasi_asal: '', lokasi_tujuan: '', detail_lokasi: '', nama_pelanggan: '',
  nomor_telepon: '', keperluan: '', status_jadwal: 'dipesan', jenis_jadwal: 'Pesanan Manual', keterangan: '',
};


function Toast({ message, type, onClose }) {
  useEffect(() => { const t = setTimeout(onClose, 3500); return () => clearTimeout(t); }, [onClose]);
  const s = type === 'success';
  const style = s ? { backgroundColor: '#dcfce7', color: '#15803d', border: '1px solid #bbf7d0' }
                   : { backgroundColor: '#fee2e2', color: '#dc2626', border: '1px solid #fecaca' };
  return (
    <div className="fixed bottom-6 right-6 z-[100] flex items-center gap-3 px-5 py-3.5 rounded-2xl shadow-xl text-sm font-semibold" style={style}>
      {s ? <CheckCircle size={18} /> : <AlertTriangle size={18} />}
      {message}
      <button onClick={onClose} className="ml-2 opacity-60 hover:opacity-100"><X size={15} /></button>
    </div>
  );
}

// ─── Modal Overlay ────────────────────────────────────────────
function ModalOverlay({ onClose, children }) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/40 backdrop-blur-sm"
      onClick={(e) => { if (e.target === e.currentTarget) onClose(); }}>
      {children}
    </div>
  );
}

// ─── FormField ────────────────────────────────────────────────
function FormField({ label, icon: Icon, error, children, optional }) {
  return (
    <div>
      <label className="block text-xs font-semibold text-slate-600 mb-1.5">
        {label} {optional && <span className="text-slate-400 font-normal">(opsional)</span>}
      </label>
      <div className="relative">
        {Icon && <Icon size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />}
        {children}
      </div>
      {error && <p className="text-xs text-red-500 mt-1">{error}</p>}
    </div>
  );
}

// ─── Jadwal Form Modal ────────────────────────────────────────
function JadwalFormModal({ title, onSubmit, onClose, form, formErrors, handleFormChange, submitLoading, isEditMode, armadaList }) {
  const selectedArmada = armadaList.find(a => String(a.id) === String(form.armada_id));
  const isArmadaBlocked = selectedArmada && ['perawatan', 'tidak_aktif', 'Perawatan', 'Tidak Aktif'].includes(selectedArmada.status_operasional);

  const armadaOptions = armadaList.map(a => ({
    value: String(a.id),
    label: `${a.kode_armada} — ${a.nama_armada} (${a.plat_nomor}) [${STATUS_LABEL[a.display_status || a.status_ketersediaan || a.status_operasional] || (a.display_status || a.status_ketersediaan || a.status_operasional)}]`,
  }));

  const inputCls = (field) => `w-full pl-9 pr-4 py-2.5 bg-slate-50 border rounded-lg text-sm text-slate-700 placeholder-slate-400 focus:bg-white focus:outline-none transition-colors ${formErrors[field] ? 'border-red-300 focus:border-red-400' : 'border-transparent focus:border-slate-300'}`;

  return (
    <ModalOverlay onClose={onClose}>
      <div className="bg-white rounded-2xl shadow-xl w-full max-w-xl overflow-hidden animate-in fade-in zoom-in-95 duration-200">
        <div className="flex items-center justify-between px-6 py-4 border-b border-slate-100">
          <h3 className="text-lg font-bold text-slate-800">{title}</h3>
          <button onClick={onClose} className="text-slate-400 hover:text-slate-600 transition-colors"><X size={20} /></button>
        </div>
        <form onSubmit={onSubmit}>
          <div className="px-6 py-5 space-y-4 max-h-[65vh] overflow-y-auto">

            {/* Pilih Armada */}
            <div>
              <label className="block text-xs font-semibold text-slate-600 mb-1.5">Pilih Armada</label>
              <AppSelect
                options={armadaOptions}
                value={form.armada_id}
                onChange={(v) => handleFormChange('armada_id', v)}
                placeholder="Pilih armada..."
              />
              {formErrors.armada_id && <p className="text-xs text-red-500 mt-1">{formErrors.armada_id}</p>}
              {selectedArmada && (
                <div className={`mt-2 p-3 rounded-xl text-xs space-y-1 ${isArmadaBlocked ? 'bg-red-50 border border-red-200' : 'bg-slate-50 border border-slate-100'}`}>
                  <div className="flex items-center justify-between">
                    <span className="font-semibold text-slate-700">{selectedArmada.kode_armada} — {selectedArmada.jenis_armada}</span>
                    <Badge status={selectedArmada.display_status || selectedArmada.status_ketersediaan || selectedArmada.status_operasional} />
                  </div>
                  <p className="text-slate-500">Plat: {selectedArmada.plat_nomor} · Kapasitas: {selectedArmada.kapasitas} {selectedArmada.satuan_kapasitas}</p>
                  {isArmadaBlocked && (
                    <p className="text-red-600 font-semibold flex items-center gap-1 mt-1"><AlertTriangle size={13} /> Armada tidak dapat dijadwalkan ({STATUS_LABEL[selectedArmada.status_operasional]})</p>
                  )}
                </div>
              )}
            </div>

            {/* Tanggal + Jam */}
            <div className="grid grid-cols-3 gap-3">
              <div>
                <label className="block text-xs font-semibold text-slate-600 mb-1.5">Tanggal Mulai</label>
                <AppDateInput value={form.tanggal_mulai} onChange={(v) => handleFormChange('tanggal_mulai', v)} className="w-full" />
                {formErrors.tanggal_mulai && <p className="text-xs text-red-500 mt-1">{formErrors.tanggal_mulai}</p>}
              </div>
              <div>
                <label className="block text-xs font-semibold text-slate-600 mb-1.5">Tanggal Selesai</label>
                <AppDateInput value={form.tanggal_selesai} onChange={(v) => handleFormChange('tanggal_selesai', v)} className="w-full" />
                {formErrors.tanggal_selesai && <p className="text-xs text-red-500 mt-1">{formErrors.tanggal_selesai}</p>}
              </div>
              <FormField label="Jam Berangkat" icon={Clock} error={formErrors.jam_berangkat}>
                <input type="time" value={form.jam_berangkat} onChange={(e) => handleFormChange('jam_berangkat', e.target.value)} className={inputCls('jam_berangkat')} />
              </FormField>
            </div>

            {/* Lokasi */}
            <div className="grid grid-cols-2 gap-4">
              <FormField label="Lokasi Asal" icon={MapPin} error={formErrors.lokasi_asal}>
                <input type="text" placeholder="cth: Grobogan" value={form.lokasi_asal} onChange={(e) => handleFormChange('lokasi_asal', e.target.value)} className={inputCls('lokasi_asal')} />
              </FormField>
              <FormField label="Lokasi Tujuan" icon={MapPin} error={formErrors.lokasi_tujuan}>
                <input type="text" placeholder="cth: Semarang" value={form.lokasi_tujuan} onChange={(e) => handleFormChange('lokasi_tujuan', e.target.value)} className={inputCls('lokasi_tujuan')} />
              </FormField>
            </div>

            {/* Detail Lokasi */}
            <FormField label="Detail Lokasi" icon={FileText} error={formErrors.detail_lokasi} optional>
              <input type="text" placeholder="Titik jemput atau alamat lengkap" value={form.detail_lokasi} onChange={(e) => handleFormChange('detail_lokasi', e.target.value)} className={inputCls('detail_lokasi')} />
            </FormField>

            {/* Pelanggan */}
            <div className="grid grid-cols-2 gap-4">
              <FormField label="Nama Pelanggan" icon={User} error={formErrors.nama_pelanggan}>
                <input type="text" placeholder="Nama pelanggan" value={form.nama_pelanggan} onChange={(e) => handleFormChange('nama_pelanggan', e.target.value)} className={inputCls('nama_pelanggan')} />
              </FormField>
              <FormField label="Nomor Telepon" icon={Phone} error={formErrors.nomor_telepon}>
                <input type="text" placeholder="08xxxxxxxxxx" value={form.nomor_telepon} onChange={(e) => handleFormChange('nomor_telepon', e.target.value)} className={inputCls('nomor_telepon')} />
              </FormField>
            </div>

            {/* Keperluan */}
            <FormField label="Keperluan" icon={Tag} error={formErrors.keperluan} optional>
              <input type="text" placeholder="cth: Wisata rombongan" value={form.keperluan} onChange={(e) => handleFormChange('keperluan', e.target.value)} className={inputCls('keperluan')} />
            </FormField>

            {/* Status Jadwal & Jenis */}
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-semibold text-slate-600 mb-1.5">Jenis Jadwal</label>
                <AppSelect options={JENIS_JADWAL_OPTIONS.map(o => ({ value: o, label: o }))} value={form.jenis_jadwal} onChange={(v) => handleFormChange('jenis_jadwal', v)} placeholder="Pilih jenis" />
                {formErrors.jenis_jadwal && <p className="text-xs text-red-500 mt-1">{formErrors.jenis_jadwal}</p>}
              </div>
              <div>
                <label className="block text-xs font-semibold text-slate-600 mb-1.5">Status Jadwal</label>
                <AppSelect options={STATUS_JADWAL_OPTIONS.map(o => ({ value: o, label: STATUS_LABEL[o] || o }))} value={form.status_jadwal} onChange={(v) => handleFormChange('status_jadwal', v)} placeholder="Pilih status" />
                {formErrors.status_jadwal && <p className="text-xs text-red-500 mt-1">{formErrors.status_jadwal}</p>}
              </div>
            </div>

            {/* Keterangan */}
            <div>
              <label className="block text-xs font-semibold text-slate-600 mb-1.5">Keterangan <span className="text-slate-400 font-normal">(opsional)</span></label>
              <div className="relative">
                <FileText size={16} className="absolute left-3 top-3 text-slate-400" />
                <textarea placeholder="Catatan tambahan..." value={form.keterangan} onChange={(e) => handleFormChange('keterangan', e.target.value)} rows={2}
                  className="w-full pl-9 pr-4 py-2.5 bg-slate-50 border border-transparent rounded-lg text-sm text-slate-700 placeholder-slate-400 focus:bg-white focus:border-slate-300 focus:outline-none transition-colors resize-none" />
              </div>
            </div>
          </div>

          {/* Footer */}
          <div className="px-6 py-4 border-t border-slate-100 flex items-center justify-center sm:justify-end gap-3 bg-white">
            <button type="button" onClick={onClose} disabled={submitLoading}
              className="px-6 py-2.5 text-sm font-semibold text-slate-700 bg-white border border-slate-200 rounded-full hover:bg-slate-50 transition-colors w-full sm:w-auto disabled:opacity-50">Batal</button>
            <button type="submit" disabled={submitLoading || isArmadaBlocked}
              className="flex items-center justify-center gap-2 px-6 py-2.5 text-sm font-semibold text-slate-900 rounded-full hover:opacity-90 transition-opacity shadow-sm w-full sm:w-auto disabled:opacity-70"
              style={{ backgroundColor: '#a3e635' }}>
              {submitLoading ? <><Loader2 size={15} className="animate-spin" /> Menyimpan...</> : 'Simpan Data'}
            </button>
          </div>
        </form>
      </div>
    </ModalOverlay>
  );
}

// ═══════════════════════════════════════════════════════════════
export default function Jadwal() {
  const [jadwals, setJadwals] = useState([]);
  const [armadaList, setArmadaList] = useState([]);
  const [summaryData, setSummaryData] = useState({
    terjadwal: 0,
    dalam_perjalanan: 0,
    perlu_diselesaikan: 0,
    selesai_hari_ini: 0
  });
  const [loading, setLoading] = useState(true);
  const { refreshNotifications } = useNotifications();
  const [error, setError] = useState(null);

  const [searchParams] = useSearchParams();
  const initSearch = searchParams.get('search') || '';
  const [search, setSearch] = useState(initSearch);
  const [filterTanggal, setFilterTanggal] = useState('');
  const [filterJenis, setFilterJenis] = useState('Semua');
  const [filterStatusJadwal, setFilterStatusJadwal] = useState('Semua');

  const [showTambah, setShowTambah] = useState(false);
  const [showEdit, setShowEdit] = useState(false);
  const [showDetail, setShowDetail] = useState(false);
  const [showHapus, setShowHapus] = useState(false);
  const [showComplete, setShowComplete] = useState(false);
  const [selectedJadwal, setSelectedJadwal] = useState(null);

  const [form, setForm] = useState(EMPTY_FORM);
  const [formErrors, setFormErrors] = useState({});
  const [submitLoading, setSubmitLoading] = useState(false);
  const [toast, setToast] = useState(null);
  const [mounted, setMounted] = useState(false);

  useEffect(() => { setMounted(true); fetchData(); }, []);
  
  useEffect(() => {
    const q = searchParams.get('search');
    if (q !== null) {
      setSearch(q);
    }
  }, [searchParams]);

  async function fetchData() {
    setLoading(true); setError(null);
    try {
      const [jRes, aRes, sRes] = await Promise.all([
        api.get('/jadwals'), 
        api.get('/armadas'),
        getJadwalSummary().catch(() => ({ data: { data: { terjadwal: 0, dalam_perjalanan: 0, perlu_diselesaikan: 0, selesai_hari_ini: 0 } } }))
      ]);
      setJadwals(jRes.data.data || []);
      setArmadaList(aRes.data.data || []);
      if (sRes?.data?.data) {
        setSummaryData(sRes.data.data);
      }
    } catch { setError('Gagal memuat data. Pastikan backend berjalan dan Anda sudah login.'); }
    finally { setLoading(false); }
  }

  // ── Filter ──
  const filtered = jadwals.filter((j) => {
    const q = search.toLowerCase();
    const matchSearch = !q || (j.armada?.plat_nomor || '').toLowerCase().includes(q)
      || (j.armada?.kode_armada || '').toLowerCase().includes(q)
      || (j.lokasi_asal || '').toLowerCase().includes(q)
      || (j.lokasi_tujuan || '').toLowerCase().includes(q)
      || (j.nama_pelanggan || '').toLowerCase().includes(q)
      || (j.kode_pesanan || '').toLowerCase().includes(q)
      || String(j.id) === q;
    const matchJenis = filterJenis === 'Semua' || j.armada?.jenis_armada === filterJenis;
    const matchStatus = filterStatusJadwal === 'Semua' || j.status_jadwal === filterStatusJadwal;
    const matchTanggal = !filterTanggal || j.tanggal_mulai === filterTanggal || j.tanggal_selesai === filterTanggal;
    return matchSearch && matchJenis && matchStatus && matchTanggal;
  });

  // ── Form ──
  function handleFormChange(field, value) {
    setForm(prev => ({ ...prev, [field]: value }));
    if (formErrors[field]) setFormErrors(prev => ({ ...prev, [field]: '' }));
  }

  function validateForm() {
    const e = {};
    if (!form.armada_id) e.armada_id = 'Armada wajib dipilih';
    if (!form.tanggal_mulai) e.tanggal_mulai = 'Tanggal mulai wajib diisi';
    if (!form.tanggal_selesai) e.tanggal_selesai = 'Tanggal selesai wajib diisi';
    if (form.tanggal_mulai && form.tanggal_selesai && form.tanggal_selesai < form.tanggal_mulai) e.tanggal_selesai = 'Tidak boleh lebih awal dari tanggal mulai';
    if (!form.jam_berangkat) e.jam_berangkat = 'Jam berangkat wajib diisi';
    if (!form.lokasi_asal?.trim()) e.lokasi_asal = 'Lokasi asal wajib diisi';
    if (!form.lokasi_tujuan?.trim()) e.lokasi_tujuan = 'Lokasi tujuan wajib diisi';
    if (!form.nama_pelanggan?.trim()) e.nama_pelanggan = 'Nama pelanggan wajib diisi';
    if (!form.nomor_telepon?.trim()) e.nomor_telepon = 'Nomor telepon wajib diisi';
    if (!form.status_jadwal) e.status_jadwal = 'Status jadwal wajib dipilih';
    return e;
  }

  function openTambah() { setForm(EMPTY_FORM); setFormErrors({}); setShowTambah(true); }

  async function handleTambah(e) {
    e.preventDefault();
    const errors = validateForm();
    if (Object.keys(errors).length > 0) { setFormErrors(errors); return; }
    setSubmitLoading(true);
    try {
      await api.post('/jadwals', form);
      setShowTambah(false); setForm(EMPTY_FORM); await fetchData();
      setToast({ message: 'Jadwal berhasil ditambahkan!', type: 'success' });
    } catch (err) {
      if (err.response?.status === 422) {
        const sv = err.response.data.errors || {};
        const m = {}; Object.keys(sv).forEach(k => { m[k] = sv[k][0]; }); setFormErrors(m);
      } else { setToast({ message: err.response?.data?.message || 'Gagal menambah jadwal.', type: 'error' }); }
    } finally { setSubmitLoading(false); }
  }

  function openEdit(jadwal) {
    setSelectedJadwal(jadwal);
    setForm({
      armada_id: String(jadwal.armada_id),
      tanggal_mulai: jadwal.tanggal_mulai?.split('T')[0] || '',
      tanggal_selesai: jadwal.tanggal_selesai?.split('T')[0] || '',
      jam_berangkat: jadwal.jam_berangkat || '',
      lokasi_asal: jadwal.lokasi_asal || '',
      lokasi_tujuan: jadwal.lokasi_tujuan || '',
      detail_lokasi: jadwal.detail_lokasi || '',
      nama_pelanggan: jadwal.nama_pelanggan || '',
      nomor_telepon: jadwal.nomor_telepon || '',
      keperluan: jadwal.keperluan || '',
      status_jadwal: jadwal.status_jadwal || 'dipesan',
      jenis_jadwal: jadwal.jenis_jadwal || 'Pesanan Manual',
      keterangan: jadwal.keterangan || '',
    });
    setFormErrors({}); setShowEdit(true);
  }

  async function handleEdit(e) {
    e.preventDefault();
    const errors = validateForm();
    if (Object.keys(errors).length > 0) { setFormErrors(errors); return; }
    setSubmitLoading(true);
    try {
      await api.put(`/jadwals/${selectedJadwal.id}`, form);
      setShowEdit(false); setSelectedJadwal(null); await fetchData();
      setToast({ message: 'Jadwal berhasil diperbarui!', type: 'success' });
    } catch (err) {
      if (err.response?.status === 422) {
        const sv = err.response.data.errors || {};
        const m = {}; Object.keys(sv).forEach(k => { m[k] = sv[k][0]; }); setFormErrors(m);
      } else { setToast({ message: err.response?.data?.message || 'Gagal memperbarui jadwal.', type: 'error' }); }
    } finally { setSubmitLoading(false); }
  }

  function openDetail(j) { setSelectedJadwal(j); setShowDetail(true); }
  function openHapus(j) { setSelectedJadwal(j); setShowHapus(true); }
  async function handleHapus() {
    setSubmitLoading(true);
    try {
      await api.delete(`/jadwals/${selectedJadwal.id}`);
      setShowHapus(false); setSelectedJadwal(null); await fetchData();
      setToast({ message: 'Jadwal berhasil dihapus!', type: 'success' });
    } catch { setToast({ message: 'Gagal menghapus jadwal.', type: 'error' }); }
    finally { setSubmitLoading(false); }
  }

  function openComplete(j) {
    if (j.order) {
      if (j.order.payment_status === 'Menunggu Validasi Pelunasan') {
        setToast({ message: 'Pelunasan masih menunggu validasi admin.', type: 'error' });
        return;
      }
      if (j.order.payment_status !== 'Lunas') {
        setToast({ message: 'Pembayaran belum lunas. Jadwal belum bisa diselesaikan.', type: 'error' });
        return;
      }
    }
    setSelectedJadwal(j);
    setShowComplete(true);
  }
  async function handleComplete() {
    setSubmitLoading(true);
    try {
      await api.patch(`/admin/jadwals/${selectedJadwal.id}/complete`);
      setShowComplete(false); setSelectedJadwal(null); await fetchData();
      setToast({ message: 'Jadwal berhasil ditandai selesai.', type: 'success' });
      refreshNotifications();
    } catch (err) { setToast({ message: err.response?.data?.message || 'Terjadi kesalahan saat menyelesaikan jadwal', type: 'error' }); }
    finally { setSubmitLoading(false); }
  }

  const checkPerluDiselesaikan = (row) => {
    if (row.status_jadwal !== 'terjadwal' && row.status_jadwal !== 'Terjadwal') return false;
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const end = new Date(row.tanggal_selesai);
    end.setHours(0, 0, 0, 0);
    return today > end;
  };

  const fmtDate = (d) => d ? new Date(d).toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' }) : '-';

  // ── Render ──
  return (
    <Layout>
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6 transition-all duration-500"
        style={{ opacity: mounted ? 1 : 0, transform: mounted ? 'translateY(0)' : 'translateY(-12px)' }}>
        <div>
          <h2 className="text-xl font-bold text-slate-800">Jadwal Armada</h2>
          <p className="text-sm text-slate-500 mt-0.5">Kelola jadwal operasional armada</p>
        </div>
        <button onClick={openTambah}
          className="flex items-center gap-2 px-4 py-2.5 rounded-xl text-sm font-semibold text-slate-900 hover:opacity-90 active:scale-95 transition-all duration-150 shadow-sm"
          style={{ backgroundColor: '#a3e635' }}>
          <Plus size={16} /> Tambah Jadwal
        </button>
      </div>

      {/* Summary Cards */}
      <div
        className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-5 transition-all duration-500 delay-75"
        style={{ opacity: mounted ? 1 : 0, transform: mounted ? 'translateY(0)' : 'translateY(12px)' }}
      >
        {[
          { label: 'Terjadwal', value: summaryData.terjadwal, color: '#16a34a', bg: '#dcfce7' },
          { label: 'Dalam Perjalanan', value: summaryData.dalam_perjalanan, color: '#1d4ed8', bg: '#dbeafe' },
          { label: 'Perlu Diselesaikan', value: summaryData.perlu_diselesaikan, color: '#ea580c', bg: '#ffedd5' },
          { label: 'Selesai Hari Ini', value: summaryData.selesai_hari_ini, color: '#059669', bg: '#d1fae5' },
        ].map((stat) => (
          <Card key={stat.label} className="p-4 hover:shadow-md transition-shadow duration-200">
            <p className="text-2xl font-bold" style={{ color: loading ? '#cbd5e1' : stat.color }}>
              {loading ? '—' : stat.value}
            </p>
            <p className="text-sm text-slate-500 mt-0.5">{stat.label}</p>
            <div className="mt-2 h-1 rounded-full" style={{ backgroundColor: stat.bg }} />
          </Card>
        ))}
      </div>

      {/* Filters */}
      <div className="transition-all duration-500 delay-100" style={{ opacity: mounted ? 1 : 0, transform: mounted ? 'translateY(0)' : 'translateY(12px)' }}>
        <Card className="p-4 mb-5">
          <div className="flex flex-wrap gap-3 items-center">
            <div className="relative flex-1 min-w-48">
              <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
              <input type="text" placeholder="Cari pelanggan, plat, rute..." value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="w-full pl-9 pr-4 py-2.5 border border-slate-200 rounded-xl text-sm bg-white text-slate-700 placeholder-slate-400 focus:outline-none focus:ring-2 transition-shadow" />
            </div>
            <div className="flex items-center gap-2">
              <Calendar size={15} className="text-slate-400" />
              <AppDateInput value={filterTanggal} onChange={setFilterTanggal} />
            </div>
            <div className="flex items-center gap-2">
              <Filter size={15} className="text-slate-400" />
              <AppSelect
                value={filterJenis}
                onChange={setFilterJenis}
                options={[{ value: 'Semua', label: 'Semua' }, ...JENIS_OPTIONS.map(o => ({ value: o, label: o }))]}
                className="w-full md:w-auto md:min-w-[160px]"
              />
            </div>
            <AppSelect
              value={filterStatusJadwal}
              onChange={setFilterStatusJadwal}
              options={[{ value: 'Semua', label: 'Semua Status' }, ...STATUS_JADWAL_OPTIONS.map(o => ({ value: o, label: STATUS_LABEL[o] || o }))]}
              className="w-full md:w-auto md:min-w-[160px]"
            />
            {(filterTanggal || filterJenis !== 'Semua' || filterStatusJadwal !== 'Semua' || search) && (
              <button onClick={() => { setFilterTanggal(''); setFilterJenis('Semua'); setFilterStatusJadwal('Semua'); setSearch(''); }}
                className="text-xs text-slate-500 hover:text-slate-700 underline">Reset</button>
            )}
          </div>
        </Card>
      </div>

      {/* Table */}
      <div className="transition-all duration-500 delay-150" style={{ opacity: mounted ? 1 : 0, transform: mounted ? 'translateY(0)' : 'translateY(12px)' }}>
        <Card>
          <div className="overflow-x-auto">
            {loading && (
              <div className="flex flex-col items-center justify-center py-20 text-slate-400">
                <Loader2 size={36} className="animate-spin mb-3" style={{ color: '#a3e635' }} />
                <p className="text-sm font-medium">Memuat data jadwal...</p>
              </div>
            )}
            {!loading && error && (
              <div className="flex flex-col items-center justify-center py-20 text-red-400">
                <AlertTriangle size={40} className="mb-3 opacity-60" />
                <p className="text-sm font-medium text-center max-w-xs">{error}</p>
                <button onClick={fetchData} className="mt-4 px-4 py-2 text-xs font-semibold rounded-lg bg-red-50 text-red-600 hover:bg-red-100 transition-colors">Coba lagi</button>
              </div>
            )}
            {!loading && !error && (
              <table className="w-full">
                <thead className="bg-white">
                  <tr className="border-b border-slate-200">
                    {['Tanggal', 'Jam', 'Armada', 'Kode Pesanan', 'Plat Nomor', 'Rute', 'Pelanggan', 'Status Armada', 'Status Jadwal', 'Status Pembayaran', 'Jenis', 'Aksi'].map((h) => (
                      <th key={h} className="text-left text-[11px] font-bold text-slate-400 uppercase tracking-wider px-4 py-4">{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {filtered.map((row, idx) => (
                    <tr key={row.id} className="odd:bg-white even:bg-slate-50 hover:bg-lime-50/40 transition-colors group animate-fade-in-up"
                      style={{ animationDelay: `${idx * 50}ms` }}>
                      <td className="px-4 py-4 text-sm text-slate-600 whitespace-nowrap">
                        <p>{fmtDate(row.tanggal_mulai)}</p>
                        <p className="text-xs text-slate-400">s/d {fmtDate(row.tanggal_selesai)}</p>
                      </td>
                      <td className="px-4 py-4 text-sm text-slate-600 whitespace-nowrap font-mono">{row.jam_berangkat}</td>
                      <td className="px-4 py-4">
                        <div className="flex items-center gap-2">
                          <div className="w-7 h-7 rounded-lg bg-slate-100 flex items-center justify-center group-hover:bg-white transition-colors">
                            <Truck size={13} className="text-slate-500" />
                          </div>
                          <div>
                            <p className="text-sm font-semibold text-slate-800 leading-tight">{row.armada?.nama_armada || '-'}</p>
                            <p className="text-xs text-slate-400">{row.armada?.kode_armada}</p>
                          </div>
                        </div>
                      </td>
                      <td className="px-4 py-4 text-sm font-mono text-slate-700">{row.kode_pesanan || '-'}</td>
                      <td className="px-4 py-4 text-sm font-mono text-slate-700">{row.armada?.plat_nomor || '-'}</td>
                      <td className="px-4 py-4 text-sm text-slate-700">{row.lokasi_asal} → {row.lokasi_tujuan}</td>
                      <td className="px-4 py-4 text-sm text-slate-600">{row.nama_pelanggan}</td>
                      <td className="px-4 py-4"><Badge status={row.armada?.display_status || row.armada?.status_ketersediaan || row.armada?.status_operasional || 'aktif'} /></td>
                      <td className="px-4 py-4">
                        <div className="flex flex-col gap-1 items-start">
                          <Badge status={row.status_jadwal} />
                          {checkPerluDiselesaikan(row) && (
                            <span className="text-[10px] font-bold text-amber-600 bg-amber-100 px-2 py-0.5 rounded-full w-fit">
                              Perlu Diselesaikan
                            </span>
                          )}
                        </div>
                      </td>
                      <td className="px-4 py-4">
                        {row.order ? (
                          <Badge status={row.order.payment_status} type="payment" />
                        ) : (
                          <span className="text-xs text-slate-400 font-medium">-</span>
                        )}
                      </td>
                      <td className="px-4 py-4 text-sm font-medium text-slate-500">
                        {(row.jenis_jadwal === 'Pesanan Mobile' || row.jenis_jadwal === 'Reservasi') ? (
                          <span className="inline-flex items-center px-2 py-1 rounded-md text-xs font-semibold bg-indigo-50 text-indigo-600 border border-indigo-100">
                            {row.jenis_jadwal}
                          </span>
                        ) : (
                          row.jenis_jadwal
                        )}
                      </td>
                      <td className="px-4 py-4">
                        <div className="flex items-center gap-1.5">
                          {(row.status_jadwal === 'terjadwal' || row.status_jadwal === 'Terjadwal') && (
                            <button 
                                onClick={() => openComplete(row)} 
                                disabled={row.order && row.order.payment_status !== 'Lunas'}
                                className={`p-1.5 rounded-lg active:scale-90 transition-all ${
                                  row.order && row.order.payment_status !== 'Lunas' 
                                    ? 'bg-slate-100 text-slate-400 cursor-not-allowed opacity-70' 
                                    : 'bg-emerald-50 text-emerald-600 hover:bg-emerald-100'
                                }`} 
                                title={
                                  row.order
                                    ? row.order.payment_status === 'Menunggu Validasi Pelunasan'
                                      ? 'Pelunasan Menunggu Validasi'
                                      : row.order.payment_status !== 'Lunas'
                                        ? 'Menunggu Pelunasan'
                                        : 'Tandai Selesai'
                                    : 'Tandai Selesai'
                                }>
                                <CheckCircle size={14} />
                            </button>
                          )}
                          <button onClick={() => openDetail(row)} className="p-1.5 rounded-lg bg-blue-50 text-blue-600 hover:bg-blue-100 active:scale-90 transition-all" title="Detail"><Eye size={14} /></button>
                          <button onClick={() => openEdit(row)} className="p-1.5 rounded-lg bg-amber-50 text-amber-600 hover:bg-amber-100 active:scale-90 transition-all" title="Edit"><Edit2 size={14} /></button>
                          <button onClick={() => openHapus(row)} className="p-1.5 rounded-lg bg-red-50 text-red-500 hover:bg-red-100 active:scale-90 transition-all" title="Hapus"><Trash2 size={14} /></button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
            {!loading && !error && filtered.length === 0 && (
              <div className="text-center py-16 text-slate-400">
                <Calendar size={40} className="mx-auto mb-3 opacity-30" />
                <p className="text-sm font-medium">{jadwals.length === 0 ? 'Belum ada data jadwal' : 'Tidak ada jadwal yang sesuai filter'}</p>
                {jadwals.length === 0 && (
                  <button onClick={openTambah} className="mt-4 flex items-center gap-2 mx-auto px-4 py-2 text-xs font-semibold rounded-lg text-slate-900 hover:opacity-90" style={{ backgroundColor: '#a3e635' }}>
                    <Plus size={14} /> Tambah Jadwal Pertama
                  </button>
                )}
              </div>
            )}
          </div>
        </Card>
      </div>

      {/* Modal Tambah */}
      {showTambah && <JadwalFormModal title="Tambah Jadwal" onSubmit={handleTambah} onClose={() => setShowTambah(false)}
        form={form} formErrors={formErrors} handleFormChange={handleFormChange} submitLoading={submitLoading} isEditMode={false} armadaList={armadaList} />}

      {/* Modal Edit */}
      {showEdit && <JadwalFormModal title="Edit Jadwal" onSubmit={handleEdit} onClose={() => setShowEdit(false)}
        form={form} formErrors={formErrors} handleFormChange={handleFormChange} submitLoading={submitLoading} isEditMode={true} armadaList={armadaList} />}

      {/* Modal Detail */}
      {showDetail && selectedJadwal && (
        <ModalOverlay onClose={() => setShowDetail(false)}>
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-md overflow-hidden animate-in fade-in zoom-in-95 duration-200">
            <div className="flex items-center justify-between px-6 py-4 border-b border-slate-100">
              <h3 className="text-lg font-bold text-slate-800">Detail Jadwal</h3>
              <button onClick={() => setShowDetail(false)} className="text-slate-400 hover:text-slate-600"><X size={20} /></button>
            </div>
            <div className="px-6 py-5 max-h-[65vh] overflow-y-auto">
              {/* Armada header */}
              <div className="flex items-center gap-4 mb-5 p-4 bg-slate-50 rounded-xl">
                <div className="w-12 h-12 rounded-xl flex items-center justify-center" style={{ backgroundColor: '#f0fdf4' }}>
                  <Truck size={22} style={{ color: '#16a34a' }} />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-base font-bold text-slate-800">{selectedJadwal.armada?.nama_armada || '-'}</p>
                  <p className="text-xs text-slate-500 font-mono">{selectedJadwal.armada?.plat_nomor} · {selectedJadwal.armada?.kode_armada}</p>
                </div>
                <div className="ml-auto">
                  <Badge status={selectedJadwal.armada?.display_status || selectedJadwal.armada?.status_ketersediaan || selectedJadwal.armada?.status_operasional || 'aktif'} />
                </div>
              </div>
              <div className="space-y-2.5">
                {[
                  { label: 'Jenis Armada', value: selectedJadwal.armada?.jenis_armada },
                  { label: 'Kapasitas', value: `${selectedJadwal.armada?.kapasitas || '-'} ${selectedJadwal.armada?.satuan_kapasitas || ''}` },
                  { label: 'Tanggal', value: `${fmtDate(selectedJadwal.tanggal_mulai)} — ${fmtDate(selectedJadwal.tanggal_selesai)}` },
                  { label: 'Jam Berangkat', value: selectedJadwal.jam_berangkat },
                  { label: 'Rute', value: `${selectedJadwal.lokasi_asal} → ${selectedJadwal.lokasi_tujuan}` },
                  { label: 'Detail Lokasi', value: selectedJadwal.detail_lokasi || '—' },
                  { label: 'Nama Pelanggan', value: selectedJadwal.nama_pelanggan },
                  { label: 'Nomor Telepon', value: selectedJadwal.nomor_telepon },
                  { label: 'Keperluan', value: selectedJadwal.keperluan || '—' },
                  { label: 'Status Jadwal', value: selectedJadwal.status_jadwal, isBadge: true },
                  { label: 'Jenis Jadwal', value: selectedJadwal.jenis_jadwal || 'Pesanan Manual' },
                  { label: 'Keterangan', value: selectedJadwal.keterangan || '—' },
                ].map(({ label, value, isBadge }) => (
                  <div key={label} className="flex justify-between items-start py-2 border-b border-slate-100 last:border-0">
                    <span className="text-xs font-semibold text-slate-500 uppercase tracking-wide shrink-0">{label}</span>
                    {isBadge ? <Badge status={value} /> : <span className="text-sm text-slate-700 font-medium text-right max-w-[60%]">{value}</span>}
                  </div>
                ))}
              </div>
            </div>
            <div className="px-6 py-4 border-t border-slate-100 flex justify-end gap-3">
              <button onClick={() => { setShowDetail(false); openEdit(selectedJadwal); }}
                className="px-5 py-2.5 text-sm font-semibold text-amber-700 bg-amber-50 rounded-full hover:bg-amber-100 transition-colors flex items-center gap-2">
                <Edit2 size={14} /> Edit
              </button>
              <button onClick={() => setShowDetail(false)}
                className="px-5 py-2.5 text-sm font-semibold text-slate-900 rounded-full hover:opacity-90 transition-opacity"
                style={{ backgroundColor: '#a3e635' }}>Tutup</button>
            </div>
          </div>
        </ModalOverlay>
      )}

      {/* Modal Hapus */}
      <ConfirmModal
        isOpen={showHapus && selectedJadwal !== null}
        title="Hapus Jadwal?"
        message={
          <>
            Jadwal <span className="font-semibold text-slate-700">{selectedJadwal?.lokasi_asal} → {selectedJadwal?.lokasi_tujuan}</span> akan dihapus.
            Tindakan ini tidak dapat dibatalkan.
          </>
        }
        confirmText="Hapus"
        cancelText="Batal"
        variant="danger"
        isLoading={submitLoading}
        onConfirm={handleHapus}
        onCancel={() => { setShowHapus(false); setSelectedJadwal(null); }}
      />

      {/* Complete Modal */}
      <ConfirmModal
        isOpen={showComplete}
        onCancel={() => { setShowComplete(false); setSelectedJadwal(null); }}
        onConfirm={handleComplete}
        isLoading={submitLoading}
        title="Tandai Selesai"
        message="Jadwal ini akan ditandai selesai dan status pesanan terkait juga akan berubah menjadi selesai. Lanjutkan?"
        confirmText="Tandai Selesai"
        variant="success"
      />

      {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}

      <style>{`
        @keyframes fadeSlideIn {
          from { opacity: 0; transform: translateY(8px); }
          to   { opacity: 1; transform: translateY(0); }
        }
      `}</style>
    </Layout>
  );
}
