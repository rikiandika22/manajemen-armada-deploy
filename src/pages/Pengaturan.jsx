import { useState } from 'react';
import { Save, Eye, EyeOff, Building2, Phone, MapPin, User, Lock } from 'lucide-react';
import Layout from '../components/Layout';
import Card from '../components/Card';

export default function Pengaturan() {
  const [showPassword, setShowPassword] = useState(false);
  const [showNewPassword, setShowNewPassword] = useState(false);
  const [form, setForm] = useState({
    namaAdmin: 'Admin Sumber Agung',
    emailAdmin: 'admin@sumberagungtrans.id',
    namaUsaha: 'Sumber Agung Trans',
    teleponUsaha: '0812-3456-7890',
    alamatUsaha: 'Jl. Raya Grobogan No. 45, Purwodadi, Grobogan, Jawa Tengah',
    passwordLama: '',
    passwordBaru: '',
    konfirmasiPassword: '',
  });

  const handleChange = (key, value) => setForm((prev) => ({ ...prev, [key]: value }));

  return (
    <Layout>
      <div className="mb-6">
        <h2 className="text-xl font-bold text-slate-800">Pengaturan</h2>
        <p className="text-sm text-slate-500 mt-0.5">Atur profil admin dan informasi usaha</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Profile Card */}
        <div className="lg:col-span-1">
          <Card className="p-6 text-center">
            <div
              className="w-20 h-20 rounded-full flex items-center justify-center text-white text-3xl font-bold mx-auto mb-4"
              style={{ background: 'linear-gradient(135deg, #a3e635, #65a30d)' }}
            >
              A
            </div>
            <h3 className="text-base font-bold text-slate-800">{form.namaAdmin}</h3>
            <p className="text-sm text-slate-500 mt-1">{form.emailAdmin}</p>
            <span
              className="inline-block mt-3 text-xs font-semibold px-3 py-1 rounded-full"
              style={{ backgroundColor: '#dcfce7', color: '#16a34a' }}
            >
              Admin / Pengelola
            </span>
            <div className="mt-5 pt-5 border-t border-slate-100 text-left space-y-3">
              <div className="flex items-center gap-2 text-sm text-slate-600">
                <Building2 size={15} className="text-slate-400" />
                {form.namaUsaha}
              </div>
              <div className="flex items-center gap-2 text-sm text-slate-600">
                <Phone size={15} className="text-slate-400" />
                {form.teleponUsaha}
              </div>
              <div className="flex items-start gap-2 text-sm text-slate-600">
                <MapPin size={15} className="text-slate-400 mt-0.5 flex-shrink-0" />
                <span>{form.alamatUsaha}</span>
              </div>
            </div>
          </Card>
        </div>

        {/* Settings Form */}
        <div className="lg:col-span-2 space-y-5">
          {/* Profil Admin */}
          <Card className="p-6">
            <div className="flex items-center gap-2 mb-5">
              <User size={18} className="text-slate-600" />
              <h3 className="text-sm font-bold text-slate-800">Profil Admin</h3>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-medium text-slate-600 mb-1.5">Nama Admin</label>
                <input
                  type="text"
                  value={form.namaAdmin}
                  onChange={(e) => handleChange('namaAdmin', e.target.value)}
                  className="w-full border border-slate-200 rounded-xl px-3.5 py-2.5 text-sm text-slate-800 focus:outline-none focus:ring-2"
                />
              </div>
              <div>
                <label className="block text-xs font-medium text-slate-600 mb-1.5">Email Admin</label>
                <input
                  type="email"
                  value={form.emailAdmin}
                  onChange={(e) => handleChange('emailAdmin', e.target.value)}
                  className="w-full border border-slate-200 rounded-xl px-3.5 py-2.5 text-sm text-slate-800 focus:outline-none focus:ring-2"
                />
              </div>
            </div>
          </Card>

          {/* Info Usaha */}
          <Card className="p-6">
            <div className="flex items-center gap-2 mb-5">
              <Building2 size={18} className="text-slate-600" />
              <h3 className="text-sm font-bold text-slate-800">Informasi Usaha</h3>
            </div>
            <div className="space-y-4">
              <div>
                <label className="block text-xs font-medium text-slate-600 mb-1.5">Nama Usaha</label>
                <input
                  type="text"
                  value={form.namaUsaha}
                  onChange={(e) => handleChange('namaUsaha', e.target.value)}
                  className="w-full border border-slate-200 rounded-xl px-3.5 py-2.5 text-sm text-slate-800 focus:outline-none focus:ring-2"
                />
              </div>
              <div>
                <label className="block text-xs font-medium text-slate-600 mb-1.5">Nomor Kontak Usaha</label>
                <input
                  type="text"
                  value={form.teleponUsaha}
                  onChange={(e) => handleChange('teleponUsaha', e.target.value)}
                  className="w-full border border-slate-200 rounded-xl px-3.5 py-2.5 text-sm text-slate-800 focus:outline-none focus:ring-2"
                />
              </div>
              <div>
                <label className="block text-xs font-medium text-slate-600 mb-1.5">Alamat Usaha</label>
                <textarea
                  value={form.alamatUsaha}
                  onChange={(e) => handleChange('alamatUsaha', e.target.value)}
                  rows={3}
                  className="w-full border border-slate-200 rounded-xl px-3.5 py-2.5 text-sm text-slate-800 focus:outline-none focus:ring-2 resize-none"
                />
              </div>
            </div>
          </Card>

          {/* Ubah Password */}
          <Card className="p-6">
            <div className="flex items-center gap-2 mb-5">
              <Lock size={18} className="text-slate-600" />
              <h3 className="text-sm font-bold text-slate-800">Ubah Password</h3>
            </div>
            <div className="space-y-4">
              <div>
                <label className="block text-xs font-medium text-slate-600 mb-1.5">Password Lama</label>
                <div className="relative">
                  <input
                    type={showPassword ? 'text' : 'password'}
                    value={form.passwordLama}
                    onChange={(e) => handleChange('passwordLama', e.target.value)}
                    placeholder="Masukkan password lama"
                    className="w-full border border-slate-200 rounded-xl px-3.5 py-2.5 pr-10 text-sm text-slate-800 focus:outline-none focus:ring-2 placeholder-slate-400"
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600"
                  >
                    {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                  </button>
                </div>
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-medium text-slate-600 mb-1.5">Password Baru</label>
                  <div className="relative">
                    <input
                      type={showNewPassword ? 'text' : 'password'}
                      value={form.passwordBaru}
                      onChange={(e) => handleChange('passwordBaru', e.target.value)}
                      placeholder="Password baru"
                      className="w-full border border-slate-200 rounded-xl px-3.5 py-2.5 pr-10 text-sm text-slate-800 focus:outline-none focus:ring-2 placeholder-slate-400"
                    />
                    <button
                      type="button"
                      onClick={() => setShowNewPassword(!showNewPassword)}
                      className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600"
                    >
                      {showNewPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                    </button>
                  </div>
                </div>
                <div>
                  <label className="block text-xs font-medium text-slate-600 mb-1.5">Konfirmasi Password</label>
                  <input
                    type="password"
                    value={form.konfirmasiPassword}
                    onChange={(e) => handleChange('konfirmasiPassword', e.target.value)}
                    placeholder="Ulangi password baru"
                    className="w-full border border-slate-200 rounded-xl px-3.5 py-2.5 text-sm text-slate-800 focus:outline-none focus:ring-2 placeholder-slate-400"
                  />
                </div>
              </div>
            </div>
          </Card>

          {/* Save Button */}
          <div className="flex justify-end">
            <button
              className="flex items-center gap-2 px-6 py-2.5 rounded-xl text-sm font-semibold text-slate-900 hover:opacity-90 transition-opacity shadow-sm"
              style={{ backgroundColor: '#a3e635' }}
            >
              <Save size={16} />
              Simpan Perubahan
            </button>
          </div>
        </div>
      </div>
    </Layout>
  );
}
