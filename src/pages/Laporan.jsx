import { useState } from 'react';
import { Filter, Download, FileText, ShoppingCart, CreditCard, Truck, Eye } from 'lucide-react';
import Layout from '../components/Layout';
import Card from '../components/Card';
import Badge from '../components/Badge';
import { mockLaporan } from '../data/mockData';

export default function Laporan() {
  const [filterJenis, setFilterJenis] = useState('Semua');
  const [filterDari, setFilterDari] = useState('');
  const [filterSampai, setFilterSampai] = useState('');

  const jenisOptions = ['Semua', 'Bus Medium', 'Elf Long', 'Truk CDD'];

  const filtered = mockLaporan.filter((l) => {
    const matchJenis = filterJenis === 'Semua' || l.jenis === filterJenis;
    return matchJenis;
  });

  const totalPendapatan = filtered.reduce((acc, l) => {
    const num = parseInt(l.pendapatan.replace(/[^0-9]/g, ''));
    return acc + num;
  }, 0);

  const formatRp = (n) => 'Rp ' + n.toLocaleString('id-ID');

  return (
    <Layout>
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
        <div>
          <h2 className="text-xl font-bold text-slate-800">Laporan Operasional</h2>
          <p className="text-sm text-slate-500 mt-0.5">Rekap data operasional armada Sumber Agung Trans</p>
        </div>
        <div className="flex gap-2">
          <button className="flex items-center gap-2 px-4 py-2.5 rounded-xl text-sm font-semibold text-red-700 bg-red-50 hover:bg-red-100 transition-colors border border-red-200">
            <FileText size={15} />
            Export PDF
          </button>
          <button
            className="flex items-center gap-2 px-4 py-2.5 rounded-xl text-sm font-semibold text-slate-900 hover:opacity-90 transition-opacity"
            style={{ backgroundColor: '#a3e635' }}
          >
            <Download size={15} />
            Export Excel
          </button>
        </div>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-6">
        <Card className="p-5">
          <div className="flex items-center justify-between mb-3">
            <div className="w-10 h-10 rounded-xl bg-blue-50 flex items-center justify-center">
              <ShoppingCart size={20} className="text-blue-600" />
            </div>
            <span className="text-xs text-slate-400">Total</span>
          </div>
          <p className="text-3xl font-bold text-slate-800">{filtered.length}</p>
          <p className="text-sm text-slate-500 mt-1">Total Pemesanan</p>
        </Card>
        <Card className="p-5">
          <div className="flex items-center justify-between mb-3">
            <div className="w-10 h-10 rounded-xl bg-green-50 flex items-center justify-center">
              <CreditCard size={20} className="text-green-600" />
            </div>
            <span className="text-xs text-slate-400">Pendapatan</span>
          </div>
          <p className="text-2xl font-bold text-slate-800">{formatRp(totalPendapatan)}</p>
          <p className="text-sm text-slate-500 mt-1">Total Pembayaran Masuk</p>
        </Card>
        <Card className="p-5">
          <div className="flex items-center justify-between mb-3">
            <div className="w-10 h-10 rounded-xl bg-lime-50 flex items-center justify-center">
              <Truck size={20} style={{ color: '#65a30d' }} />
            </div>
            <span className="text-xs text-slate-400">Aktif</span>
          </div>
          <p className="text-3xl font-bold text-slate-800">4</p>
          <p className="text-sm text-slate-500 mt-1">Armada Aktif</p>
        </Card>
      </div>

      {/* Filters */}
      <Card className="p-4 mb-5">
        <div className="flex flex-wrap gap-3 items-center">
          <div className="flex items-center gap-2">
            <Filter size={15} className="text-slate-400" />
            <span className="text-sm text-slate-600">Periode:</span>
            <input
              type="date"
              value={filterDari}
              onChange={(e) => setFilterDari(e.target.value)}
              className="border border-slate-200 rounded-xl px-3 py-2.5 text-sm text-slate-700 bg-white focus:outline-none focus:ring-2"
            />
            <span className="text-sm text-slate-400">s/d</span>
            <input
              type="date"
              value={filterSampai}
              onChange={(e) => setFilterSampai(e.target.value)}
              className="border border-slate-200 rounded-xl px-3 py-2.5 text-sm text-slate-700 bg-white focus:outline-none focus:ring-2"
            />
          </div>
          <select
            value={filterJenis}
            onChange={(e) => setFilterJenis(e.target.value)}
            className="border border-slate-200 rounded-xl px-3 py-2.5 text-sm text-slate-700 bg-white focus:outline-none focus:ring-2"
          >
            {jenisOptions.map((o) => <option key={o}>{o}</option>)}
          </select>
        </div>
      </Card>

      {/* Table */}
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
              {filtered.map((row) => (
                <tr key={row.id} className="odd:bg-white even:bg-slate-50 hover:bg-slate-100/50 transition-colors">
                  <td className="px-5 py-4 text-sm font-mono text-slate-500">{row.id}</td>
                  <td className="px-5 py-4 text-sm text-slate-600">{row.tanggal}</td>
                  <td className="px-5 py-4 text-sm text-slate-700">{row.jenis}</td>
                  <td className="px-5 py-4 text-sm text-slate-700 max-w-44">
                    <span className="truncate block">{row.rute}</span>
                  </td>
                  <td className="px-5 py-4 text-sm text-slate-700">{row.pelanggan}</td>
                  <td className="px-5 py-4 text-sm font-semibold text-slate-800">{row.pendapatan}</td>
                  <td className="px-5 py-4"><Badge status={row.status} /></td>
                  <td className="px-5 py-4">
                    <button className="p-1.5 rounded-lg bg-blue-50 text-blue-600 hover:bg-blue-100 transition-colors">
                      <Eye size={14} />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          {filtered.length === 0 && (
            <div className="text-center py-16 text-slate-400">
              <FileText size={40} className="mx-auto mb-3 opacity-30" />
              <p className="text-sm">Tidak ada data laporan</p>
            </div>
          )}
        </div>
      </Card>
    </Layout>
  );
}
