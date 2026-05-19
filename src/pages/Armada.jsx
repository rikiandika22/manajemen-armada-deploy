import { useState } from 'react';
import { Search, Plus, Filter, Eye, Edit2, Trash2, Truck } from 'lucide-react';
import Layout from '../components/Layout';
import Card from '../components/Card';
import Badge from '../components/Badge';
import { mockArmada } from '../data/mockData';

export default function Armada() {
  const [search, setSearch] = useState('');
  const [filterJenis, setFilterJenis] = useState('Semua');
  const [filterStatus, setFilterStatus] = useState('Semua');

  const jenisOptions = ['Semua', 'Bus Medium', 'Elf Long', 'Truk CDD Bak Terbuka'];
  const statusOptions = ['Semua', 'Tersedia', 'Dalam Perjalanan', 'Perawatan', 'Tidak Aktif'];

  const filtered = mockArmada.filter((a) => {
    const matchSearch = a.plat.toLowerCase().includes(search.toLowerCase()) || a.jenis.toLowerCase().includes(search.toLowerCase());
    const matchJenis = filterJenis === 'Semua' || a.jenis === filterJenis;
    const matchStatus = filterStatus === 'Semua' || a.status === filterStatus;
    return matchSearch && matchJenis && matchStatus;
  });

  return (
    <Layout>
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
        <div>
          <h2 className="text-xl font-bold text-slate-800">Data Armada</h2>
          <p className="text-sm text-slate-500 mt-0.5">Kelola semua unit armada Sumber Agung Trans</p>
        </div>
        <button
          className="flex items-center gap-2 px-4 py-2.5 rounded-xl text-sm font-semibold text-slate-900 hover:opacity-90 transition-opacity shadow-sm"
          style={{ backgroundColor: '#a3e635' }}
        >
          <Plus size={16} />
          Tambah Armada
        </button>
      </div>

      {/* Filters */}
      <Card className="p-4 mb-5">
        <div className="flex flex-wrap gap-3 items-center">
          {/* Search */}
          <div className="relative flex-1 min-w-52">
            <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
            <input
              type="text"
              placeholder="Cari plat nomor atau jenis armada..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full pl-9 pr-4 py-2.5 border border-slate-200 rounded-xl text-sm bg-white text-slate-700 placeholder-slate-400 focus:outline-none focus:ring-2 focus:border-transparent"
            />
          </div>
          {/* Filter Jenis */}
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
          {/* Filter Status */}
          <select
            value={filterStatus}
            onChange={(e) => setFilterStatus(e.target.value)}
            className="border border-slate-200 rounded-xl px-3 py-2.5 text-sm text-slate-700 bg-white focus:outline-none focus:ring-2"
          >
            {statusOptions.map((o) => <option key={o}>{o}</option>)}
          </select>
        </div>
      </Card>

      {/* Table */}
      <Card>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-white">
              <tr className="border-b border-slate-200">
                {['ID Armada', 'Plat Nomor', 'Jenis Kendaraan', 'Kapasitas', 'Status', 'Keterangan', 'Aksi'].map((h) => (
                  <th key={h} className="text-left text-[11px] font-bold text-slate-400 uppercase tracking-wider px-5 py-4">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {filtered.map((row) => (
                <tr key={row.id} className="odd:bg-white even:bg-slate-50 hover:bg-slate-100/50 transition-colors group">
                  <td className="px-5 py-4 text-sm font-mono text-slate-500">{row.id}</td>
                  <td className="px-5 py-4">
                    <span className="text-sm font-semibold text-slate-800">{row.plat}</span>
                  </td>
                  <td className="px-5 py-4">
                    <div className="flex items-center gap-2">
                      <div className="w-8 h-8 rounded-lg bg-slate-100 flex items-center justify-center">
                        <Truck size={14} className="text-slate-500" />
                      </div>
                      <span className="text-sm text-slate-700">{row.jenis}</span>
                    </div>
                  </td>
                  <td className="px-5 py-4 text-sm text-slate-600">{row.kapasitas}</td>
                  <td className="px-5 py-4"><Badge status={row.status} /></td>
                  <td className="px-5 py-4 text-sm text-slate-500 max-w-48">
                    <span className="truncate block">{row.keterangan}</span>
                  </td>
                  <td className="px-5 py-4">
                    <div className="flex items-center gap-2">
                      <button className="p-1.5 rounded-lg bg-blue-50 text-blue-600 hover:bg-blue-100 transition-colors" title="Detail">
                        <Eye size={14} />
                      </button>
                      <button className="p-1.5 rounded-lg bg-amber-50 text-amber-600 hover:bg-amber-100 transition-colors" title="Edit">
                        <Edit2 size={14} />
                      </button>
                      <button className="p-1.5 rounded-lg bg-red-50 text-red-500 hover:bg-red-100 transition-colors" title="Hapus">
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
              <Truck size={40} className="mx-auto mb-3 opacity-30" />
              <p className="text-sm">Tidak ada data armada ditemukan</p>
            </div>
          )}
        </div>
      </Card>
    </Layout>
  );
}
