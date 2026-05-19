import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Mail, Lock, Eye, EyeOff, ArrowRight, User } from 'lucide-react';
import logoImg from '../assets/logo.png';
import api from '../services/api';

export default function Login() {
  const navigate = useNavigate();
  const [showPassword, setShowPassword] = useState(false);
  const [formData, setFormData] = useState({ identifier: '', password: '' });
  const [error, setError] = useState('');

  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!formData.identifier || !formData.password) {
      setError('Email/Username dan Kata Sandi wajib diisi.');
      return;
    }
    
    setIsLoading(true);
    try {
      const response = await api.post('/login', {
        login: formData.identifier,
        password: formData.password
      });
      
      const { token, user } = response.data;
      
      // Simpan token dan data admin
      localStorage.setItem('token', token);
      localStorage.setItem('user', JSON.stringify(user));
      
      navigate('/dashboard');
    } catch (err) {
      setError(err.response?.data?.message || 'Terjadi kesalahan saat login.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-slate-100 font-sans p-6">
      {/* ── Main Container ── */}
      <div className="w-full max-w-5xl flex flex-col md:flex-row bg-white rounded-xl shadow-[0_20px_60px_rgba(0,0,0,0.1)] overflow-hidden min-h-[600px]">
        
        {/* ── Left Column (Brand/Info) ── */}
        <div className="w-full md:w-1/2 bg-[#1b202e] p-10 md:p-14 flex flex-col justify-between relative">
          
          {/* Logo & Brand */}
          <div className="flex items-center gap-3">
            <img src={logoImg} alt="Logo SAT" className="w-8 h-8 object-contain" />
            <h1 className="text-xl font-bold text-white tracking-tight">
              Sumber Agung <span className="text-[#a3e635]">Trans</span>
            </h1>
          </div>

          {/* Titles & Desc */}
          <div className="mt-16 md:mt-24 mb-16 md:mb-24">
            <h2 className="text-3xl md:text-4xl font-bold text-white leading-tight mb-4 tracking-tight">
              Sistem Manajemen<br />
              <span className="text-[#a3e635]">Transportasi Terpadu</span>
            </h2>
            <p className="text-slate-400 text-sm md:text-base leading-relaxed max-w-sm">
              Akses dashboard admin untuk mengelola armada, jadwal, dan memantau operasional harian dengan mudah dan efisien.
            </p>
          </div>

          {/* Bottom Accent */}
          <div>
            <div className="w-12 h-1 bg-[#a3e635] rounded-full"></div>
          </div>
        </div>

        {/* ── Right Column (Login Form) ── */}
        <div className="w-full md:w-1/2 p-10 md:p-14 flex flex-col justify-center">
          
          <div className="mb-8">
            <h2 className="text-3xl font-bold text-slate-800 mb-2 tracking-tight">Selamat Datang</h2>
            <p className="text-slate-500 text-sm">Silakan masuk ke akun admin Anda.</p>
          </div>

          {error && (
            <div className="mb-6 p-3 rounded-lg bg-red-50 border border-red-100 text-sm text-red-600 font-medium flex items-center">
              <span className="mr-2">⚠️</span>
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-6">
            
            {/* Field Identifier */}
            <div className="space-y-1.5">
              <label className="text-xs font-semibold text-slate-600 block">Email atau Username</label>
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none">
                  <User size={16} className="text-slate-400" />
                </div>
                <input
                  type="text"
                  placeholder="Masukkan email atau username"
                  value={formData.identifier}
                  onChange={(e) => {
                    setFormData({ ...formData, identifier: e.target.value });
                    setError('');
                  }}
                  className="w-full pl-10 pr-4 py-2.5 bg-white border border-slate-200 rounded-lg text-sm text-slate-800 placeholder-slate-300 focus:outline-none focus:ring-2 focus:ring-[#a3e635]/50 focus:border-[#a3e635] transition-all"
                />
              </div>
            </div>

            {/* Field Password */}
            <div className="space-y-1.5">
              <label className="text-xs font-semibold text-slate-600 block">Kata Sandi</label>
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none">
                  <Lock size={16} className="text-slate-400" />
                </div>
                <input
                  type={showPassword ? 'text' : 'password'}
                  placeholder="Masukkan kata sandi"
                  value={formData.password}
                  onChange={(e) => {
                    setFormData({ ...formData, password: e.target.value });
                    setError('');
                  }}
                  className="w-full pl-10 pr-10 py-2.5 bg-white border border-slate-200 rounded-lg text-sm text-slate-800 placeholder-slate-300 focus:outline-none focus:ring-2 focus:ring-[#a3e635]/50 focus:border-[#a3e635] transition-all"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute inset-y-0 right-0 pr-3.5 flex items-center text-slate-400 hover:text-slate-600 transition-colors"
                >
                  {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                </button>
              </div>
            </div>

            {/* Options */}
            <div className="flex items-center justify-between pt-1">
              <label className="flex items-center gap-2 cursor-pointer">
                <input
                  type="checkbox"
                  className="w-3.5 h-3.5 rounded border-slate-300 text-[#a3e635] focus:ring-[#a3e635] cursor-pointer"
                />
                <span className="text-xs text-slate-500 font-medium">Ingat saya</span>
              </label>
              <a href="#" className="text-xs font-bold text-slate-800 hover:text-slate-600 transition-colors">
                Lupa Password?
              </a>
            </div>

            <button
              type="submit"
              disabled={isLoading}
              className="w-full py-3 bg-[#a3e635] hover:bg-[#84cc16] disabled:opacity-70 text-[#0f172a] font-bold rounded-full shadow-sm transition-all flex items-center justify-center gap-2 mt-4"
            >
              <span>{isLoading ? 'Memproses...' : 'Masuk'}</span>
              {!isLoading && <ArrowRight size={16} />}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
}
