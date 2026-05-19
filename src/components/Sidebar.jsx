import { NavLink, useNavigate } from 'react-router-dom';
import {
  LayoutDashboard, Truck, Calendar, ShoppingCart,
  CreditCard, User, BarChart3, Settings, LogOut,
  Smartphone, ArrowUpRight, Menu, ChevronLeft, ChevronRight
} from 'lucide-react';
import logoImg from '../assets/logo.png';
import api from '../services/api';

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
        {NAV.map(({ to, Icon, label }) => (
          <NavLink key={to} to={to} className="block" title={!isOpen ? label : undefined}>
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
                <Icon size={17} className="flex-shrink-0" />
                {isOpen && <span className="whitespace-nowrap">{label}</span>}
              </div>
            )}
          </NavLink>
        ))}
      </nav>

      {/* ── Download App ── */}
      {isOpen && (
        <div className="mx-3 mb-3">
          <div className="rounded-2xl px-4 py-3.5" style={{ backgroundColor: '#1e293b' }}>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2.5">
                <div
                  className="w-8 h-8 rounded-xl flex items-center justify-center flex-shrink-0"
                  style={{ backgroundColor: 'rgba(163,230,53,0.15)' }}
                >
                  <Smartphone size={16} style={{ color: ACTIVE_COLOR }} />
                </div>
                <span className="text-xs font-medium whitespace-nowrap" style={{ color: '#94a3b8' }}>Download App</span>
              </div>
              <div
                className="w-7 h-7 rounded-full flex items-center justify-center flex-shrink-0"
                style={{ backgroundColor: ACTIVE_COLOR }}
              >
                <ArrowUpRight size={14} color="#0f172a" />
              </div>
            </div>
          </div>
        </div>
      )}

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
