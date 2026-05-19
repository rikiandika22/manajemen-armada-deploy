import { useState } from 'react';
import { Plus, Filter, Calendar, Eye, Edit2, Trash2, Truck } from 'lucide-react';
import Layout from '../components/Layout';
import Card from '../components/Card';
import Badge from '../components/Badge';
import { mockJadwal } from '../data/mockData';

export default function Jadwal() {
  const [filterJenis, setFilterJenis] = useState('Semua');
  const [filterStatus, setFilterStatus] = useState('Semua');
  const [filterTanggal, setFilterTanggal] = useState('');

  const jenisOptions = ['Semua', 'Bus Medium', 'Elf Long', 'Truk CDD Bak Terbuka'];
  const statusOptions = ['Semua', 'Tersedia', 'Dipesan', 'Dalam Perjalanan', 'Selesai'];

  const filtered = mockJadwal.filter((j) => {
    const matchJenis = filterJenis === 'Semua' || j.jenis === filterJenis;
    const matchStatus = filterStatus === 'Semua' || j.status === filterStatus;
    const matchTanggal = !filterTanggal || j.tanggal === filterTanggal;
    return matchJenis && matchStatus && matchTanggal;
  });

  return (
    <Layout>
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
        <div>
          <h2 className="text-xl font-bold text-slate-800">Jadwal Armada</h2>
          <p className="text-sm text-slate-500 mt-0.5">Kelola jadwal operasional armada</p>
        </div>
        <button
          className="flex items-center gap-2 px-4 py-2.5 rounded-xl text-sm font-semibold text-slate-900 hover:opacity-90 transition-opacity shadow-sm"
          style={{ backgroundColor: '#a3e635' }}
        >
          <Plus size={16} />
          Tambah Jadwal
        </button>
      </div>

      {/* Filters */}
      <Card className="p-4 mb-5">
        <div className="flex flex-wrap gap-3 items-center">
          <div className="flex items-center gap-2">
            <Calendar size={15} className="text-slate-400" />
            <input
              type="date"
              value={filterTanggal}
              onChange={(e) => setFilterTanggal(e.target.value)}
              className="border border-slate-200 rounded-xl px-3 py-2.5 text-sm text-slate-700 bg-white focus:outline-none focus:ring-2"
            />
          </div>
          <div className="flex items-center gap-2">
            <Filter size={15} className="text-slate-400" />
            <select
              value={filterJenis}
              onChange={(e) => setFilterJenis(e.target.value)}
              className="border border-slate-200 rounded-xl px-3 py-2.5 text-sm text-slate-700 bg-white focus:outline-none focus:ring-2"
            >
              {jenisOptions.map((o) => <option key={o}>{o}</option>)}
            </select>
          </div>
          <select
            value={filterStatus}
            onChange={(e) => setFilterStatus(e.target.value)}
            className="border border-slate-200 rounded-xl px-3 py-2.5 text-sm text-slate-700 bg-white focus:outline-none focus:ring-2"
          >
            {statusOptions.map((o) => <option key={o}>{o}</option>)}
          </select>
          {(filterTanggal || filterJenis !== 'Semua' || filterStatus !== 'Semua') && (
            <button
              onClick={() => { setFilterTanggal(''); setFilterJenis('Semua'); setFilterStatus('Semua'); }}
              className="text-xs text-slate-500 hover:text-slate-700 underline"
            >
              Reset Filter
            </button>
          )}
        </div>
      </Card>

      {/* Table */}
      <Card>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-white">
              <tr className="border-b border-slate-200">
                {['ID Jadwal', 'Tanggal', 'Jenis Armada', 'Plat Nomor', 'Rute / Tujuan', 'Sopir', 'Status', 'Aksi'].map((h) => (
                  <th key={h} className="text-left text-[11px] font-bold text-slate-400 uppercase tracking-wider px-5 py-4">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {filtered.map((row) => (
                <tr key={row.id} className="odd:bg-white even:bg-slate-50 hover:bg-slate-100/50 transition-colors">
                  <td className="px-5 py-4 text-sm font-mono text-slate-500">{row.id}</td>
                  <td className="px-5 py-4 text-sm text-slate-600 whitespace-nowrap">{row.tanggal}</td>
                  <td className="px-5 py-4">
                    <div className="flex items-center gap-2">
                      <Truck size={14} className="text-slate-400" />
                      <span className="text-sm text-slate-700">{row.jenis}</span>
                    </div>
                  </td>
                  <td className="px-5 py-4 text-sm font-semibold text-slate-800">{row.plat}</td>
                  <td className="px-5 py-4 text-sm text-slate-700">{row.rute}</td>
                  <td className="px-5 py-4 text-sm text-slate-600">{row.sopir}</td>
                  <td className="px-5 py-4"><Badge status={row.status} /></td>
                  <td className="px-5 py-4">
                    <div className="flex items-center gap-2">
                      <button className="p-1.5 rounded-lg bg-blue-50 text-blue-600 hover:bg-blue-100 transition-colors">
                        <Eye size={14} />
                      </button>
                      <button className="p-1.5 rounded-lg bg-amber-50 text-amber-600 hover:bg-amber-100 transition-colors">
                        <Edit2 size={14} />
                      </button>
                      <button className="p-1.5 rounded-lg bg-red-50 text-red-500 hover:bg-red-100 transition-colors">
                        <Trash2 size={14} />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          {filtered.length === 0 && (
            <div className="text-center py-16 text-slate-400">
              <Calendar size={40} className="mx-auto mb-3 opacity-30" />
              <p className="text-sm">Tidak ada jadwal ditemukan</p>
            </div>
          )}
        </div>
      </Card>
    </Layout>
  );
}
