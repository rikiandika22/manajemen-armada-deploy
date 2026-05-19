import { useState, useRef, useEffect } from 'react';
import { Search, Plus, Eye, Edit2, Trash2, User, X, Camera, Phone, MapPin, ChevronDown } from 'lucide-react';
import Layout from '../components/Layout';
import Card from '../components/Card';
import Badge from '../components/Badge';
import { mockSopir } from '../data/mockData';

function FormDropdown({ options, value, onChange }) {
  const [isOpen, setIsOpen] = useState(false);
  const dropdownRef = useRef(null);

  useEffect(() => {
    function handleClickOutside(event) {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target)) {
        setIsOpen(false);
      }
    }
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  return (
    <div className="relative inline-block w-full text-left" ref={dropdownRef}>
      <button
        type="button"
        onClick={() => setIsOpen(!isOpen)}
        className="flex items-center justify-between w-full pl-3 pr-4 py-2.5 bg-slate-50 border border-transparent rounded-lg text-sm text-slate-700 hover:bg-slate-100 focus:bg-white focus:border-slate-300 focus:outline-none transition-colors"
      >
        <span>{value}</span>
        <ChevronDown size={16} className={`text-slate-400 transition-transform duration-200 ${isOpen ? 'rotate-180' : ''}`} />
      </button>

      {isOpen && (
        <div className="absolute left-0 mt-1 w-full origin-top rounded-xl bg-white shadow-[0_10px_40px_rgba(0,0,0,0.12)] focus:outline-none z-50 overflow-hidden border border-slate-100 animate-in fade-in zoom-in-95 duration-100">
          <div className="py-1">
            {options.map((option) => (
              <button
                key={option}
                type="button"
                onClick={() => {
                  onChange(option);
                  setIsOpen(false);
                }}
                className={`block w-full text-left px-4 py-2.5 text-sm hover:bg-slate-50 transition-colors ${value === option ? 'text-emerald-600 bg-emerald-50/50 font-semibold' : 'text-slate-700 font-medium'}`}
              >
                {option}
              </button>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

export default function Sopir() {
  const [search, setSearch] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [formStatus, setFormStatus] = useState('Aktif');

  const filtered = mockSopir.filter((s) =>
    s.nama.toLowerCase().includes(search.toLowerCase()) ||
    s.telepon.includes(search)
  );

  return (
    <Layout>
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
        <div>
          <h2 className="text-xl font-bold text-slate-800">Data Sopir</h2>
          <p className="text-sm text-slate-500 mt-0.5">Kelola data sopir sebagai data operasional</p>
        </div>
        <button
          onClick={() => setShowModal(true)}
          className="flex items-center gap-2 px-4 py-2.5 rounded-xl text-sm font-semibold text-slate-900 hover:opacity-90 transition-opacity shadow-sm"
          style={{ backgroundColor: '#a3e635' }}
        >
          <Plus size={16} />
          Tambah Sopir
        </button>
      </div>

      {/* Stat cards */}
      <div className="grid grid-cols-2 gap-4 mb-5">
        <Card className="p-4">
          <p className="text-2xl font-bold text-slate-800">{mockSopir.filter(s => s.status === 'Aktif').length}</p>
          <p className="text-sm text-slate-500 mt-0.5">Sopir Aktif</p>
        </Card>
        <Card className="p-4">
          <p className="text-2xl font-bold text-slate-400">{mockSopir.filter(s => s.status === 'Tidak Aktif').length}</p>
          <p className="text-sm text-slate-500 mt-0.5">Sopir Tidak Aktif</p>
        </Card>
      </div>

      {/* Search */}
      <Card className="p-4 mb-5">
        <div className="relative max-w-md">
          <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
          <input
            type="text"
            placeholder="Cari nama atau nomor telepon sopir..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full pl-9 pr-4 py-2.5 border border-slate-200 rounded-xl text-sm bg-white text-slate-700 placeholder-slate-400 focus:outline-none focus:ring-2"
          />
        </div>
      </Card>

      {/* Table */}
      <Card>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-white">
              <tr className="border-b border-slate-200">
                {['ID Sopir', 'Nama Sopir', 'No. Telepon', 'Alamat', 'Status', 'Armada Ditugaskan', 'Aksi'].map((h) => (
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
                        className="w-9 h-9 rounded-full flex items-center justify-center text-white text-sm font-bold flex-shrink-0"
                        style={{ background: 'linear-gradient(135deg, #0f172a, #334155)' }}
                      >
                        {row.nama.charAt(0)}
                      </div>
                      <div>
                        <p className="text-sm font-semibold text-slate-800">{row.nama}</p>
                      </div>
                    </div>
                  </td>
                  <td className="px-5 py-4 text-sm text-slate-600">{row.telepon}</td>
                  <td className="px-5 py-4 text-sm text-slate-600 max-w-48">
                    <span className="truncate block">{row.alamat}</span>
                  </td>
                  <td className="px-5 py-4"><Badge status={row.status} /></td>
                  <td className="px-5 py-4 text-sm text-slate-700">{row.armada}</td>
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
              <User size={40} className="mx-auto mb-3 opacity-30" />
              <p className="text-sm">Tidak ada data sopir ditemukan</p>
            </div>
          )}
        </div>
      </Card>
      {/* Modal Tambah Data Sopir */}
      {showModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/40 backdrop-blur-sm transition-opacity">
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-md overflow-hidden animate-in fade-in zoom-in-95 duration-200">
            {/* Header */}
            <div className="flex items-center justify-between px-6 py-4 border-b border-slate-100">
              <h3 className="text-lg font-bold text-slate-800">Tambah Data Sopir</h3>
              <button onClick={() => setShowModal(false)} className="text-slate-400 hover:text-slate-600 transition-colors">
                <X size={20} />
              </button>
            </div>

            {/* Body */}
            <div className="px-6 py-5 space-y-4">
              {/* Upload Foto */}
              <div className="flex flex-col items-center justify-center mb-6">
                <div className="w-20 h-20 rounded-full border-2 border-dashed border-slate-300 bg-slate-50 flex items-center justify-center cursor-pointer hover:bg-slate-100 transition-colors">
                  <Camera size={24} className="text-slate-400" />
                </div>
                <span className="text-xs text-slate-500 mt-2 font-medium">Unggah Foto Profil</span>
              </div>

              {/* Form Fields */}
              <div className="space-y-4">
                {/* Nama Lengkap */}
                <div>
                  <label className="block text-xs font-semibold text-slate-600 mb-1.5">Nama Lengkap</label>
                  <div className="relative">
                    <User size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                    <input type="text" placeholder="Masukkan nama lengkap" className="w-full pl-9 pr-4 py-2.5 bg-slate-50 border border-transparent rounded-lg text-sm text-slate-700 placeholder-slate-400 focus:bg-white focus:border-slate-300 focus:outline-none transition-colors" />
                  </div>
                </div>

                {/* No. Telepon */}
                <div>
                  <label className="block text-xs font-semibold text-slate-600 mb-1.5">No. Telepon</label>
                  <div className="relative">
                    <Phone size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                    <input type="text" placeholder="Masukkan nomor telepon" className="w-full pl-9 pr-4 py-2.5 bg-slate-50 border border-transparent rounded-lg text-sm text-slate-700 placeholder-slate-400 focus:bg-white focus:border-slate-300 focus:outline-none transition-colors" />
                  </div>
                </div>

                {/* Alamat */}
                <div>
                  <label className="block text-xs font-semibold text-slate-600 mb-1.5">Alamat</label>
                  <div className="relative">
                    <MapPin size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                    <input type="text" placeholder="Masukkan alamat lengkap" className="w-full pl-9 pr-4 py-2.5 bg-slate-50 border border-transparent rounded-lg text-sm text-slate-700 placeholder-slate-400 focus:bg-white focus:border-slate-300 focus:outline-none transition-colors" />
                  </div>
                </div>

                {/* Status */}
                <div>
                  <label className="block text-xs font-semibold text-slate-600 mb-1.5">Status</label>
                  <FormDropdown 
                    options={['Aktif', 'Tidak Aktif']}
                    value={formStatus}
                    onChange={setFormStatus}
                  />
                </div>
              </div>
            </div>

            {/* Footer */}
            <div className="px-6 py-4 border-t border-slate-100 flex items-center justify-center sm:justify-end gap-3 bg-white">
              <button 
                onClick={() => setShowModal(false)}
                className="px-6 py-2.5 text-sm font-semibold text-slate-700 bg-white border border-slate-200 rounded-full hover:bg-slate-50 transition-colors w-full sm:w-auto"
              >
                Batal
              </button>
              <button 
                onClick={() => setShowModal(false)}
                className="px-6 py-2.5 text-sm font-semibold text-slate-900 rounded-full hover:opacity-90 transition-opacity shadow-sm w-full sm:w-auto"
                style={{ backgroundColor: '#a3e635' }}
              >
                Simpan Data
              </button>
            </div>
          </div>
        </div>
      )}
    </Layout>
  );
}
