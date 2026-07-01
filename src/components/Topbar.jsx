import { useState, useRef, useEffect } from 'react';
import { Bell, Search, Loader2, FileText, CreditCard, Truck, Calendar as CalendarIcon } from 'lucide-react';
import { useLocation, useNavigate } from 'react-router-dom';
import { useNotifications } from '../contexts/NotificationContext';
import { globalSearch } from '../services/api';

const PAGE_TITLES = {
  '/armada': 'Data Armada',
  '/jadwal': 'Jadwal Armada',
  '/pemesanan': 'Pemesanan',
  '/pembayaran': 'Pembayaran',
  '/sopir': 'Data Sopir',
  '/laporan': 'Laporan',
  '/pengaturan': 'Pengaturan',
};

const TYPE_ICONS = {
  'order': <FileText size={16} className="text-blue-500" />,
  'payment': <CreditCard size={16} className="text-orange-500" />,
  'fleet': <Truck size={16} className="text-green-500" />,
  'schedule': <CalendarIcon size={16} className="text-purple-500" />
};

const TYPE_LABELS = {
  'order': 'Pesanan',
  'payment': 'Pembayaran',
  'fleet': 'Armada',
  'schedule': 'Jadwal'
};

export default function Topbar({ isOpen, setIsOpen }) {
  const { pathname } = useLocation();
  const navigate = useNavigate();
  const { notifications } = useNotifications();
  const isDash = pathname === '/dashboard';
  
  const [showNotif, setShowNotif] = useState(false);
  const notifRef = useRef(null);

  // Global Search State
  const [searchQuery, setSearchQuery] = useState('');
  const [searchResults, setSearchResults] = useState(null);
  const [isSearching, setIsSearching] = useState(false);
  const [showSearch, setShowSearch] = useState(false);
  const searchRef = useRef(null);
  const debounceTimeout = useRef(null);

  useEffect(() => {
    const handleClickOutside = (event) => {
      if (notifRef.current && !notifRef.current.contains(event.target)) {
        setShowNotif(false);
      }
      if (searchRef.current && !searchRef.current.contains(event.target)) {
        setShowSearch(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, []);

  // Close search on route change
  useEffect(() => {
    setShowSearch(false);
    setSearchQuery('');
  }, [pathname]);

  const handleSearchChange = (e) => {
    const value = e.target.value;
    setSearchQuery(value);

    if (value.trim().length < 2) {
      setSearchResults(null);
      if (value.trim().length === 0) {
        setShowSearch(false);
      } else {
        setShowSearch(true);
      }
      return;
    }

    setShowSearch(true);
    setIsSearching(true);

    if (debounceTimeout.current) {
      clearTimeout(debounceTimeout.current);
    }

    debounceTimeout.current = setTimeout(async () => {
      try {
        const res = await globalSearch(value);
        setSearchResults(res.data.data);
      } catch (err) {
        console.error('Search error', err);
        setSearchResults('error');
      } finally {
        setIsSearching(false);
      }
    }, 400); // 400ms debounce
  };

  const handleKeyDown = (e) => {
    if (e.key === 'Escape') {
      setShowSearch(false);
    }
  };

  const handleResultClick = (result) => {
    setShowSearch(false);
    setSearchQuery('');
    
    // Construct search param based on target page and available unique id
    let searchParam = '';
    if (result.type === 'order') searchParam = result.order_code;
    if (result.type === 'payment') searchParam = result.order_code;
    if (result.type === 'schedule') searchParam = result.order_code;
    if (result.type === 'fleet') searchParam = result.kode_armada;

    navigate(`/${result.target_page}?search=${encodeURIComponent(searchParam)}`);
  };

  const renderSearchDropdown = () => {
    if (!showSearch) return null;

    return (
      <div className="absolute top-full left-0 mt-2 w-80 bg-white rounded-xl shadow-[0_10px_40px_rgba(0,0,0,0.12)] border border-slate-100 overflow-hidden z-50">
        {searchQuery.trim().length === 1 ? (
          <div className="p-4 text-center text-xs text-slate-500 font-medium">
            Ketik minimal 2 karakter untuk mencari...
          </div>
        ) : isSearching ? (
          <div className="p-6 flex flex-col items-center justify-center text-slate-400">
            <Loader2 className="animate-spin mb-2" size={24} />
            <span className="text-xs font-medium">Mencari data...</span>
          </div>
        ) : searchResults === 'error' ? (
          <div className="p-4 text-center text-xs font-medium text-red-500 bg-red-50">
            Gagal memuat hasil pencarian.
          </div>
        ) : searchResults ? (
          <div className="max-h-[70vh] overflow-y-auto">
            {Object.keys(searchResults).every(k => searchResults[k].length === 0) ? (
              <div className="p-6 text-center text-xs font-medium text-slate-500">
                Tidak ada hasil ditemukan.
              </div>
            ) : (
              Object.entries(searchResults).map(([category, items]) => {
                if (items.length === 0) return null;
                const typeMap = { 'orders': 'order', 'payments': 'payment', 'fleets': 'fleet', 'schedules': 'schedule' };
                const cType = typeMap[category];
                return (
                  <div key={category}>
                    <div className="px-4 py-2 bg-slate-50/80 border-b border-t border-slate-100 first:border-t-0 flex items-center gap-2 sticky top-0 z-10 backdrop-blur-sm">
                      <span className="text-[10px] font-bold text-slate-500 uppercase tracking-wider">
                        {TYPE_LABELS[cType]}
                      </span>
                      <span className="text-[10px] bg-slate-200 text-slate-600 px-1.5 py-0.5 rounded-md font-bold">
                        {items.length}
                      </span>
                    </div>
                    {items.map((item) => (
                      <div 
                        key={`${item.type}-${item.id}`}
                        onClick={() => handleResultClick(item)}
                        className="p-3 border-b border-slate-50 hover:bg-lime-50/50 cursor-pointer transition-colors group"
                      >
                        <div className="flex items-start gap-3">
                          <div className="mt-0.5 p-1.5 bg-slate-100 rounded-lg group-hover:bg-white group-hover:shadow-sm transition-all">
                            {TYPE_ICONS[item.type]}
                          </div>
                          <div className="flex-1 min-w-0">
                            <h4 className="text-sm font-bold text-slate-800 leading-tight flex items-center justify-between">
                              {item.title}
                            </h4>
                            <p className="text-xs font-semibold text-slate-600 mt-0.5 truncate">{item.subtitle}</p>
                            <p className="text-[11px] text-slate-400 mt-0.5 truncate">{item.description}</p>
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                );
              })
            )}
          </div>
        ) : null}
      </div>
    );
  };

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
        <div className="relative" ref={searchRef}>
          <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
          <input
            type="text"
            placeholder="Cari pesanan, armada..."
            value={searchQuery}
            onChange={handleSearchChange}
            onKeyDown={handleKeyDown}
            onFocus={() => {
              if (searchQuery.trim().length > 0) setShowSearch(true);
            }}
            className="pl-8 pr-4 py-2 rounded-full text-sm bg-slate-100 text-slate-700 placeholder-slate-400 focus:outline-none focus:bg-white border border-transparent focus:border-slate-300 transition-all"
            style={{ width: 220 }}
          />
          {renderSearchDropdown()}
        </div>

        {/* Bell */}
        <div className="relative" ref={notifRef}>
          <button 
            onClick={() => setShowNotif(!showNotif)}
            className="relative w-9 h-9 rounded-full bg-slate-100 flex items-center justify-center hover:bg-slate-200 transition-colors"
          >
            <Bell size={16} className="text-slate-600" />
            {notifications.total > 0 && (
              <span
                className="absolute top-0 right-0 w-4 h-4 rounded-full border border-white flex items-center justify-center text-[8px] font-bold text-white"
                style={{ backgroundColor: '#ef4444' }}
              >
                {notifications.total > 99 ? '99+' : notifications.total}
              </span>
            )}
          </button>

          {/* Dropdown Notif */}
          {showNotif && (
            <div className="absolute right-0 mt-2 w-72 bg-white rounded-xl shadow-[0_10px_40px_rgba(0,0,0,0.1)] border border-slate-100 overflow-hidden z-50">
              <div className="px-4 py-3 border-b border-slate-100 bg-slate-50/80 flex justify-between items-center">
                <h3 className="text-sm font-bold text-slate-800">Ringkasan Notifikasi</h3>
              </div>
              <div className="max-h-80 overflow-y-auto">
                {notifications.total === 0 ? (
                  <div className="px-4 py-4 text-center">
                    <p className="text-xs font-semibold text-slate-500">Tidak ada notifikasi baru</p>
                  </div>
                ) : (
                  <>
                    {notifications.pemesanan?.count > 0 && (
                      <div 
                        onClick={() => { navigate('/pemesanan'); setShowNotif(false); }}
                        className="px-4 py-3 border-b border-slate-50 hover:bg-slate-50/80 transition-colors cursor-pointer"
                      >
                        <p className="text-sm font-bold text-slate-700 leading-tight">Pesanan Baru</p>
                        <p className="text-xs text-slate-500 mt-1 leading-snug">{notifications.pemesanan.label}</p>
                        <p className="text-[10px] text-[#ef4444] mt-1.5 font-bold">{notifications.pemesanan.count} item</p>
                      </div>
                    )}
                    {notifications.pembayaran?.count > 0 && (
                      <div 
                        onClick={() => { navigate('/pembayaran'); setShowNotif(false); }}
                        className="px-4 py-3 border-b border-slate-50 hover:bg-slate-50/80 transition-colors cursor-pointer"
                      >
                        <p className="text-sm font-bold text-slate-700 leading-tight">Validasi Pembayaran</p>
                        <p className="text-xs text-slate-500 mt-1 leading-snug">{notifications.pembayaran.label}</p>
                        <p className="text-[10px] text-[#ef4444] mt-1.5 font-bold">{notifications.pembayaran.count} item</p>
                      </div>
                    )}
                    {notifications.jadwal?.count > 0 && (
                      <div 
                        onClick={() => { navigate('/jadwal'); setShowNotif(false); }}
                        className="px-4 py-3 border-b border-slate-50 hover:bg-slate-50/80 transition-colors cursor-pointer"
                      >
                        <p className="text-sm font-bold text-slate-700 leading-tight">Penyelesaian Jadwal</p>
                        <p className="text-xs text-slate-500 mt-1 leading-snug">{notifications.jadwal.label}</p>
                        <p className="text-[10px] text-[#ef4444] mt-1.5 font-bold">{notifications.jadwal.count} item</p>
                      </div>
                    )}
                  </>
                )}
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
