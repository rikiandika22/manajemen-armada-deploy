import { NavLink, useNavigate } from 'react-router-dom';
import {
  LayoutDashboard, Truck, Calendar, ShoppingCart,
  CreditCard, User, BarChart3, Settings, LogOut,
  Smartphone, ArrowUpRight, Menu, ChevronLeft, ChevronRight
} from 'lucide-react';
import logoImg from '../assets/logo.png';
import api from '../services/api';
import { useNotifications } from '../contexts/NotificationContext';

const NAV = [
  { to: '/dashboard',  Icon: LayoutDashboard, label: 'Dashboard'   },
  { to: '/armada',     Icon: Truck,           label: 'Armada'      },
  { to: '/jadwal',     Icon: Calendar,        label: 'Jadwal'      },
  { to: '/pemesanan',  Icon: ShoppingCart,    label: 'Pemesanan'   },
  { to: '/pembayaran', Icon: CreditCard,      label: 'Pembayaran'  },
  { to: '/sopir',      Icon: User,            label: 'Sopir'       },
  { to: '/laporan',    Icon: BarChart3,       label: 'Laporan'     },
];

const SIDEBAR_BG   = '#13192b';
const ACTIVE_COLOR = '#a3e635';

export default function Sidebar({ isOpen, setIsOpen }) {
  const navigate = useNavigate();
  const { notifications } = useNotifications();

  const getBadgeCount = (label) => {
    if (label === 'Pemesanan') return notifications.pemesanan?.count || 0;
    if (label === 'Pembayaran') return notifications.pembayaran?.count || 0;
    if (label === 'Jadwal') return notifications.jadwal?.count || 0;
    return 0;
  };

  return (
    <aside
      className="fixed top-0 left-0 h-full flex flex-col overflow-y-auto sidebar-scroll z-50 transition-all duration-300"
      style={{ width: isOpen ? 230 : 80, backgroundColor: SIDEBAR_BG }}
    >
      {/* ── Logo & Toggle ── */}
      <div className={`flex items-center ${isOpen ? 'justify-between px-4' : 'flex-col justify-center gap-4 py-4'} border-b border-white/5 min-h-[76px]`}>
        <div className="flex items-center gap-2.5 overflow-hidden">
          <div
            className="w-9 h-9 rounded-xl overflow-hidden flex-shrink-0 flex items-center justify-center"
            style={{ backgroundColor: 'rgba(255,255,255,0.08)' }}
          >
            <img src={logoImg} alt="Logo SAT" className="w-7 h-7 object-contain" />
          </div>
          
          {isOpen && (
            <div className="flex-shrink-0">
              <p className="text-white font-bold text-sm leading-tight">Sumber Agung</p>
              <p className="font-bold text-sm leading-tight" style={{ color: ACTIVE_COLOR }}>Trans</p>
            </div>
          )}
        </div>
        
        <button 
          onClick={() => setIsOpen(!isOpen)}
          title={isOpen ? "Tutup Sidebar" : "Buka Sidebar"}
          className="flex items-center justify-center w-7 h-7 rounded-lg hover:bg-white/10 transition-colors text-slate-400 hover:text-white flex-shrink-0"
        >
          {isOpen ? <ChevronLeft size={20} /> : <Menu size={20} />}
        </button>
      </div>

      {/* ── Nav ── */}
      <nav className="flex-1 px-3 py-4 space-y-3 overflow-x-hidden">
        {NAV.map(({ to, Icon, label }) => {
          const count = getBadgeCount(label);
          return (
            <NavLink key={to} to={to} className="block" title={!isOpen ? label : undefined}>
              {({ isActive }) => (
                <div
                  className={`relative flex items-center ${isOpen ? 'justify-between px-4' : 'justify-center px-0'} py-2.5 rounded-xl text-sm font-medium cursor-pointer transition-all duration-150`}
                  style={{
                    backgroundColor: isActive ? ACTIVE_COLOR : 'transparent',
                    color: isActive ? '#0f172a' : '#94a3b8',
                  }}
                  onMouseEnter={(e) => { if (!isActive) { e.currentTarget.style.backgroundColor = 'rgba(255,255,255,0.06)'; e.currentTarget.style.color = '#e2e8f0'; } }}
                  onMouseLeave={(e) => { if (!isActive) { e.currentTarget.style.backgroundColor = 'transparent'; e.currentTarget.style.color = '#94a3b8'; } }}
                >
                  <div className={`flex items-center ${isOpen ? 'gap-3' : 'justify-center'}`}>
                    <Icon size={17} className="flex-shrink-0" />
                    {isOpen && <span className="whitespace-nowrap">{label}</span>}
                  </div>
                  {count > 0 && (
                    <span 
                      className={`flex items-center justify-center rounded-full text-[10px] font-bold ${isOpen ? 'min-w-[20px] h-[20px] px-1' : 'absolute top-1 right-1 w-4 h-4 text-[8px]'}`}
                      style={{ backgroundColor: '#ef4444', color: '#fff' }}
                    >
                      {count > 99 ? '99+' : count}
                    </span>
                  )}
                </div>
              )}
            </NavLink>
          );
        })}
      </nav>


      {/* ── Bottom Actions ── */}
      <div className="px-3 pb-5 space-y-2">
        <NavLink to="/pengaturan" className="block" title={!isOpen ? 'Pengaturan' : undefined}>
          {({ isActive }) => (
            <div
              className={`flex items-center ${isOpen ? 'justify-start gap-3 px-4' : 'justify-center px-0'} py-2.5 rounded-xl text-sm font-medium cursor-pointer transition-all duration-150`}
              style={{
                backgroundColor: isActive ? ACTIVE_COLOR : 'transparent',
                color: isActive ? '#0f172a' : '#94a3b8',
              }}
              onMouseEnter={(e) => { if (!isActive) { e.currentTarget.style.backgroundColor = 'rgba(255,255,255,0.06)'; e.currentTarget.style.color = '#e2e8f0'; } }}
              onMouseLeave={(e) => { if (!isActive) { e.currentTarget.style.backgroundColor = 'transparent'; e.currentTarget.style.color = '#94a3b8'; } }}
            >
              <Settings size={17} className="flex-shrink-0" />
              {isOpen && <span>Pengaturan</span>}
            </div>
          )}
        </NavLink>

        <button
          onClick={async () => {
            try {
              await api.post('/logout');
            } catch (err) {
              console.error(err);
            } finally {
              localStorage.removeItem('token');
              localStorage.removeItem('user');
              navigate('/login');
            }
          }}
          title={!isOpen ? 'Logout' : undefined}
          className={`flex items-center ${isOpen ? 'justify-start gap-3 px-4' : 'justify-center px-0'} py-2.5 rounded-xl text-sm font-medium w-full transition-all duration-150`}
          style={{ color: '#94a3b8' }}
          onMouseEnter={(e) => { e.currentTarget.style.backgroundColor = 'rgba(255,255,255,0.06)'; e.currentTarget.style.color = '#e2e8f0'; }}
          onMouseLeave={(e) => { e.currentTarget.style.backgroundColor = 'transparent'; e.currentTarget.style.color = '#94a3b8'; }}
        >
          <LogOut size={17} className="flex-shrink-0" />
          {isOpen && <span>Logout</span>}
        </button>
      </div>
    </aside>
  );
}
