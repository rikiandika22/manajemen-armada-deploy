import { useState, useRef, useEffect } from 'react';
import { Bell, Search } from 'lucide-react';
import { useLocation } from 'react-router-dom';

const PAGE_TITLES = {
  '/armada': 'Data Armada',
  '/jadwal': 'Jadwal Armada',
  '/pemesanan': 'Pemesanan',
  '/pembayaran': 'Pembayaran',
  '/sopir': 'Data Sopir',
  '/laporan': 'Laporan',
  '/pengaturan': 'Pengaturan',
};

const DUMMY_NOTIFS = [
  { id: 1, title: 'Pesanan Baru', desc: 'Ada pesanan masuk untuk Bus Medium', time: '5 mnt lalu' },
  { id: 2, title: 'Pembayaran Sukses', desc: 'Pembayaran INV-001 telah dikonfirmasi', time: '1 jam lalu' },
  { id: 3, title: 'Jadwal Berubah', desc: 'Jadwal armada H 1234 AA mengalami perubahan rute', time: '2 jam lalu' },
];

export default function Topbar({ isOpen, setIsOpen }) {
  const { pathname } = useLocation();
  const isDash = pathname === '/dashboard';
  const [showNotif, setShowNotif] = useState(false);
  const notifRef = useRef(null);

  useEffect(() => {
    const handleClickOutside = (event) => {
      if (notifRef.current && !notifRef.current.contains(event.target)) {
        setShowNotif(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, []);

  return (
    <header
      className="fixed top-0 right-0 z-40 flex items-center justify-between px-7 bg-white border-b border-slate-200 transition-all duration-300"
      style={{ height: 62, left: isOpen ? 230 : 80 }}
    >
      {/* Left: title */}
      {isDash ? (
        <h1 className="text-xl font-bold text-slate-800 tracking-tight">
          Dashboard
        </h1>
      ) : (
        <h1 className="text-lg font-bold text-slate-800">
          {PAGE_TITLES[pathname] || 'Dashboard'}
        </h1>
      )}

      {/* Right: search + bell + avatar */}
      <div className="flex items-center gap-3">
        {/* Search */}
        <div className="relative">
          <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
          <input
            type="text"
            placeholder="Search..."
            className="pl-8 pr-4 py-2 rounded-full text-sm bg-slate-100 text-slate-700 placeholder-slate-400 focus:outline-none focus:bg-white border border-transparent focus:border-slate-300 transition-all"
            style={{ width: 200 }}
          />
        </div>

        {/* Bell */}
        <div className="relative" ref={notifRef}>
          <button 
            onClick={() => setShowNotif(!showNotif)}
            className="relative w-9 h-9 rounded-full bg-slate-100 flex items-center justify-center hover:bg-slate-200 transition-colors"
          >
            <Bell size={16} className="text-slate-600" />
            <span
              className="absolute top-1.5 right-1.5 w-2 h-2 rounded-full border-2 border-white"
              style={{ backgroundColor: '#ef4444' }}
            />
          </button>

          {/* Dropdown Notif */}
          {showNotif && (
            <div className="absolute right-0 mt-2 w-72 bg-white rounded-xl shadow-[0_10px_40px_rgba(0,0,0,0.1)] border border-slate-100 overflow-hidden z-50">
              <div className="px-4 py-3 border-b border-slate-100 bg-slate-50/80 flex justify-between items-center">
                <h3 className="text-sm font-bold text-slate-800">Notifikasi</h3>
                <span className="text-xs text-[#a3e635] font-semibold cursor-pointer hover:opacity-80 transition-opacity">Tandai dibaca</span>
              </div>
              <div className="max-h-80 overflow-y-auto">
                {DUMMY_NOTIFS.map((notif) => (
                  <div key={notif.id} className="px-4 py-3 border-b border-slate-50 hover:bg-slate-50/80 transition-colors cursor-pointer">
                    <p className="text-sm font-bold text-slate-700 leading-tight">{notif.title}</p>
                    <p className="text-xs text-slate-500 mt-1 leading-snug">{notif.desc}</p>
                    <p className="text-[10px] text-slate-400 mt-1.5 font-medium">{notif.time}</p>
                  </div>
                ))}
              </div>
              <div className="px-4 py-2.5 text-center bg-slate-50/80 border-t border-slate-100 cursor-pointer hover:bg-slate-100 transition-colors">
                <p className="text-xs font-semibold text-slate-600">Lihat semua notifikasi</p>
              </div>
            </div>
          )}
        </div>

        {/* Avatar */}
        <div
          className="w-9 h-9 rounded-full flex items-center justify-center text-white text-sm font-bold cursor-pointer hover:opacity-90 transition-opacity border-2"
          style={{
            background: 'linear-gradient(135deg, #334155, #0f172a)',
            borderColor: '#a3e635',
          }}
        >
          A
        </div>
      </div>
    </header>
  );
}
