import { useState, useEffect, useRef } from 'react';
import { useSearchParams } from 'react-router-dom';
import {
  Search, Plus, Filter, Eye, Edit2, Trash2, Truck,
  X, ChevronDown, AlertTriangle, CheckCircle, Loader2,
  Hash, Tag, CreditCard, Package, Weight, Settings2, FileText
} from 'lucide-react';
import Layout from '../components/Layout';
import Card from '../components/Card';
import Badge from '../components/Badge';
import ConfirmModal from '../components/ConfirmModal';
import AppSelect from '../components/AppSelect';
import { formatRupiah } from '../utils/format';
import api from '../services/api';

// ─── Helpers ────────────────────────────────────────────────
const STATUS_LABEL = {
  tersedia: 'Tersedia',
  dipesan: 'Dipesan',
  dalam_perjalanan: 'Dalam Perjalanan',
  perawatan: 'Perawatan',
  aktif: 'Aktif',
  tidak_aktif: 'Tidak Aktif',
};

const JENIS_OPTIONS = ['Bus Medium', 'Elf Long', 'Truk CDD Bak Terbuka'];
const SATUAN_OPTIONS = ['seat', 'Ton'];
const STATUS_OPTIONS = ['Tersedia', 'Perawatan', 'Tidak Aktif'];

const EMPTY_FORM = {
  nama_armada: '',
  plat_nomor: '',
  jenis_armada: '',
  kapasitas: '',
  satuan_kapasitas: '',
  status_operasional: 'Tersedia',
  harga_sewa: '',
  keterangan: '',
};

// ─── Toast Notification ──────────────────────────────────────
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

// ─── Modal Overlay ───────────────────────────────────────────
function ModalOverlay({ onClose, children }) {
  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/40 backdrop-blur-sm"
      onClick={(e) => { if (e.target === e.currentTarget) onClose(); }}
    >
      {children}
    </div>
  );
}

// ─── Form Fields Component ───────────────────────────────────
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

// ─── Armada Form Modal (top-level agar tidak unmount saat re-render) ─────────
function ArmadaFormModal({ 
  title, onSubmit, onClose, form, formErrors, handleFormChange, 
  submitLoading, isEditMode, fotoFiles, setFotoFiles, existingImages, 
  setExistingImages, onSetPrimary, onDeleteExistingImage, onAddNewImage, setToast
}) {
  const fileInputRef = useRef(null);
  
  function handleFileSelect(e) {
    const files = Array.from(e.target.files);
    if (!files.length) return;
    
    const currentTotal = (existingImages?.length || 0) + fotoFiles.length;
    if (currentTotal + files.length > 5) {
      setToast({ message: 'Maksimal 5 foto per armada.', type: 'error' });
      return;
    }
    
    const validFiles = files.filter(f => {
      const validTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
      if (!validTypes.includes(f.type)) {
        setToast({ message: `${f.name} format tidak valid. Harus JPG, PNG, atau WEBP.`, type: 'error' });
        return false;
      }
      if (f.size > 2 * 1024 * 1024) {
        setToast({ message: `${f.name} terlalu besar. Maksimal 2MB.`, type: 'error' });
        return false;
      }
      return true;
    });
    
    if (isEditMode) {
      // In edit mode, we upload immediately
      validFiles.forEach(f => onAddNewImage(f));
    } else {
      // In add mode, we accumulate
      const newPreviews = validFiles.map(f => ({
        file: f,
        preview: URL.createObjectURL(f)
      }));
      setFotoFiles(prev => [...prev, ...newPreviews]);
    }
    
    if (fileInputRef.current) fileInputRef.current.value = '';
  }

  function removePreview(index) {
    const toRemove = fotoFiles[index];
    URL.revokeObjectURL(toRemove.preview);
    setFotoFiles(prev => prev.filter((_, i) => i !== index));
  }

  const isTruk = form.jenis_armada && form.jenis_armada.toLowerCase().includes('truk');
  const kapasitasLabel = isTruk ? 'Kapasitas Muatan' : (form.jenis_armada ? 'Kapasitas Penumpang' : 'Kapasitas');
  const placeholderKapasitas = isTruk ? 'cth: 4 atau 7.5' : 'cth: 30';
  const stepKapasitas = isTruk ? '0.1' : '1';

  return (
    <ModalOverlay onClose={onClose}>
      <div className="bg-white rounded-2xl shadow-xl w-full max-w-lg overflow-hidden animate-in fade-in zoom-in-95 duration-200">
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
            {/* Kode Armada (otomatis saat tambah, readonly saat edit) + Nama */}
            {isEditMode ? (
              <div className="grid grid-cols-2 gap-4">
                {/* Kode — readonly di edit */}
                <div>
                  <label className="block text-xs font-semibold text-slate-600 mb-1.5">Kode Armada</label>
                  <div className="relative">
                    <Hash size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />
                    <input
                      type="text"
                      value={form.kode_armada || ''}
                      readOnly
                      className="w-full pl-9 pr-4 py-2.5 bg-slate-100 border border-transparent rounded-lg text-sm text-slate-500 font-mono cursor-not-allowed select-none"
                    />
                  </div>
                </div>
                <FormField label="Nama Armada" icon={Tag} error={formErrors.nama_armada}>
                  <input
                    type="text"
                    placeholder="cth: Bus Medium 01"
                    value={form.nama_armada}
                    onChange={(e) => handleFormChange('nama_armada', e.target.value)}
                    className={`w-full pl-9 pr-4 py-2.5 bg-slate-50 border rounded-lg text-sm text-slate-700 placeholder-slate-400 focus:bg-white focus:outline-none transition-colors ${formErrors.nama_armada ? 'border-red-300 focus:border-red-400' : 'border-transparent focus:border-slate-300'}`}
                  />
                </FormField>
              </div>
            ) : (
              <div className="grid grid-cols-2 gap-4">
                {/* Kode — otomatis di tambah */}
                <div>
                  <label className="block text-xs font-semibold text-slate-600 mb-1.5">Kode Armada</label>
                  <div className="flex items-center gap-2 px-3 py-2.5 bg-slate-50 border border-transparent rounded-lg">
                    <Hash size={15} className="text-slate-400 flex-shrink-0" />
                    <span className="text-xs text-slate-400 italic">Dibuat otomatis oleh sistem</span>
                  </div>
                </div>
                <FormField label="Nama Armada" icon={Tag} error={formErrors.nama_armada}>
                  <input
                    type="text"
                    placeholder="cth: Bus Medium 01"
                    value={form.nama_armada}
                    onChange={(e) => handleFormChange('nama_armada', e.target.value)}
                    className={`w-full pl-9 pr-4 py-2.5 bg-slate-50 border rounded-lg text-sm text-slate-700 placeholder-slate-400 focus:bg-white focus:outline-none transition-colors ${formErrors.nama_armada ? 'border-red-300 focus:border-red-400' : 'border-transparent focus:border-slate-300'}`}
                  />
                </FormField>
              </div>
            )}

            {/* Plat Nomor */}
            <FormField label="Plat Nomor" icon={CreditCard} error={formErrors.plat_nomor}>
              <input
                type="text"
                placeholder="cth: H 1234 AA"
                value={form.plat_nomor}
                onChange={(e) => handleFormChange('plat_nomor', e.target.value)}
                className={`w-full pl-9 pr-4 py-2.5 bg-slate-50 border rounded-lg text-sm text-slate-700 placeholder-slate-400 focus:bg-white focus:outline-none transition-colors ${formErrors.plat_nomor ? 'border-red-300 focus:border-red-400' : 'border-transparent focus:border-slate-300'}`}
              />
            </FormField>

            {/* Jenis Armada */}
            <div>
              <label className="block text-xs font-semibold text-slate-600 mb-1.5">Jenis Armada</label>
              <AppSelect
                options={JENIS_OPTIONS.map(o => ({ value: o, label: o }))}
                value={form.jenis_armada}
                onChange={(v) => {
                  handleFormChange('jenis_armada', v);
                  if (v.toLowerCase().includes('truk')) {
                    handleFormChange('satuan_kapasitas', 'Ton');
                  } else {
                    handleFormChange('satuan_kapasitas', 'seat');
                  }
                }}
                placeholder="Pilih jenis armada"
              />
              {formErrors.jenis_armada && <p className="text-xs text-red-500 mt-1">{formErrors.jenis_armada}</p>}
            </div>

            {/* Row 2: Kapasitas & Satuan */}
            <div className="grid grid-cols-2 gap-4">
              <FormField label={kapasitasLabel} icon={Package} error={formErrors.kapasitas}>
                <input
                  type="number"
                  placeholder={placeholderKapasitas}
                  min={isTruk ? "0" : "1"}
                  step={stepKapasitas}
                  value={form.kapasitas}
                  onChange={(e) => handleFormChange('kapasitas', e.target.value)}
                  className={`w-full pl-9 pr-4 py-2.5 bg-slate-50 border rounded-lg text-sm text-slate-700 placeholder-slate-400 focus:bg-white focus:outline-none transition-colors ${formErrors.kapasitas ? 'border-red-300 focus:border-red-400' : 'border-transparent focus:border-slate-300'}`}
                />
              </FormField>
              <div>
                <label className="block text-xs font-semibold text-slate-600 mb-1.5">Satuan Kapasitas</label>
                <AppSelect
                  options={(isTruk ? ['Ton'] : ['seat']).map(o => ({ value: o, label: o }))}
                  value={form.satuan_kapasitas}
                  onChange={(v) => handleFormChange('satuan_kapasitas', v)}
                  placeholder="Pilih satuan"
                />
                {formErrors.satuan_kapasitas && <p className="text-xs text-red-500 mt-1">{formErrors.satuan_kapasitas}</p>}
              </div>
            </div>

            {/* Status Operasional */}
            <div>
              <label className="block text-xs font-semibold text-slate-600 mb-1.5">Status Operasional</label>
              <AppSelect
                options={STATUS_OPTIONS.map(o => ({ value: o, label: o }))}
                value={form.status_operasional}
                onChange={(v) => handleFormChange('status_operasional', v)}
                placeholder="Pilih status"
              />
              {formErrors.status_operasional && <p className="text-xs text-red-500 mt-1">{formErrors.status_operasional}</p>}
            </div>

            {/* Foto Armada */}
            <div>
              <label className="block text-xs font-semibold text-slate-600 mb-1.5">Foto Armada (Max 5)</label>
              
              <div className="grid grid-cols-3 sm:grid-cols-5 gap-3 mb-3">
                {/* Existing Images */}
                {existingImages?.map((img) => (
                  <div key={img.id} className="relative aspect-square rounded-lg border border-slate-200 overflow-hidden group">
                    <img src={img.url} alt="Armada" className="w-full h-full object-cover" />
                    
                    {img.is_primary && (
                      <div className="absolute top-1 left-1 bg-emerald-500 text-white text-[9px] font-bold px-1.5 py-0.5 rounded shadow">
                        UTAMA
                      </div>
                    )}
                    
                    <div className="absolute inset-0 bg-black/50 opacity-0 group-hover:opacity-100 transition-opacity flex flex-col items-center justify-center gap-1.5">
                      {!img.is_primary && (
                        <button 
                          type="button" 
                          onClick={() => onSetPrimary(img.id)}
                          className="text-xs bg-white text-slate-800 px-2 py-1 rounded shadow hover:bg-slate-100"
                        >
                          Jadikan Utama
                        </button>
                      )}
                      <button 
                        type="button" 
                        onClick={() => onDeleteExistingImage(img.id)}
                        className="p-1.5 bg-red-500 text-white rounded-full hover:bg-red-600 shadow"
                      >
                        <Trash2 size={12} />
                      </button>
                    </div>
                  </div>
                ))}

                {/* New Files Preview (For Add Mode) */}
                {!isEditMode && fotoFiles.map((fileObj, idx) => (
                  <div key={idx} className="relative aspect-square rounded-lg border border-slate-200 overflow-hidden group">
                    <img src={fileObj.preview} alt="Preview" className="w-full h-full object-cover" />
                    
                    {idx === 0 && (
                      <div className="absolute top-1 left-1 bg-emerald-500 text-white text-[9px] font-bold px-1.5 py-0.5 rounded shadow">
                        UTAMA
                      </div>
                    )}

                    <button 
                      type="button" 
                      onClick={() => removePreview(idx)}
                      className="absolute top-1 right-1 p-1 bg-red-500 text-white rounded-full shadow opacity-0 group-hover:opacity-100 transition-opacity"
                    >
                      <X size={10} />
                    </button>
                  </div>
                ))}

                {/* Upload Button */}
                {((existingImages?.length || 0) + fotoFiles.length) < 5 && (
                  <button
                    type="button"
                    onClick={() => fileInputRef.current?.click()}
                    className="aspect-square flex flex-col items-center justify-center border-2 border-dashed border-slate-300 rounded-lg text-slate-400 hover:border-slate-400 hover:text-slate-500 bg-slate-50 transition-colors"
                  >
                    <Plus size={20} className="mb-1" />
                    <span className="text-[10px] font-medium">Tambah</span>
                  </button>
                )}
              </div>
              
              <input
                ref={fileInputRef}
                type="file"
                multiple
                accept="image/jpeg,image/jpg,image/png,image/webp"
                className="hidden"
                onChange={handleFileSelect}
              />
              <p className="text-[10px] text-slate-400">Format: JPG, PNG, WEBP. Maks 2MB per foto.</p>
              {formErrors.images && <p className="text-xs text-red-500 mt-1">{formErrors.images}</p>}
            </div>

            {/* Row 3: Harga Sewa */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <FormField label="Harga Sewa (Rp)" icon={CreditCard} error={formErrors.harga_sewa}>
                <input
                  type="number"
                  placeholder="cth: 2500000"
                  min="0"
                  value={form.harga_sewa}
                  onChange={(e) => handleFormChange('harga_sewa', e.target.value)}
                  className={`w-full pl-9 pr-4 py-2.5 bg-slate-50 border rounded-lg text-sm text-slate-700 placeholder-slate-400 focus:bg-white focus:outline-none transition-colors ${formErrors.harga_sewa ? 'border-red-300 focus:border-red-400' : 'border-transparent focus:border-slate-300'}`}
                />
              </FormField>
            </div>

            {/* Keterangan */}
            <div>
              <label className="block text-xs font-semibold text-slate-600 mb-1.5">Keterangan <span className="text-slate-400 font-normal">(opsional)</span></label>
              <div className="relative">
                <FileText size={16} className="absolute left-3 top-3 text-slate-400" />
                <textarea
                  placeholder="Catatan kondisi atau informasi tambahan..."
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
              {submitLoading ? <><Loader2 size={15} className="animate-spin" /> Menyimpan...</> : 'Simpan Data'}
            </button>
          </div>
        </form>
      </div>
    </ModalOverlay>
  );
}

// ─── Main Component ──────────────────────────────────────────
export default function Armada() {
  // Data state
  const [armadas, setArmadas] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // Filter state
  const [searchParams] = useSearchParams();
  const initSearch = searchParams.get('search') || '';
  const [search, setSearch] = useState(initSearch);
  const [filterJenis, setFilterJenis] = useState('Semua');
  const [filterStatus, setFilterStatus] = useState('Semua');

  // Modal state
  const [showTambah, setShowTambah] = useState(false);
  const [showEdit, setShowEdit] = useState(false);
  const [showDetail, setShowDetail] = useState(false);
  const [showHapus, setShowHapus] = useState(false);
  const [selectedArmada, setSelectedArmada] = useState(null);

  // Form state
  const [form, setForm] = useState(EMPTY_FORM);
  const [formErrors, setFormErrors] = useState({});
  const [submitLoading, setSubmitLoading] = useState(false);

  // Toast
  const [toast, setToast] = useState(null);

  // Foto state
  const [fotoFiles, setFotoFiles] = useState([]); // for Add mode
  const [existingImages, setExistingImages] = useState([]); // for Edit mode

  // Animation
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
    fetchArmadas();
  }, []);

  // ── Fetch ──
  async function fetchArmadas() {
    setLoading(true);
    setError(null);
    try {
      const res = await api.get('/armadas');
      setArmadas(res.data.data || []);
    } catch (err) {
      setError('Gagal memuat data armada. Pastikan backend berjalan dan Anda sudah login.');
    } finally {
      setLoading(false);
    }
  }

  // ── Filter ──
  const jenisOptions = ['Semua', ...JENIS_OPTIONS];
  const statusOptions = ['Semua', ...STATUS_OPTIONS];

  const filtered = armadas.filter((a) => {
    const matchSearch =
      a.plat_nomor.toLowerCase().includes(search.toLowerCase()) ||
      a.jenis_armada.toLowerCase().includes(search.toLowerCase()) ||
      a.kode_armada.toLowerCase().includes(search.toLowerCase()) ||
      a.nama_armada.toLowerCase().includes(search.toLowerCase());
    const matchJenis = filterJenis === 'Semua' || a.jenis_armada === filterJenis;
    const matchStatus = filterStatus === 'Semua' || a.status_operasional === filterStatus;
    return matchSearch && matchJenis && matchStatus;
  });



  // ── Form handlers ──
  function handleFormChange(field, value) {
    setForm(prev => ({ ...prev, [field]: value }));
    if (formErrors[field]) setFormErrors(prev => ({ ...prev, [field]: '' }));
  }

  function validateForm() {
    const errors = {};
    if (!form.nama_armada.trim()) errors.nama_armada = 'Nama armada wajib diisi';
    if (!form.plat_nomor.trim()) errors.plat_nomor = 'Plat nomor wajib diisi';
    if (!form.jenis_armada) errors.jenis_armada = 'Jenis armada wajib dipilih';
    
    if (!form.kapasitas || isNaN(form.kapasitas) || Number(form.kapasitas) <= 0) {
      errors.kapasitas = form.satuan_kapasitas?.toLowerCase() === 'seat' 
        ? 'Kapasitas penumpang harus berupa angka bulat lebih dari 0'
        : 'Kapasitas muatan harus berupa angka lebih dari 0';
    } else if (form.satuan_kapasitas?.toLowerCase() === 'seat' && !Number.isInteger(Number(form.kapasitas))) {
      errors.kapasitas = 'Kapasitas penumpang harus berupa angka bulat.';
    }

    if (!form.satuan_kapasitas) errors.satuan_kapasitas = 'Satuan kapasitas wajib dipilih';
    if (!form.status_operasional) errors.status_operasional = 'Status operasional wajib dipilih';
    if (form.harga_sewa && isNaN(form.harga_sewa)) errors.harga_sewa = 'Harga sewa harus angka';
    return errors;
  }

  // ── Tambah ──
  function openTambah() {
    setForm(EMPTY_FORM);
    setFormErrors({});
    setFotoFiles([]);
    setExistingImages([]);
    setShowTambah(true);
  }

  async function handleTambah(e) {
    e.preventDefault();
    const errors = validateForm();
    if (Object.keys(errors).length > 0) { setFormErrors(errors); return; }

    setSubmitLoading(true);
    try {
      const fd = new FormData();
      Object.keys(form).forEach(key => {
        if (key !== 'kode_armada') {
          if (key === 'kapasitas' || key === 'harga_sewa') {
            fd.append(key, form[key] ? Number(form[key]) : '');
          } else {
            fd.append(key, form[key]);
          }
        }
      });
      
      fotoFiles.forEach((fileObj) => {
        fd.append('images[]', fileObj.file);
      });

      await api.post('/armadas', fd, {
        headers: { 'Content-Type': 'multipart/form-data' }
      });
      
      setShowTambah(false);
      setForm(EMPTY_FORM);
      setFotoFiles([]);
      await fetchArmadas();
      setToast({ message: 'Armada berhasil ditambahkan!', type: 'success' });
    } catch (err) {
      if (err.response?.status === 422) {
        const serverErrors = err.response.data.errors || {};
        const mapped = {};
        Object.keys(serverErrors).forEach(k => { mapped[k] = serverErrors[k][0]; });
        setFormErrors(mapped);
      } else {
        setToast({ message: err.response?.data?.message || 'Gagal menambah armada. Coba lagi.', type: 'error' });
      }
    } finally {
      setSubmitLoading(false);
    }
  }

  // ── Edit ──
  function openEdit(armada) {
    setSelectedArmada(armada);
    
    // Normalize status just in case backend data is old
    const normalizeStatus = (s) => {
      const lower = String(s || '').toLowerCase();
      if (lower === 'aktif' || lower === 'tersedia') return 'Tersedia';
      if (lower === 'perawatan') return 'Perawatan';
      if (lower === 'tidak_aktif' || lower === 'tidak aktif') return 'Tidak Aktif';
      return 'Tersedia';
    };

    setForm({
      kode_armada: armada.kode_armada,  // untuk tampilan readonly
      nama_armada: armada.nama_armada,
      plat_nomor: armada.plat_nomor,
      jenis_armada: armada.jenis_armada,
      kapasitas: String(armada.kapasitas),
      satuan_kapasitas: armada.satuan_kapasitas,
      status_operasional: normalizeStatus(armada.status_operasional),
      harga_sewa: armada.harga_sewa ? String(armada.harga_sewa) : '',
      keterangan: armada.keterangan || '',
    });
    setFormErrors({});
    setExistingImages(armada.images || []);
    setFotoFiles([]);
    setShowEdit(true);
  }

  async function handleEdit(e) {
    e.preventDefault();
    const errors = validateForm();
    if (Object.keys(errors).length > 0) { setFormErrors(errors); return; }

    setSubmitLoading(true);
    try {
      const { kode_armada, ...payload } = form;
      await api.put(`/armadas/${selectedArmada.id}`, { 
        ...payload, 
        kapasitas: Number(form.kapasitas),
        harga_sewa: form.harga_sewa ? Number(form.harga_sewa) : null
      });
      setShowEdit(false);
      setSelectedArmada(null);
      await fetchArmadas();
      setToast({ message: 'Data armada berhasil diperbarui!', type: 'success' });
    } catch (err) {
      if (err.response?.status === 422) {
        const serverErrors = err.response.data.errors || {};
        const mapped = {};
        Object.keys(serverErrors).forEach(k => { mapped[k] = serverErrors[k][0]; });
        setFormErrors(mapped);
      } else {
        setToast({ message: 'Gagal memperbarui armada. Coba lagi.', type: 'error' });
      }
    } finally {
      setSubmitLoading(false);
    }
  }

  // ── API for Images in Edit Mode ──
  async function onSetPrimary(imageId) {
    try {
      await api.put(`/armadas/images/${imageId}/set-primary`);
      setExistingImages(prev => prev.map(img => ({
        ...img,
        is_primary: img.id === imageId
      })));
      setToast({ message: 'Foto utama diperbarui.', type: 'success' });
    } catch {
      setToast({ message: 'Gagal mengubah foto utama.', type: 'error' });
    }
  }

  async function onDeleteExistingImage(imageId) {
    try {
      await api.delete(`/armadas/images/${imageId}`);
      setExistingImages(prev => {
        const updated = prev.filter(img => img.id !== imageId);
        // Automatically make the first one primary if the primary was deleted
        const wasPrimary = prev.find(img => img.id === imageId)?.is_primary;
        if (wasPrimary && updated.length > 0) {
          updated[0].is_primary = true;
        }
        return updated;
      });
      setToast({ message: 'Foto dihapus.', type: 'success' });
    } catch {
      setToast({ message: 'Gagal menghapus foto.', type: 'error' });
    }
  }

  async function onAddNewImage(file) {
    try {
      const fd = new FormData();
      fd.append('image', file);
      const res = await api.post(`/armadas/${selectedArmada.id}/images`, fd, {
        headers: { 'Content-Type': 'multipart/form-data' }
      });
      const newImage = {
        id: res.data.data.id,
        url: res.data.data.url,
        is_primary: res.data.data.is_primary
      };
      setExistingImages(prev => [...prev, newImage]);
      setToast({ message: 'Foto berhasil diunggah.', type: 'success' });
    } catch (err) {
      setToast({ message: err.response?.data?.message || 'Gagal mengunggah foto.', type: 'error' });
    }
  }

  // ── Detail ──
  function openDetail(armada) {
    setSelectedArmada(armada);
    setShowDetail(true);
  }

  // ── Hapus ──
  function openHapus(armada) {
    setSelectedArmada(armada);
    setShowHapus(true);
  }

  async function handleHapus() {
    setSubmitLoading(true);
    try {
      await api.delete(`/armadas/${selectedArmada.id}`);
      setShowHapus(false);
      setSelectedArmada(null);
      await fetchArmadas();
      setToast({ message: 'Armada berhasil dihapus.', type: 'success' });
    } catch {
      setToast({ message: 'Gagal menghapus armada. Coba lagi.', type: 'error' });
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
          <h2 className="text-xl font-bold text-slate-800">Data Armada</h2>
          <p className="text-sm text-slate-500 mt-0.5">Kelola semua unit armada Sumber Agung Trans</p>
        </div>
        <button
          onClick={openTambah}
          className="flex items-center gap-2 px-4 py-2.5 rounded-xl text-sm font-semibold text-slate-900 hover:opacity-90 active:scale-95 transition-all duration-150 shadow-sm"
          style={{ backgroundColor: '#a3e635' }}
        >
          <Plus size={16} />
          Tambah Armada
        </button>
      </div>



      {/* Filters */}
      <div
        className="transition-all duration-500 delay-100"
        style={{ opacity: mounted ? 1 : 0, transform: mounted ? 'translateY(0)' : 'translateY(12px)' }}
      >
        <Card className="p-4 mb-5">
          <div className="flex flex-wrap gap-3 items-center">
            {/* Search */}
            <div className="relative flex-1 min-w-52">
              <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
              <input
                type="text"
                placeholder="Cari kode, nama, plat, atau jenis armada..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="w-full pl-9 pr-4 py-2.5 border border-slate-200 rounded-xl text-sm bg-white text-slate-700 placeholder-slate-400 focus:outline-none focus:ring-2 focus:border-transparent transition-shadow"
              />
            </div>
            {/* Filter Jenis */}
            <div className="flex items-center gap-2">
              <Filter size={15} className="text-slate-400" />
              <AppSelect
                value={filterJenis}
                onChange={setFilterJenis}
                options={jenisOptions.map(o => ({ value: o, label: o }))}
                className="w-full md:w-auto md:min-w-[160px]"
              />
            </div>
            {/* Filter Status */}
            <AppSelect
              value={filterStatus}
              onChange={setFilterStatus}
              options={statusOptions.map(o => ({ value: o, label: STATUS_LABEL[o] || o }))}
              className="w-full md:w-auto md:min-w-[160px]"
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
                <p className="text-sm font-medium">Memuat data armada...</p>
              </div>
            )}

            {/* Error state */}
            {!loading && error && (
              <div className="flex flex-col items-center justify-center py-20 text-red-400">
                <AlertTriangle size={40} className="mb-3 opacity-60" />
                <p className="text-sm font-medium text-center max-w-xs">{error}</p>
                <button
                  onClick={fetchArmadas}
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
                    {['Kode', 'Nama / Plat Nomor', 'Jenis Kendaraan', 'Kapasitas', 'Status', 'Keterangan', 'Aksi'].map((h) => (
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
                      <td className="px-5 py-4 text-sm font-mono text-slate-500">{row.kode_armada}</td>
                      <td className="px-5 py-4">
                        <p className="text-sm font-semibold text-slate-800">{row.nama_armada}</p>
                        <p className="text-xs text-slate-400 mt-0.5 font-mono">{row.plat_nomor}</p>
                      </td>
                      <td className="px-5 py-4">
                        <div className="flex items-center gap-2">
                          <div className="w-8 h-8 rounded-lg bg-slate-100 flex items-center justify-center group-hover:bg-white transition-colors">
                            <Truck size={14} className="text-slate-500" />
                          </div>
                          <span className="text-sm text-slate-700">{row.jenis_armada}</span>
                        </div>
                      </td>
                      <td className="px-5 py-4 text-sm text-slate-600">
                        {row.kapasitas} <span className="text-slate-400">{row.satuan_kapasitas}</span>
                      </td>
                      <td className="px-5 py-4">
                        <Badge status={row.status_ketersediaan || row.status_operasional} />
                      </td>
                      <td className="px-5 py-4 text-sm text-slate-500 max-w-48">
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
                <Truck size={40} className="mx-auto mb-3 opacity-30" />
                <p className="text-sm font-medium">
                  {armadas.length === 0 ? 'Belum ada data armada' : 'Tidak ada armada yang sesuai filter'}
                </p>
                {armadas.length === 0 && (
                  <button
                    onClick={openTambah}
                    className="mt-4 flex items-center gap-2 mx-auto px-4 py-2 text-xs font-semibold rounded-lg text-slate-900 hover:opacity-90 transition-opacity"
                    style={{ backgroundColor: '#a3e635' }}
                  >
                    <Plus size={14} /> Tambah Armada Pertama
                  </button>
                )}
              </div>
            )}
          </div>
        </Card>
      </div>

      {/* ── Modal Tambah ── */}
      {showTambah && (
        <ArmadaFormModal
          title="Tambah Data Armada"
          onSubmit={handleTambah}
          onClose={() => setShowTambah(false)}
          form={form}
          formErrors={formErrors}
          handleFormChange={handleFormChange}
          submitLoading={submitLoading}
          isEditMode={false}
          fotoFiles={fotoFiles}
          setFotoFiles={setFotoFiles}
          existingImages={existingImages}
          setExistingImages={setExistingImages}
          onSetPrimary={onSetPrimary}
          onDeleteExistingImage={onDeleteExistingImage}
          onAddNewImage={onAddNewImage}
        />
      )}

      {/* ── Modal Edit ── */}
      {showEdit && (
        <ArmadaFormModal
          title="Edit Data Armada"
          onSubmit={handleEdit}
          onClose={() => setShowEdit(false)}
          form={form}
          formErrors={formErrors}
          handleFormChange={handleFormChange}
          submitLoading={submitLoading}
          isEditMode={true}
          fotoFiles={fotoFiles}
          setFotoFiles={setFotoFiles}
          existingImages={existingImages}
          setExistingImages={setExistingImages}
          onSetPrimary={onSetPrimary}
          onDeleteExistingImage={onDeleteExistingImage}
          onAddNewImage={onAddNewImage}
        />
      )}

      {/* ── Modal Detail ── */}
      {showDetail && selectedArmada && (
        <ModalOverlay onClose={() => setShowDetail(false)}>
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-md overflow-hidden animate-in fade-in zoom-in-95 duration-200">
            <div className="flex items-center justify-between px-6 py-4 border-b border-slate-100">
              <h3 className="text-lg font-bold text-slate-800">Detail Armada</h3>
              <button onClick={() => setShowDetail(false)} className="text-slate-400 hover:text-slate-600 transition-colors">
                <X size={20} />
              </button>
            </div>
            <div className="px-6 py-5">
              {/* Icon header */}
              <div className="flex items-center gap-4 mb-6 p-4 bg-slate-50 rounded-xl">
                <div className="w-12 h-12 rounded-xl flex items-center justify-center" style={{ backgroundColor: '#f0fdf4' }}>
                  <Truck size={22} style={{ color: '#16a34a' }} />
                </div>
                <div>
                  <p className="text-base font-bold text-slate-800">{selectedArmada.nama_armada}</p>
                  <p className="text-sm font-mono text-slate-500">{selectedArmada.plat_nomor}</p>
                </div>
                <div className="ml-auto">
                  <Badge status={selectedArmada.status_ketersediaan || selectedArmada.status_operasional} />
                </div>
              </div>

              {/* Fields */}
              <div className="space-y-3">
                {[
                  { label: 'Kode Armada', value: selectedArmada.kode_armada },
                  { label: 'Jenis Kendaraan', value: selectedArmada.jenis_armada },
                  { label: 'Kapasitas', value: `${selectedArmada.kapasitas} ${selectedArmada.satuan_kapasitas}` },
                  { label: 'Keterangan', value: selectedArmada.keterangan || '—' },
                  { label: 'Ditambahkan', value: new Date(selectedArmada.created_at).toLocaleDateString('id-ID', { day: 'numeric', month: 'long', year: 'numeric' }) },
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
                onClick={() => { setShowDetail(false); openEdit(selectedArmada); }}
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
        isOpen={showHapus && selectedArmada !== null}
        title="Hapus Armada?"
        message={
          <>
            Anda akan menghapus <span className="font-semibold text-slate-700">{selectedArmada?.nama_armada}</span>{' '}
            <span className="font-mono text-slate-500">({selectedArmada?.plat_nomor})</span>.
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
