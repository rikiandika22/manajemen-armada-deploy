import { useState, useEffect, useRef } from 'react';
import {
  Search, Plus, Eye, Edit2, Trash2, User, X, Camera,
  Phone, MapPin, ChevronDown, AlertTriangle, CheckCircle,
  Loader2, Hash, FileText, ImageIcon
} from 'lucide-react';
import Layout from '../components/Layout';
import Card from '../components/Card';
import Badge from '../components/Badge';
import ConfirmModal from '../components/ConfirmModal';
import AppSelect from '../components/AppSelect';
import api from '../services/api';

// ─── Helpers ────────────────────────────────────────────────
const STATUS_LABEL = { aktif: 'Aktif', tidak_aktif: 'Tidak Aktif' };
const STATUS_OPTIONS = ['aktif', 'tidak_aktif'];

const EMPTY_FORM = {
  nama: '',
  telepon: '',
  alamat: '',
  status: 'aktif',
  keterangan: '',
};

// ─── AvatarImg (with onError fallback) ──────────────────────
function AvatarImg({ src, nama, size = 'w-9 h-9', textSize = 'text-sm', ringClass = 'ring-2 ring-slate-100' }) {
  const [errored, setErrored] = useState(false);

  if (src && !errored) {
    return (
      <img
        src={src}
        alt={nama}
        className={`${size} rounded-full object-cover flex-shrink-0 ${ringClass}`}
        onError={() => setErrored(true)}
      />
    );
  }

  return (
    <div
      className={`${size} rounded-full flex items-center justify-center text-white ${textSize} font-bold flex-shrink-0`}
      style={{ background: 'linear-gradient(135deg, #0f172a, #334155)' }}
    >
      {nama?.charAt(0) || '?'}
    </div>
  );
}


function FormField({ label, icon: Icon, error, children }) {
  return (
    <div>
      <label className="block text-xs font-semibold text-slate-600 mb-1.5">{label}</label>
      <div className="relative">
        {Icon && <Icon size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />}
        {children}
      </div>
      {error && <p className="text-xs text-red-500 mt-1">{error}</p>}
    </div>
  );
}

// ─── ModalOverlay ───────────────────────────────────────────
function ModalOverlay({ onClose, children }) {
  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/40 backdrop-blur-sm transition-opacity"
      onClick={(e) => { if (e.target === e.currentTarget) onClose(); }}
    >
      {children}
    </div>
  );
}

// ─── Toast ──────────────────────────────────────────────────
function Toast({ message, type, onClose }) {
  useEffect(() => {
    const t = setTimeout(onClose, 3000);
    return () => clearTimeout(t);
  }, [onClose]);

  return (
    <div className="fixed bottom-6 right-6 z-[60] animate-in slide-in-from-bottom-4 fade-in duration-300">
      <div className={`flex items-center gap-3 px-5 py-3 rounded-xl shadow-lg text-sm font-medium ${type === 'success' ? 'bg-emerald-600 text-white' : 'bg-red-600 text-white'}`}>
        {type === 'success' ? <CheckCircle size={16} /> : <AlertTriangle size={16} />}
        {message}
      </div>
    </div>
  );
}

// ─── SopirFormModal ─────────────────────────────────────────
function SopirFormModal({ title, onSubmit, onClose, form, formErrors, handleFormChange, submitLoading, isEditMode, fotoPreview, onFotoChange }) {
  const fileInputRef = useRef(null);
  const [imgError, setImgError] = useState(false);

  return (
    <ModalOverlay onClose={onClose}>
      <div className="bg-white rounded-2xl shadow-xl w-full max-w-md overflow-hidden animate-in fade-in zoom-in-95 duration-200">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-slate-100">
          <h3 className="text-lg font-bold text-slate-800">{title}</h3>
          <button onClick={onClose} className="text-slate-400 hover:text-slate-600 transition-colors">
            <X size={20} />
          </button>
        </div>

        {/* Body */}
        <form onSubmit={onSubmit}>
          <div className="px-6 py-5 space-y-4 max-h-[65vh] overflow-y-auto">
            {/* Kode Sopir readonly saat edit */}
            {isEditMode && (
              <div>
                <label className="block text-xs font-semibold text-slate-600 mb-1.5">Kode Sopir</label>
                <div className="relative">
                  <Hash size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />
                  <input
                    type="text"
                    value={form.kode_sopir || ''}
                    readOnly
                    className="w-full pl-9 pr-4 py-2.5 bg-slate-100 border border-transparent rounded-lg text-sm text-slate-500 font-mono cursor-not-allowed select-none"
                  />
                </div>
              </div>
            )}

            {!isEditMode && (
              <div>
                <label className="block text-xs font-semibold text-slate-600 mb-1.5">Kode Sopir</label>
                <div className="flex items-center gap-2 px-3 py-2.5 bg-slate-50 border border-transparent rounded-lg">
                  <Hash size={15} className="text-slate-400 flex-shrink-0" />
                  <span className="text-xs text-slate-400 italic">Dibuat otomatis oleh sistem</span>
                </div>
              </div>
            )}

            {/* Upload Foto */}
            <div className="flex flex-col items-center justify-center">
              <input
                ref={fileInputRef}
                type="file"
                accept="image/jpeg,image/jpg,image/png,image/webp"
                className="hidden"
                onChange={(e) => { onFotoChange(e); setImgError(false); }}
              />
              <button
                type="button"
                onClick={() => { if (fileInputRef.current) fileInputRef.current.value = ''; fileInputRef.current?.click(); }}
                className="group relative w-20 h-20 rounded-full border-2 border-dashed border-slate-300 bg-slate-50 flex items-center justify-center cursor-pointer hover:bg-slate-100 hover:border-slate-400 transition-colors overflow-hidden"
              >
                {fotoPreview && !imgError ? (
                  <img src={fotoPreview} alt="Preview" className="w-full h-full object-cover rounded-full" onError={() => setImgError(true)} />
                ) : (
                  <Camera size={24} className="text-slate-400 group-hover:text-slate-500 transition-colors" />
                )}
                {/* Overlay on hover */}
                <div className="absolute inset-0 bg-black/30 rounded-full opacity-0 group-hover:opacity-100 flex items-center justify-center transition-opacity">
                  <Camera size={18} className="text-white" />
                </div>
              </button>
              <span className="text-xs text-slate-500 mt-2 font-medium">
                {fotoPreview && !imgError ? 'Klik untuk ganti foto' : 'Unggah Foto Profil'}
              </span>
              <span className="text-[10px] text-slate-400 mt-0.5">Format: JPG, JPEG, PNG, WEBP. Maksimal 2 MB.</span>
              {formErrors.foto && <p className="text-xs text-red-500 mt-1">{formErrors.foto}</p>}
            </div>

            {/* Nama Lengkap */}
            <FormField label="Nama Lengkap" icon={User} error={formErrors.nama}>
              <input
                type="text"
                placeholder="Masukkan nama lengkap"
                value={form.nama}
                onChange={(e) => handleFormChange('nama', e.target.value)}
                className={`w-full pl-9 pr-4 py-2.5 bg-slate-50 border rounded-lg text-sm text-slate-700 placeholder-slate-400 focus:bg-white focus:outline-none transition-colors ${formErrors.nama ? 'border-red-300 focus:border-red-400' : 'border-transparent focus:border-slate-300'}`}
              />
            </FormField>

            {/* No. Telepon */}
            <FormField label="No. Telepon" icon={Phone} error={formErrors.telepon}>
              <input
                type="text"
                placeholder="cth: 081234567890"
                value={form.telepon}
                onChange={(e) => handleFormChange('telepon', e.target.value)}
                className={`w-full pl-9 pr-4 py-2.5 bg-slate-50 border rounded-lg text-sm text-slate-700 placeholder-slate-400 focus:bg-white focus:outline-none transition-colors ${formErrors.telepon ? 'border-red-300 focus:border-red-400' : 'border-transparent focus:border-slate-300'}`}
              />
            </FormField>

            {/* Alamat */}
            <FormField label="Alamat" icon={MapPin} error={formErrors.alamat}>
              <input
                type="text"
                placeholder="Masukkan alamat lengkap"
                value={form.alamat}
                onChange={(e) => handleFormChange('alamat', e.target.value)}
                className={`w-full pl-9 pr-4 py-2.5 bg-slate-50 border rounded-lg text-sm text-slate-700 placeholder-slate-400 focus:bg-white focus:outline-none transition-colors ${formErrors.alamat ? 'border-red-300 focus:border-red-400' : 'border-transparent focus:border-slate-300'}`}
              />
            </FormField>

            {/* Status */}
            <div>
              <label className="block text-xs font-semibold text-slate-600 mb-1.5">Status</label>
              <AppSelect
                options={STATUS_OPTIONS.map(o => ({ value: o, label: STATUS_LABEL[o] || o }))}
                value={form.status}
                onChange={(v) => handleFormChange('status', v)}
                placeholder="Pilih status"
              />
              {formErrors.status && <p className="text-xs text-red-500 mt-1">{formErrors.status}</p>}
            </div>

            {/* Keterangan */}
            <div>
              <label className="block text-xs font-semibold text-slate-600 mb-1.5">Keterangan <span className="text-slate-400 font-normal">(opsional)</span></label>
              <div className="relative">
                <FileText size={16} className="absolute left-3 top-3 text-slate-400" />
                <textarea
                  placeholder="Catatan tambahan..."
                  value={form.keterangan}
                  onChange={(e) => handleFormChange('keterangan', e.target.value)}
                  rows={3}
                  className="w-full pl-9 pr-4 py-2.5 bg-slate-50 border border-transparent rounded-lg text-sm text-slate-700 placeholder-slate-400 focus:bg-white focus:border-slate-300 focus:outline-none transition-colors resize-none"
                />
              </div>
            </div>
          </div>

          {/* Footer */}
          <div className="px-6 py-4 border-t border-slate-100 flex items-center justify-center sm:justify-end gap-3 bg-white">
            <button
              type="button"
              onClick={onClose}
              disabled={submitLoading}
              className="px-6 py-2.5 text-sm font-semibold text-slate-700 bg-white border border-slate-200 rounded-full hover:bg-slate-50 transition-colors w-full sm:w-auto disabled:opacity-50"
            >
              Batal
            </button>
            <button
              type="submit"
              disabled={submitLoading}
              className="flex items-center justify-center gap-2 px-6 py-2.5 text-sm font-semibold text-slate-900 rounded-full hover:opacity-90 transition-opacity shadow-sm w-full sm:w-auto disabled:opacity-70"
              style={{ backgroundColor: '#a3e635' }}
            >
              {submitLoading ? <><Loader2 size={14} className="animate-spin" /> Menyimpan...</> : 'Simpan Data'}
            </button>
          </div>
        </form>
      </div>
    </ModalOverlay>
  );
}

// ─── Main Component ─────────────────────────────────────────
export default function Sopir() {
  // Data
  const [sopirs, setSopirs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // Search
  const [search, setSearch] = useState('');

  // Modals
  const [showTambah, setShowTambah] = useState(false);
  const [showEdit, setShowEdit] = useState(false);
  const [showDetail, setShowDetail] = useState(false);
  const [showHapus, setShowHapus] = useState(false);
  const [selectedSopir, setSelectedSopir] = useState(null);

  // Form
  const [form, setForm] = useState(EMPTY_FORM);
  const [formErrors, setFormErrors] = useState({});
  const [submitLoading, setSubmitLoading] = useState(false);

  // Foto
  const [fotoFile, setFotoFile] = useState(null);
  const [fotoPreview, setFotoPreview] = useState(null);

  // Toast
  const [toast, setToast] = useState(null);

  // Animation
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
    fetchSopirs();
  }, []);

  // ── Fetch ──
  async function fetchSopirs() {
    setLoading(true);
    setError(null);
    try {
      const res = await api.get('/sopirs');
      setSopirs(res.data.data || []);
    } catch (err) {
      setError('Gagal memuat data sopir. Pastikan backend berjalan dan Anda sudah login.');
    } finally {
      setLoading(false);
    }
  }

  // ── Filter ──
  const filtered = sopirs.filter((s) => {
    const q = search.toLowerCase();
    return (
      s.nama.toLowerCase().includes(q) ||
      s.telepon.includes(q) ||
      s.kode_sopir.toLowerCase().includes(q)
    );
  });

  // ── Stats ──
  const stats = {
    aktif: sopirs.filter(s => s.status === 'aktif').length,
    tidak_aktif: sopirs.filter(s => s.status === 'tidak_aktif').length,
  };

  // ── Form handlers ──
  function handleFormChange(field, value) {
    setForm(prev => ({ ...prev, [field]: value }));
    if (formErrors[field]) setFormErrors(prev => ({ ...prev, [field]: '' }));
  }

  function handleFotoChange(e) {
    const file = e.target.files?.[0];
    if (!file) return;

    // Client-side validation
    const validTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
    if (!validTypes.includes(file.type)) {
      setFormErrors(prev => ({ ...prev, foto: 'Format file harus JPG, PNG, atau WEBP' }));
      return;
    }
    if (file.size > 2 * 1024 * 1024) {
      setFormErrors(prev => ({ ...prev, foto: 'Ukuran file maksimal 2 MB' }));
      return;
    }

    // Revoke old blob URL to prevent memory leak
    if (fotoPreview && fotoPreview.startsWith('blob:')) {
      URL.revokeObjectURL(fotoPreview);
    }

    setFotoFile(file);
    setFotoPreview(URL.createObjectURL(file));
    setFormErrors(prev => ({ ...prev, foto: '' }));
  }

  function resetFoto() {
    setFotoFile(null);
    if (fotoPreview && fotoPreview.startsWith('blob:')) {
      URL.revokeObjectURL(fotoPreview);
    }
    setFotoPreview(null);
  }

  function validateForm() {
    const errors = {};
    if (!form.nama.trim()) errors.nama = 'Nama sopir wajib diisi';
    if (!form.telepon.trim()) errors.telepon = 'No. telepon wajib diisi';
    if (!form.status) errors.status = 'Status wajib dipilih';
    return errors;
  }

  function buildFormData() {
    const fd = new FormData();
    fd.append('nama', form.nama);
    fd.append('telepon', form.telepon);
    fd.append('alamat', form.alamat || '');
    fd.append('status', form.status);
    fd.append('keterangan', form.keterangan || '');
    if (fotoFile) fd.append('foto', fotoFile);
    return fd;
  }

  // ── Tambah ──
  function openTambah() {
    setForm(EMPTY_FORM);
    setFormErrors({});
    resetFoto();
    setSelectedSopir(null);
    setShowTambah(true);
  }

  async function handleTambah(e) {
    e.preventDefault();
    const errors = validateForm();
    if (Object.keys(errors).length > 0) { setFormErrors(errors); return; }

    setSubmitLoading(true);
    try {
      await api.post('/sopirs', buildFormData(), {
        headers: { 'Content-Type': undefined },
      });
      setShowTambah(false);
      resetFoto();
      setForm(EMPTY_FORM);
      await fetchSopirs();
      setToast({ message: 'Sopir berhasil ditambahkan!', type: 'success' });
    } catch (err) {
      if (err.response?.status === 422) {
        const serverErrors = err.response.data.errors || {};
        const mapped = {};
        Object.keys(serverErrors).forEach(k => { mapped[k] = serverErrors[k][0]; });
        setFormErrors(mapped);
      } else {
        setToast({ message: 'Gagal menambah sopir. Coba lagi.', type: 'error' });
      }
    } finally {
      setSubmitLoading(false);
    }
  }

  // ── Edit ──
  function openEdit(sopir) {
    setSelectedSopir(sopir);
    setForm({
      kode_sopir: sopir.kode_sopir,
      nama: sopir.nama,
      telepon: sopir.telepon,
      alamat: sopir.alamat || '',
      status: sopir.status,
      keterangan: sopir.keterangan || '',
    });
    setFormErrors({});
    resetFoto();
    // Show existing photo as preview
    if (sopir.foto_url) {
      setFotoPreview(sopir.foto_url);
    }
    setShowEdit(true);
  }

  async function handleEdit(e) {
    e.preventDefault();
    const errors = validateForm();
    if (Object.keys(errors).length > 0) { setFormErrors(errors); return; }

    setSubmitLoading(true);
    try {
      const fd = buildFormData();
      fd.append('_method', 'PUT');
      await api.post(`/sopirs/${selectedSopir.id}`, fd, {
        headers: { 'Content-Type': undefined },
      });
      setShowEdit(false);
      setSelectedSopir(null);
      resetFoto();
      await fetchSopirs();
      setToast({ message: 'Data sopir berhasil diperbarui!', type: 'success' });
    } catch (err) {
      if (err.response?.status === 422) {
        const serverErrors = err.response.data.errors || {};
        const mapped = {};
        Object.keys(serverErrors).forEach(k => { mapped[k] = serverErrors[k][0]; });
        setFormErrors(mapped);
      } else {
        setToast({ message: 'Gagal memperbarui sopir. Coba lagi.', type: 'error' });
      }
    } finally {
      setSubmitLoading(false);
    }
  }

  // ── Detail ──
  function openDetail(sopir) {
    setSelectedSopir(sopir);
    setShowDetail(true);
  }

  // ── Hapus ──
  function openHapus(sopir) {
    setSelectedSopir(sopir);
    setShowHapus(true);
  }

  async function handleHapus() {
    setSubmitLoading(true);
    try {
      await api.delete(`/sopirs/${selectedSopir.id}`);
      setShowHapus(false);
      setSelectedSopir(null);
      await fetchSopirs();
      setToast({ message: 'Sopir berhasil dihapus!', type: 'success' });
    } catch {
      setToast({ message: 'Gagal menghapus sopir. Coba lagi.', type: 'error' });
    } finally {
      setSubmitLoading(false);
    }
  }

  // ── Render ──
  return (
    <Layout>
      {/* Header */}
      <div
        className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6 transition-all duration-500"
        style={{ opacity: mounted ? 1 : 0, transform: mounted ? 'translateY(0)' : 'translateY(-12px)' }}
      >
        <div>
          <h2 className="text-xl font-bold text-slate-800">Data Sopir</h2>
          <p className="text-sm text-slate-500 mt-0.5">Kelola data sopir sebagai data operasional</p>
        </div>
        <button
          onClick={openTambah}
          className="flex items-center gap-2 px-4 py-2.5 rounded-xl text-sm font-semibold text-slate-900 hover:opacity-90 active:scale-95 transition-all duration-150 shadow-sm"
          style={{ backgroundColor: '#a3e635' }}
        >
          <Plus size={16} />
          Tambah Sopir
        </button>
      </div>

      {/* Stat Cards */}
      <div
        className="grid grid-cols-2 gap-4 mb-5 transition-all duration-500 delay-75"
        style={{ opacity: mounted ? 1 : 0, transform: mounted ? 'translateY(0)' : 'translateY(12px)' }}
      >
        <Card className="p-4 hover:shadow-md transition-shadow duration-200">
          <p className="text-2xl font-bold" style={{ color: loading ? '#cbd5e1' : '#16a34a' }}>
            {loading ? '—' : stats.aktif}
          </p>
          <p className="text-sm text-slate-500 mt-0.5">Sopir Aktif</p>
          <div className="mt-2 h-1 rounded-full" style={{ backgroundColor: '#dcfce7' }} />
        </Card>
        <Card className="p-4 hover:shadow-md transition-shadow duration-200">
          <p className="text-2xl font-bold" style={{ color: loading ? '#cbd5e1' : '#64748b' }}>
            {loading ? '—' : stats.tidak_aktif}
          </p>
          <p className="text-sm text-slate-500 mt-0.5">Sopir Tidak Aktif</p>
          <div className="mt-2 h-1 rounded-full" style={{ backgroundColor: '#f1f5f9' }} />
        </Card>
      </div>

      {/* Search */}
      <div
        className="transition-all duration-500 delay-100"
        style={{ opacity: mounted ? 1 : 0, transform: mounted ? 'translateY(0)' : 'translateY(12px)' }}
      >
        <Card className="p-4 mb-5">
          <div className="relative max-w-md">
            <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
            <input
              type="text"
              placeholder="Cari kode, nama, atau nomor telepon sopir..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full pl-9 pr-4 py-2.5 border border-slate-200 rounded-xl text-sm bg-white text-slate-700 placeholder-slate-400 focus:outline-none focus:ring-2 focus:border-transparent transition-shadow"
            />
          </div>
        </Card>
      </div>

      {/* Table */}
      <div
        className="transition-all duration-500 delay-150"
        style={{ opacity: mounted ? 1 : 0, transform: mounted ? 'translateY(0)' : 'translateY(12px)' }}
      >
        <Card>
          <div className="overflow-x-auto">
            {/* Loading state */}
            {loading && (
              <div className="flex flex-col items-center justify-center py-20 text-slate-400">
                <Loader2 size={36} className="animate-spin mb-3" style={{ color: '#a3e635' }} />
                <p className="text-sm font-medium">Memuat data sopir...</p>
              </div>
            )}

            {/* Error state */}
            {!loading && error && (
              <div className="flex flex-col items-center justify-center py-20 text-red-400">
                <AlertTriangle size={40} className="mb-3 opacity-60" />
                <p className="text-sm font-medium text-center max-w-xs">{error}</p>
                <button
                  onClick={fetchSopirs}
                  className="mt-4 px-4 py-2 text-xs font-semibold rounded-lg bg-red-50 text-red-600 hover:bg-red-100 transition-colors"
                >
                  Coba lagi
                </button>
              </div>
            )}

            {/* Table */}
            {!loading && !error && (
              <table className="w-full">
                <thead className="bg-white">
                  <tr className="border-b border-slate-200">
                    {['Kode Sopir', 'Nama Sopir', 'No. Telepon', 'Alamat', 'Status', 'Keterangan', 'Aksi'].map((h) => (
                      <th key={h} className="text-left text-[11px] font-bold text-slate-400 uppercase tracking-wider px-5 py-4">{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {filtered.map((row, idx) => (
                    <tr
                      key={row.id}
                      className="odd:bg-white even:bg-slate-50 hover:bg-lime-50/40 transition-colors group animate-fade-in-up"
                      style={{ animationDelay: `${idx * 50}ms` }}
                    >
                      <td className="px-5 py-4 text-sm font-mono text-slate-500">{row.kode_sopir}</td>
                      <td className="px-5 py-4">
                        <div className="flex items-center gap-2.5">
                          <AvatarImg src={row.foto_url} nama={row.nama} size="w-9 h-9" textSize="text-sm" />
                          <p className="text-sm font-semibold text-slate-800">{row.nama}</p>
                        </div>
                      </td>
                      <td className="px-5 py-4 text-sm text-slate-600">{row.telepon}</td>
                      <td className="px-5 py-4 text-sm text-slate-600 max-w-48">
                        <span className="truncate block">{row.alamat || '—'}</span>
                      </td>
                      <td className="px-5 py-4"><Badge status={STATUS_LABEL[row.status] || row.status} /></td>
                      <td className="px-5 py-4 text-sm text-slate-500 max-w-40">
                        <span className="truncate block">{row.keterangan || '—'}</span>
                      </td>
                      <td className="px-5 py-4">
                        <div className="flex items-center gap-2">
                          <button
                            onClick={() => openDetail(row)}
                            className="p-1.5 rounded-lg bg-blue-50 text-blue-600 hover:bg-blue-100 active:scale-90 transition-all duration-150"
                            title="Lihat Detail"
                          >
                            <Eye size={14} />
                          </button>
                          <button
                            onClick={() => openEdit(row)}
                            className="p-1.5 rounded-lg bg-amber-50 text-amber-600 hover:bg-amber-100 active:scale-90 transition-all duration-150"
                            title="Edit"
                          >
                            <Edit2 size={14} />
                          </button>
                          <button
                            onClick={() => openHapus(row)}
                            className="p-1.5 rounded-lg bg-red-50 text-red-500 hover:bg-red-100 active:scale-90 transition-all duration-150"
                            title="Hapus"
                          >
                            <Trash2 size={14} />
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}

            {/* Empty state */}
            {!loading && !error && filtered.length === 0 && (
              <div className="text-center py-16 text-slate-400">
                <User size={40} className="mx-auto mb-3 opacity-30" />
                <p className="text-sm font-medium">
                  {sopirs.length === 0 ? 'Belum ada data sopir' : 'Tidak ada sopir yang sesuai pencarian'}
                </p>
                {sopirs.length === 0 && (
                  <button
                    onClick={openTambah}
                    className="mt-4 flex items-center gap-2 mx-auto px-4 py-2 text-xs font-semibold rounded-lg text-slate-900 hover:opacity-90 transition-opacity"
                    style={{ backgroundColor: '#a3e635' }}
                  >
                    <Plus size={14} /> Tambah Sopir Pertama
                  </button>
                )}
              </div>
            )}
          </div>
        </Card>
      </div>

      {/* ── Modal Tambah ── */}
      {showTambah && (
        <SopirFormModal
          title="Tambah Data Sopir"
          onSubmit={handleTambah}
          onClose={() => { setShowTambah(false); resetFoto(); }}
          form={form}
          formErrors={formErrors}
          handleFormChange={handleFormChange}
          submitLoading={submitLoading}
          isEditMode={false}
          fotoPreview={fotoPreview}
          onFotoChange={handleFotoChange}
        />
      )}

      {/* ── Modal Edit ── */}
      {showEdit && (
        <SopirFormModal
          title="Edit Data Sopir"
          onSubmit={handleEdit}
          onClose={() => { setShowEdit(false); resetFoto(); }}
          form={form}
          formErrors={formErrors}
          handleFormChange={handleFormChange}
          submitLoading={submitLoading}
          isEditMode={true}
          fotoPreview={fotoPreview}
          onFotoChange={handleFotoChange}
        />
      )}

      {/* ── Modal Detail ── */}
      {showDetail && selectedSopir && (
        <ModalOverlay onClose={() => setShowDetail(false)}>
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-md overflow-hidden animate-in fade-in zoom-in-95 duration-200">
            <div className="flex items-center justify-between px-6 py-4 border-b border-slate-100">
              <h3 className="text-lg font-bold text-slate-800">Detail Sopir</h3>
              <button onClick={() => setShowDetail(false)} className="text-slate-400 hover:text-slate-600 transition-colors">
                <X size={20} />
              </button>
            </div>
            <div className="px-6 py-5">
              {/* Photo & name header */}
              <div className="flex items-center gap-4 mb-6 p-4 bg-slate-50 rounded-xl">
                <AvatarImg src={selectedSopir.foto_url} nama={selectedSopir.nama} size="w-14 h-14" textSize="text-lg" ringClass="ring-2 ring-slate-200" />
                <div>
                  <p className="text-base font-bold text-slate-800">{selectedSopir.nama}</p>
                  <p className="text-sm font-mono text-slate-500">{selectedSopir.kode_sopir}</p>
                </div>
                <div className="ml-auto">
                  <Badge status={STATUS_LABEL[selectedSopir.status] || selectedSopir.status} />
                </div>
              </div>

              {/* Fields */}
              <div className="space-y-3">
                {[
                  { label: 'Kode Sopir', value: selectedSopir.kode_sopir },
                  { label: 'No. Telepon', value: selectedSopir.telepon },
                  { label: 'Alamat', value: selectedSopir.alamat || '—' },
                  { label: 'Status', value: STATUS_LABEL[selectedSopir.status] || selectedSopir.status },
                  { label: 'Keterangan', value: selectedSopir.keterangan || '—' },
                  { label: 'Ditambahkan', value: new Date(selectedSopir.created_at).toLocaleDateString('id-ID', { day: 'numeric', month: 'long', year: 'numeric' }) },
                ].map(({ label, value }) => (
                  <div key={label} className="flex justify-between items-start py-2 border-b border-slate-100 last:border-0">
                    <span className="text-xs font-semibold text-slate-500 uppercase tracking-wide">{label}</span>
                    <span className="text-sm text-slate-700 font-medium text-right max-w-[60%]">{value}</span>
                  </div>
                ))}
              </div>
            </div>
            <div className="px-6 py-4 border-t border-slate-100 flex justify-end gap-3">
              <button
                onClick={() => { setShowDetail(false); openEdit(selectedSopir); }}
                className="px-5 py-2.5 text-sm font-semibold text-amber-700 bg-amber-50 rounded-full hover:bg-amber-100 transition-colors flex items-center gap-2"
              >
                <Edit2 size={14} /> Edit
              </button>
              <button
                onClick={() => setShowDetail(false)}
                className="px-5 py-2.5 text-sm font-semibold text-slate-900 rounded-full hover:opacity-90 transition-opacity"
                style={{ backgroundColor: '#a3e635' }}
              >
                Tutup
              </button>
            </div>
          </div>
        </ModalOverlay>
      )}

      {/* ── Modal Hapus ── */}
      <ConfirmModal
        isOpen={showHapus && selectedSopir !== null}
        title="Hapus Sopir?"
        message={
          <>
            Anda akan menghapus <span className="font-semibold text-slate-700">{selectedSopir?.nama}</span>{' '}
            <span className="font-mono text-slate-500">({selectedSopir?.kode_sopir})</span>.
            Tindakan ini tidak dapat dibatalkan.
          </>
        }
        confirmText="Hapus"
        cancelText="Batal"
        variant="danger"
        isLoading={submitLoading}
        onConfirm={handleHapus}
        onCancel={() => setShowHapus(false)}
      />

      {/* ── Toast ── */}
      {toast && (
        <Toast
          message={toast.message}
          type={toast.type}
          onClose={() => setToast(null)}
        />
      )}

      {/* ── Animation CSS ── */}
      <style>{`
        @keyframes fadeSlideIn {
          from { opacity: 0; transform: translateY(8px); }
          to   { opacity: 1; transform: translateY(0); }
        }
      `}</style>
    </Layout>
  );
}
