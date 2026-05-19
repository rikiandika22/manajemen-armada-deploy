import { useState } from 'react';
import { Search, Filter, Eye, Edit2, CheckCircle, XCircle, Calendar } from 'lucide-react';
import Layout from '../components/Layout';
import Card from '../components/Card';
import Badge from '../components/Badge';
import { mockPemesanan } from '../data/mockData';

export default function Pemesanan() {
  const [search, setSearch] = useState('');
  const [filterStatus, setFilterStatus] = useState('Semua');
  const [filterTanggal, setFilterTanggal] = useState('');

  const statusOptions = ['Semua', 'Menunggu Konfirmasi', 'Diterima', 'Ditolak', 'Selesai'];

  const filtered = mockPemesanan.filter((p) => {
    const matchSearch = p.nama.toLowerCase().includes(search.toLowerCase()) || p.telepon.includes(search);
    const matchStatus = filterStatus === 'Semua' || p.status === filterStatus;
    const matchTanggal = !filterTanggal || p.tanggal === filterTanggal;
    return matchSearch && matchStatus && matchTanggal;
  });

  return (
    <Layout>
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
        <div>
          <h2 className="text-xl font-bold text-slate-800">Pemesanan</h2>
          <p className="text-sm text-slate-500 mt-0.5">Kelola permintaan pemesanan dari pelanggan</p>
        </div>
        <div className="flex items-center gap-2">
          <span className="text-xs text-slate-500 bg-yellow-50 text-yellow-700 border border-yellow-200 px-3 py-1.5 rounded-full font-medium">
            4 Menunggu Konfirmasi
          </span>
        </div>
      </div>

      {/* Filters */}
      <Card className="p-4 mb-5">
        <div className="flex flex-wrap gap-3 items-center">
          <div className="relative flex-1 min-w-52">
            <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
            <input
              type="text"
              placeholder="Cari nama atau nomor telepon..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full pl-9 pr-4 py-2.5 border border-slate-200 rounded-xl text-sm bg-white text-slate-700 placeholder-slate-400 focus:outline-none focus:ring-2"
            />
          </div>
          <div className="flex items-center gap-2">
            <Filter size={15} className="text-slate-400" />
            <select
              value={filterStatus}
              onChange={(e) => setFilterStatus(e.target.value)}
              className="border border-slate-200 rounded-xl px-3 py-2.5 text-sm text-slate-700 bg-white focus:outline-none focus:ring-2"
            >
              {statusOptions.map((o) => <option key={o}>{o}</option>)}
            </select>
          </div>
          <div className="flex items-center gap-2">
            <Calendar size={15} className="text-slate-400" />
            <input
              type="date"
              value={filterTanggal}
              onChange={(e) => setFilterTanggal(e.target.value)}
              className="border border-slate-200 rounded-xl px-3 py-2.5 text-sm text-slate-700 bg-white focus:outline-none focus:ring-2"
            />
          </div>
        </div>
      </Card>

      {/* Table */}
      <Card>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-white">
              <tr className="border-b border-slate-200">
                {['ID Pemesanan', 'Nama Pelanggan', 'No. Telepon', 'Tanggal Sewa', 'Jenis Armada', 'Tujuan', 'Status', 'Aksi'].map((h) => (
                  <th key={h} className="text-left text-[11px] font-bold text-slate-400 uppercase tracking-wider px-5 py-4">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {filtered.map((row) => (
                <tr key={row.id} className="odd:bg-white even:bg-slate-50 hover:bg-slate-100/50 transition-colors">
                  <td className="px-5 py-4 text-sm font-mono text-slate-500">{row.id}</td>
                  <td className="px-5 py-4">
                    <div className="flex items-center gap-2.5">
                      <div
                        className="w-8 h-8 rounded-full flex items-center justify-center text-white text-xs font-bold flex-shrink-0"
                        style={{ background: 'linear-gradient(135deg, #a3e635, #65a30d)' }}
                      >
                        {row.nama.charAt(0)}
                      </div>
                      <span className="text-sm font-medium text-slate-800">{row.nama}</span>
                    </div>
                  </td>
                  <td className="px-5 py-4 text-sm text-slate-600">{row.telepon}</td>
                  <td className="px-5 py-4 text-sm text-slate-600 whitespace-nowrap">{row.tanggal}</td>
                  <td className="px-5 py-4 text-sm text-slate-700">{row.jenis}</td>
                  <td className="px-5 py-4 text-sm text-slate-700 max-w-44">
                    <span className="truncate block">{row.tujuan}</span>
                  </td>
                  <td className="px-5 py-4"><Badge status={row.status} /></td>
                  <td className="px-5 py-4">
                    <div className="flex items-center gap-2">
                      <button className="p-1.5 rounded-lg bg-blue-50 text-blue-600 hover:bg-blue-100 transition-colors" title="Detail">
                        <Eye size={14} />
                      </button>
                      {row.status === 'Menunggu Konfirmasi' && (
                        <>
                          <button className="p-1.5 rounded-lg bg-green-50 text-green-600 hover:bg-green-100 transition-colors" title="Terima">
                            <CheckCircle size={14} />
                          </button>
                          <button className="p-1.5 rounded-lg bg-red-50 text-red-500 hover:bg-red-100 transition-colors" title="Tolak">
                            <XCircle size={14} />
                          </button>
                        </>
                      )}
                      {row.status !== 'Menunggu Konfirmasi' && (
                        <button className="p-1.5 rounded-lg bg-amber-50 text-amber-600 hover:bg-amber-100 transition-colors" title="Edit">
                          <Edit2 size={14} />
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          {filtered.length === 0 && (
            <div className="text-center py-16 text-slate-400">
              <Search size={40} className="mx-auto mb-3 opacity-30" />
              <p className="text-sm">Tidak ada pemesanan ditemukan</p>
            </div>
          )}
        </div>
      </Card>
    </Layout>
  );
}
