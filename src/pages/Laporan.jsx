import { useState, useEffect } from 'react';
import {
  Filter, Download, FileText, ShoppingCart, CreditCard, Truck,
  Eye, X, Loader2, CheckCircle, AlertTriangle, Calendar
} from 'lucide-react';
import Layout from '../components/Layout';
import Card from '../components/Card';
import Badge from '../components/Badge';
import ConfirmModal from '../components/ConfirmModal';
import AppSelect from '../components/AppSelect';
import AppDateInput from '../components/AppDateInput';
import { getReportSummary, getOperationalReports, exportReportPdf, exportReportExcel } from '../services/api';
import { formatRupiah } from '../utils/format';

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

// ─── Helpers ────────────────────────────────────────────────

function formatTanggal(str) {
  if (!str) return '—';
  try {
    let dateStr = str;
    if (typeof dateStr === 'string' && dateStr.includes(' ')) {
      dateStr = dateStr.replace(' ', 'T');
    }
    const d = new Date(dateStr);
    if (isNaN(d.getTime())) return '—';
    return d.toLocaleDateString('id-ID', { day: '2-digit', month: 'long', year: 'numeric' });
  } catch (e) {
    return '—';
  }
}

function getReportDate(item) {
  if (!item) return null;
  return item.tanggal_penggunaan || item.tanggal_laporan || item.created_at || item.date;
}

// ─── Main Component ─────────────────────────────────────────
export default function Laporan() {
  const [filterJenis, setFilterJenis] = useState('Semua');
  const [filterDari, setFilterDari] = useState('');
  const [filterSampai, setFilterSampai] = useState('');
  const [filterStatus, setFilterStatus] = useState('Semua');
  
  const [mounted, setMounted] = useState(false);

  // Real data state
  const [summary, setSummary] = useState({ total_pemesanan: 0, total_pembayaran_masuk: 0, armada_aktif: 0 });
  const [reports, setReports] = useState([]);
  const [loadingSummary, setLoadingSummary] = useState(false);
  const [loadingReports, setLoadingReports] = useState(false);

  // Export loading states
  const [pdfLoading, setPdfLoading] = useState(false);
  const [excelLoading, setExcelLoading] = useState(false);

  // Modal
  const [showDetail, setShowDetail] = useState(false);
  const [selectedItem, setSelectedItem] = useState(null);

  // Toast
  const [toast, setToast] = useState(null);

  const jenisOptions = ['Semua', 'Bus', 'Elf', 'Truk'];
  const statusOptions = ['Semua', 'Menunggu Konfirmasi', 'Menunggu Konfirmasi Admin', 'Terjadwal', 'Selesai', 'Dibatalkan', 'DP Diterima', 'Lunas'];

  const fetchReports = async () => {
    try {
      setLoadingReports(true);
      const params = {
        start_date: filterDari || undefined,
        end_date: filterSampai || undefined,
        fleet_type: filterJenis !== 'Semua' ? filterJenis : undefined,
        status: filterStatus !== 'Semua' ? filterStatus : undefined,
      };
      const res = await getOperationalReports(params);
      setReports(res.data.data || []);
    } catch (err) {
      setToast({ message: 'Gagal memuat data laporan operasional.', type: 'error' });
      setReports([]);
    } finally {
      setLoadingReports(false);
    }
  };

  const fetchSummary = async () => {
    try {
      setLoadingSummary(true);
      const params = {
        start_date: filterDari || undefined,
        end_date: filterSampai || undefined,
        fleet_type: filterJenis !== 'Semua' ? filterJenis : undefined,
        status: filterStatus !== 'Semua' ? filterStatus : undefined,
      };
      const res = await getReportSummary(params);
      setSummary(res.data.data || { total_pemesanan: 0, total_pembayaran_masuk: 0, armada_aktif: 0 });
    } catch (err) {
      setToast({ message: 'Gagal memuat data summary laporan.', type: 'error' });
    } finally {
      setLoadingSummary(false);
    }
  };

  useEffect(() => {
    setMounted(true);
  }, []);

  // Fetch when filters change
  useEffect(() => {
    // Only fetch if dates are either both empty or both filled correctly (start <= end)
    if (filterDari && filterSampai && filterDari > filterSampai) {
      setToast({ message: 'Tanggal mulai tidak boleh lebih besar dari tanggal akhir.', type: 'error' });
      return;
    }
    fetchReports();
    fetchSummary();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [filterJenis, filterDari, filterSampai, filterStatus]);

  // ── Export handlers ──
  async function handleExportPDF() {
    if (reports.length === 0) {
      setToast({ message: 'Tidak ada data laporan untuk diexport.', type: 'error' });
      return;
    }
    setPdfLoading(true);
    try {
      const params = {
        start_date: filterDari || undefined,
        end_date: filterSampai || undefined,
        fleet_type: filterJenis !== 'Semua' ? filterJenis : undefined,
        status: filterStatus !== 'Semua' ? filterStatus : undefined,
      };
      const res = await exportReportPdf(params);
      const url = window.URL.createObjectURL(new Blob([res.data], { type: 'application/pdf' }));
      const link = document.createElement('a');
      link.href = url;
      link.setAttribute('download', `laporan_operasional_${new Date().getTime()}.pdf`);
      document.body.appendChild(link);
      link.click();
      link.remove();
      setToast({ message: 'File PDF berhasil diexport!', type: 'success' });
    } catch (err) {
      setToast({ message: 'Gagal mengexport PDF. Coba lagi.', type: 'error' });
    } finally {
      setPdfLoading(false);
    }
  }

  async function handleExportExcel() {
    if (reports.length === 0) {
      setToast({ message: 'Tidak ada data laporan untuk diexport.', type: 'error' });
      return;
    }
    setExcelLoading(true);
    try {
      const params = {
        start_date: filterDari || undefined,
        end_date: filterSampai || undefined,
        fleet_type: filterJenis !== 'Semua' ? filterJenis : undefined,
        status: filterStatus !== 'Semua' ? filterStatus : undefined,
      };
      const res = await exportReportExcel(params);
      const url = window.URL.createObjectURL(new Blob([res.data], { type: 'text/csv' }));
      const link = document.createElement('a');
      link.href = url;
      link.setAttribute('download', `laporan_operasional_${new Date().getTime()}.csv`);
      document.body.appendChild(link);
      link.click();
      link.remove();
      setToast({ message: 'File Excel berhasil diexport!', type: 'success' });
    } catch (err) {
      setToast({ message: 'Gagal mengexport Excel. Coba lagi.', type: 'error' });
    } finally {
      setExcelLoading(false);
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
          <h2 className="text-xl font-bold text-slate-800">Laporan Operasional</h2>
          <p className="text-sm text-slate-500 mt-0.5">Rekap data operasional armada Sumber Agung Trans</p>
        </div>
        <div className="flex gap-2">
          <button
            onClick={handleExportPDF}
            disabled={pdfLoading}
            className="flex items-center gap-2 px-4 py-2.5 rounded-xl text-sm font-semibold text-red-700 bg-red-50 hover:bg-red-100 active:scale-95 transition-all duration-150 border border-red-200 disabled:opacity-70"
          >
            {pdfLoading ? <Loader2 size={15} className="animate-spin" /> : <FileText size={15} />}
            {pdfLoading ? 'Mengexport...' : 'Export PDF'}
          </button>
          <button
            onClick={handleExportExcel}
            disabled={excelLoading}
            className="flex items-center gap-2 px-4 py-2.5 rounded-xl text-sm font-semibold text-slate-900 hover:opacity-90 active:scale-95 transition-all duration-150 disabled:opacity-70"
            style={{ backgroundColor: '#a3e635' }}
          >
            {excelLoading ? <Loader2 size={15} className="animate-spin" /> : <Download size={15} />}
            {excelLoading ? 'Mengexport...' : 'Export Excel'}
          </button>
        </div>
      </div>

      {/* Summary Cards */}
      <div
        className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-6 transition-all duration-500 delay-75"
        style={{ opacity: mounted ? 1 : 0, transform: mounted ? 'translateY(0)' : 'translateY(12px)' }}
      >
        <Card className="p-5 hover:shadow-md transition-shadow duration-200">
          <div className="flex items-center justify-between mb-3">
            <div className="w-10 h-10 rounded-xl bg-blue-50 flex items-center justify-center">
              <ShoppingCart size={20} className="text-blue-600" />
            </div>
            <span className="text-xs text-slate-400">Total</span>
          </div>
          {loadingSummary ? (
            <div className="h-9 w-16 bg-slate-200 animate-pulse rounded-md mt-1 mb-1"></div>
          ) : (
            <p className="text-3xl font-bold text-slate-800">{summary.total_pemesanan}</p>
          )}
          <p className="text-sm text-slate-500 mt-1">Total Pemesanan</p>
          <div className="mt-3 h-1 rounded-full bg-blue-100" />
        </Card>
        <Card className="p-5 hover:shadow-md transition-shadow duration-200">
          <div className="flex items-center justify-between mb-3">
            <div className="w-10 h-10 rounded-xl bg-green-50 flex items-center justify-center">
              <CreditCard size={20} className="text-green-600" />
            </div>
            <span className="text-xs text-slate-400">Pendapatan</span>
          </div>
          {loadingSummary ? (
            <div className="h-8 w-32 bg-slate-200 animate-pulse rounded-md mt-1 mb-1"></div>
          ) : (
            <p className="text-2xl font-bold text-slate-800">{formatRupiah(summary.total_pembayaran_masuk)}</p>
          )}
          <p className="text-sm text-slate-500 mt-1">Total Pembayaran Masuk</p>
          <div className="mt-3 h-1 rounded-full bg-green-100" />
        </Card>
        <Card className="p-5 hover:shadow-md transition-shadow duration-200">
          <div className="flex items-center justify-between mb-3">
            <div className="w-10 h-10 rounded-xl bg-lime-50 flex items-center justify-center">
              <Truck size={20} style={{ color: '#65a30d' }} />
            </div>
            <span className="text-xs text-slate-400">Aktif</span>
          </div>
          {loadingSummary ? (
            <div className="h-9 w-12 bg-slate-200 animate-pulse rounded-md mt-1 mb-1"></div>
          ) : (
            <p className="text-3xl font-bold text-slate-800">{summary.armada_aktif}</p>
          )}
          <p className="text-sm text-slate-500 mt-1">Armada Aktif</p>
          <div className="mt-3 h-1 rounded-full" style={{ backgroundColor: '#ecfccb' }} />
        </Card>
      </div>

      {/* Filters */}
      <div
        className="transition-all duration-500 delay-100"
        style={{ opacity: mounted ? 1 : 0, transform: mounted ? 'translateY(0)' : 'translateY(12px)' }}
      >
        <Card className="p-4 mb-5">
          <div className="flex flex-wrap gap-3 items-center">
            <div className="flex items-center gap-2">
              <Filter size={15} className="text-slate-400" />
              <span className="text-sm text-slate-600 font-medium">Periode:</span>
              <AppDateInput value={filterDari} onChange={setFilterDari} />
              <span className="text-sm text-slate-400">s/d</span>
              <AppDateInput value={filterSampai} onChange={setFilterSampai} />
            </div>
            <AppSelect
              value={filterJenis}
              onChange={setFilterJenis}
              options={[{ value: 'Semua', label: 'Semua Armada' }, ...jenisOptions.filter(o => o !== 'Semua').map(o => ({ value: o, label: o }))]}
              className="w-full md:w-auto md:min-w-[160px]"
            />
            <AppSelect
              value={filterStatus}
              onChange={setFilterStatus}
              options={[{ value: 'Semua', label: 'Semua Status' }, ...statusOptions.filter(o => o !== 'Semua').map(o => ({ value: o, label: o }))]}
              className="w-full md:w-auto md:min-w-[160px]"
            />
            {/* Reset filters */}
            {(filterJenis !== 'Semua' || filterDari || filterSampai || filterStatus !== 'Semua') && (
              <button
                onClick={() => { setFilterJenis('Semua'); setFilterDari(''); setFilterSampai(''); setFilterStatus('Semua'); }}
                className="text-xs text-slate-500 hover:text-slate-700 underline transition-colors"
              >
                Reset Filter
              </button>
            )}
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
            <table className="w-full">
              <thead className="bg-white">
                <tr className="border-b border-slate-200">
                  {['ID', 'Tanggal', 'Jenis Armada', 'Rute', 'Pelanggan', 'Pendapatan', 'Status', 'Aksi'].map((h) => (
                    <th key={h} className="text-left text-[11px] font-bold text-slate-400 uppercase tracking-wider px-5 py-4">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {loadingReports ? (
                  <tr>
                    <td colSpan="8" className="px-5 py-10 text-center">
                      <Loader2 size={30} className="animate-spin text-slate-300 mx-auto mb-2" />
                      <p className="text-sm text-slate-500">Memuat data laporan...</p>
                    </td>
                  </tr>
                ) : (
                  reports.map((row, idx) => (
                    <tr
                      key={row.id}
                      className="odd:bg-white even:bg-slate-50 hover:bg-lime-50/40 transition-colors group animate-fade-in-up"
                      style={{ animationDelay: `${idx * 50}ms` }}
                    >
                      <td className="px-5 py-4 text-sm font-mono text-slate-500">{row.order_code}</td>
                      <td className="px-5 py-4 text-sm text-slate-600 whitespace-nowrap">{formatTanggal(getReportDate(row))}</td>
                      <td className="px-5 py-4 text-sm text-slate-700">{row.fleet_type}</td>
                      <td className="px-5 py-4 text-sm text-slate-700 max-w-44">
                        <span className="truncate block">{row.route}</span>
                      </td>
                      <td className="px-5 py-4 text-sm text-slate-700">{row.customer_name}</td>
                      <td className="px-5 py-4 text-sm font-semibold text-slate-800">{row.income > 0 ? formatRupiah(row.income) : 'Rp 0'}</td>
                      <td className="px-5 py-4"><Badge status={row.status} /></td>
                      <td className="px-5 py-4">
                        <button
                          onClick={() => { setSelectedItem(row); setShowDetail(true); }}
                          className="p-1.5 rounded-lg bg-blue-50 text-blue-600 hover:bg-blue-100 active:scale-90 transition-all duration-150"
                          title="Detail"
                        >
                          <Eye size={14} />
                        </button>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>

            {!loadingReports && reports.length === 0 && (
              <div className="text-center py-16 text-slate-400">
                <FileText size={40} className="mx-auto mb-3 opacity-30" />
                <p className="text-sm font-medium">Belum ada data laporan</p>
                <p className="text-xs mt-1 text-slate-400">Data laporan akan muncul setelah ada pemesanan, pembayaran, atau jadwal operasional.</p>
                {(filterJenis !== 'Semua' || filterDari || filterSampai || filterStatus !== 'Semua') && (
                  <button
                    onClick={() => { setFilterJenis('Semua'); setFilterDari(''); setFilterSampai(''); setFilterStatus('Semua'); }}
                    className="mt-3 text-xs text-slate-500 hover:text-slate-700 underline transition-colors"
                  >
                    Reset filter
                  </button>
                )}
              </div>
            )}
          </div>
        </Card>
      </div>

      {/* ── Modal Detail ── */}
      {showDetail && selectedItem && (
        <ModalOverlay onClose={() => setShowDetail(false)}>
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-md overflow-hidden animate-in fade-in zoom-in-95 duration-200">
            <div className="flex items-center justify-between px-6 py-4 border-b border-slate-100">
              <h3 className="text-lg font-bold text-slate-800">Detail Laporan</h3>
              <button onClick={() => setShowDetail(false)} className="text-slate-400 hover:text-slate-600 transition-colors">
                <X size={20} />
              </button>
            </div>
            <div className="px-6 py-5">
              {/* Header */}
              <div className="flex items-center gap-4 mb-6 p-4 bg-slate-50 rounded-xl">
                <div className="w-12 h-12 rounded-xl bg-blue-50 flex items-center justify-center flex-shrink-0">
                  <FileText size={22} className="text-blue-600" />
                </div>
                <div className="min-w-0">
                  <p className="text-base font-bold text-slate-800 truncate">{selectedItem.pelanggan}</p>
                  <p className="text-sm font-mono text-slate-500">{selectedItem.id}</p>
                </div>
                <div className="ml-auto flex-shrink-0">
                  <Badge status={selectedItem.status} />
                </div>
              </div>

              {/* Fields */}
              <div className="space-y-0">
                {[
                  { icon: FileText, label: 'Kode Pesanan', value: selectedItem.order_code },
                  { icon: Calendar, label: 'Tanggal', value: formatTanggal(getReportDate(selectedItem)) },
                  { icon: Truck, label: 'Jenis Armada', value: selectedItem.fleet_type },
                  { icon: null, label: 'Rute', value: selectedItem.route },
                  { icon: null, label: 'Pelanggan', value: selectedItem.customer_name },
                  { icon: CreditCard, label: 'Pendapatan', value: selectedItem.income > 0 ? formatRupiah(selectedItem.income) : 'Rp 0' },
                  { icon: null, label: 'Status', value: selectedItem.status },
                ].map(({ label, value }) => (
                  <div key={label} className="flex justify-between items-start py-3 border-b border-slate-100 last:border-0">
                    <span className="text-xs font-semibold text-slate-500 uppercase tracking-wide">{label}</span>
                    <span className="text-sm text-slate-700 font-medium text-right max-w-[60%]">{value}</span>
                  </div>
                ))}
              </div>
            </div>
            <div className="px-6 py-4 border-t border-slate-100 flex justify-end">
              <button
                onClick={() => setShowDetail(false)}
                className="px-6 py-2.5 text-sm font-semibold text-slate-900 rounded-full hover:opacity-90 transition-opacity"
                style={{ backgroundColor: '#a3e635' }}
              >
                Tutup
              </button>
            </div>
          </div>
        </ModalOverlay>
      )}

      {/* ── Toast ── */}
      {toast && (
        <Toast
          message={toast.message}
          type={toast.type}
          onClose={() => setToast(null)}
        />
      )}

      {/* Animation CSS */}
      <style>{`
        @keyframes fadeSlideIn {
          from { opacity: 0; transform: translateY(8px); }
          to   { opacity: 1; transform: translateY(0); }
        }
      `}</style>
    </Layout>
  );
}
