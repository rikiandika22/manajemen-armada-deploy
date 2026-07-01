import { useState, useRef, useEffect } from 'react';
import { createPortal } from 'react-dom';
import {
  Truck, Calendar, ClipboardList, CreditCard,
  ChevronLeft, ChevronRight, ArrowRight, ChevronDown,
  CalendarCheck, DollarSign, RefreshCw, BellRing, Loader2, AlertCircle
} from 'lucide-react';
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid,
  Tooltip, ResponsiveContainer,
} from 'recharts';
import Layout from '../components/Layout';
import { Link, useNavigate } from 'react-router-dom';
import { getDashboardData, getDashboardCalendar } from '../services/api';
import { formatRupiah } from '../utils/format';

// ─── Status pill  ──────────────────────────────────────────────
const STATUS_STYLE = {
  'Dalam Perjalanan': { bg: '#1e293b', color: '#f8fafc' },
  'Selesai':          { bg: '#dcfce7', color: '#15803d' },
  'Menunggu':         { bg: '#f1f5f9', color: '#64748b' },
  'Tersedia':         { bg: '#dbeafe', color: '#1d4ed8' },
  'Dipesan':          { bg: '#fce7f3', color: '#9d174d' },
  'Terjadwal':        { bg: '#dbeafe', color: '#1d4ed8' },
  'Dibatalkan':       { bg: '#fef2f2', color: '#991b1b' },
};
function StatusPill({ status }) {
  const s = STATUS_STYLE[status] || { bg: '#f1f5f9', color: '#64748b' };
  return (
    <span
      className="inline-block text-xs font-semibold px-3 py-1 rounded-full whitespace-nowrap"
      style={{ backgroundColor: s.bg, color: s.color }}
    >
      {status}
    </span>
  );
}

// ─── Chart tooltip ─────────────────────────────────────────────
function ChartTooltip({ active, payload, label }) {
  if (!active || !payload?.length) return null;
  return (
    <div className="bg-white rounded-xl shadow-lg border border-slate-100 px-3 py-2 text-xs z-50 relative">
      <p className="font-semibold text-slate-700 mb-1">{label}</p>
      {payload.map((e, i) => (
        <p key={i} style={{ color: e.fill }}>
          {e.name}: <strong>{e.value}</strong>
        </p>
      ))}
    </div>
  );
}

// ─── Mini Calendar ─────────────────────────────────────────────
function MiniCalendar({ calendarData, curMonth, curYear, onMonthChange, selectedDate, onSelectDate }) {
  const todayDate = new Date();
  const today = { d: todayDate.getDate(), m: todayDate.getMonth(), y: todayDate.getFullYear() };

  const m = curMonth - 1; // JS months are 0-indexed
  const y = curYear;
  const monthLabel = new Date(y, m, 1).toLocaleString('id-ID', { month: 'long' }) + ' ' + y;

  const firstDow = new Date(y, m, 1).getDay(); // Sun=0
  const daysInM  = new Date(y, m + 1, 0).getDate();
  const prevDaysInM = new Date(y, m, 0).getDate();

  const cells = [];
  for (let i = firstDow - 1; i >= 0; i--)
    cells.push({ d: prevDaysInM - i, cur: false });
  for (let d = 1; d <= daysInM; d++)
    cells.push({ d, cur: true });
  while (cells.length < 42) cells.push({ d: cells.length - daysInM - firstDow + 1, cur: false });

  const prev = () => {
    let newM = m === 0 ? 12 : m;
    let newY = m === 0 ? y - 1 : y;
    onMonthChange(newM, newY);
  };
  const next = () => {
    let newM = m === 11 ? 1 : m + 2;
    let newY = m === 11 ? y + 1 : y;
    onMonthChange(newM, newY);
  };

  const getEventData = (day) => {
    const dStr = String(day).padStart(2, '0');
    const mStr = String(m + 1).padStart(2, '0');
    const dateStr = `${y}-${mStr}-${dStr}`;
    return calendarData.find(c => c.date === dateStr);
  };

  const handleDateClick = (day, isCur) => {
    if (!isCur) return;
    const dStr = String(day).padStart(2, '0');
    const mStr = String(m + 1).padStart(2, '0');
    const dateStr = `${y}-${mStr}-${dStr}`;
    
    const data = getEventData(day);
    if (selectedDate?.date === dateStr) {
      onSelectDate(null);
    } else {
      onSelectDate({ date: dateStr, data: data || { total: 0, items: [] } });
    }
  };

  return (
    <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-4 w-full relative">
      {/* Month nav */}
      <div className="flex items-center justify-between mb-3">
        <button onClick={prev} className="w-6 h-6 flex items-center justify-center rounded-full hover:bg-slate-100 transition-colors">
          <ChevronLeft size={13} className="text-slate-500" />
        </button>
        <span className="text-sm font-semibold text-slate-800">{monthLabel}</span>
        <button onClick={next} className="w-6 h-6 flex items-center justify-center rounded-full hover:bg-slate-100 transition-colors">
          <ChevronRight size={13} className="text-slate-500" />
        </button>
      </div>

      {/* Day headers */}
      <div className="grid grid-cols-7 mb-1">
        {['M','S','S','R','K','J','S'].map((d, i) => (
          <div key={i} className="text-center text-xs font-medium text-slate-400 pb-1">{d}</div>
        ))}
      </div>

      {/* Date cells */}
      <div className="grid grid-cols-7 gap-y-0.5">
        {cells.map((cell, i) => {
          const isToday = cell.cur && cell.d === today.d && m === today.m && y === today.y;
          const eventData = cell.cur ? getEventData(cell.d) : null;
          
          const dStr = cell.cur ? String(cell.d).padStart(2, '0') : '';
          const mStr = String(m + 1).padStart(2, '0');
          const dateStr = `${y}-${mStr}-${dStr}`;
          const isSelected = selectedDate?.date === dateStr;

          let markerColor = null;
          if (eventData && eventData.total > 0) {
            const summary = eventData.status_summary;
            if (summary.perlu_diselesaikan > 0) markerColor = '#f97316'; // orange-500
            else if (summary.terjadwal > 0) markerColor = '#3b82f6'; // blue-500
            else if (summary.selesai > 0) markerColor = '#22c55e'; // green-500
            else if (summary.dibatalkan > 0) markerColor = '#ef4444'; // red-500
          }

          let bgColor = 'transparent';
          let textColor = !cell.cur ? '#cbd5e1' : '#374151';
          let fontWeight = '400';

          if (isSelected) {
            bgColor = '#3b82f6';
            textColor = '#ffffff';
            fontWeight = '600';
          } else if (isToday) {
            bgColor = '#a3e635';
            textColor = '#0f172a';
            fontWeight = '700';
          }

          return (
            <div
              key={i}
              onClick={() => handleDateClick(cell.d, cell.cur)}
              className={`flex items-center justify-center text-xs rounded-full mx-auto transition-all relative ${cell.cur ? 'cursor-pointer hover:opacity-80' : 'cursor-default'}`}
              style={{ width: 28, height: 28, backgroundColor: bgColor, color: textColor, fontWeight }}
            >
              {cell.d}
              {markerColor && !isSelected && !isToday && (
                <span className="absolute bottom-0.5 w-1 h-1 rounded-full" style={{ backgroundColor: markerColor }}></span>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}

// ─── Calendar Panel ─────────────────────────────────────────────
function CalendarPanel({ selectedDate }) {
  const navigate = useNavigate();
  const dateObj = new Date(selectedDate.date);
  const formattedDate = dateObj.toLocaleDateString('id-ID', { day: 'numeric', month: 'long', year: 'numeric' });
  const data = selectedDate.data;

  // Aggregate fleet types
  const fleetSummary = {};
  data.items?.forEach(item => {
    if (item.fleet_type) {
      fleetSummary[item.fleet_type] = (fleetSummary[item.fleet_type] || 0) + 1;
    }
  });

  return (
    <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-3 animate-in fade-in slide-in-from-top-2 duration-300 h-[160px] overflow-hidden flex flex-col">
      <h3 className="text-sm font-bold text-slate-800 mb-0.5 flex-shrink-0">{formattedDate}</h3>
      
      {data.total > 0 ? (
        <>
          <p className="text-[11px] text-slate-500 mb-1.5 flex-shrink-0">
            {data.total} jadwal armada
            {Object.entries(fleetSummary).length > 0 && (
               <span> ({Object.entries(fleetSummary).map(([k,v]) => `${v} ${k}`).join(', ')})</span>
            )}
          </p>
          <div className="space-y-1.5 flex-1 overflow-y-auto pr-1 custom-scrollbar min-h-0">
            {data.items.map(item => (
              <div 
                key={item.id} 
                onClick={() => navigate(`/jadwal?search=${encodeURIComponent(item.order_code || item.jadwal_id)}`)}
                className="block border border-slate-100 rounded-lg px-2.5 py-2 hover:bg-slate-50 hover:border-blue-100 transition-colors cursor-pointer group"
              >
                <div className="flex justify-between items-center mb-0.5">
                  <span className="text-[10px] font-bold text-blue-600 bg-blue-50 px-1.5 py-0.5 rounded">{item.order_code}</span>
                  <span className="text-[10px] text-slate-400 font-medium group-hover:text-blue-500 transition-colors">{item.start_time}</span>
                </div>
                <p className="text-[11px] font-bold text-slate-700 leading-tight truncate">{item.fleet_name}</p>
                <div className="flex items-center justify-between mt-0.5">
                  <p className="text-[10px] text-slate-500 leading-tight truncate flex-1 mr-2" title={item.route}>{item.route}</p>
                  <span className={`inline-block text-[9px] font-semibold px-1.5 py-0.5 rounded text-white flex-shrink-0 ${item.status_jadwal === 'Terjadwal' ? 'bg-blue-500' : item.status_jadwal === 'Selesai' ? 'bg-green-500' : 'bg-slate-400'}`}>
                    {item.status_jadwal}
                  </span>
                </div>
              </div>
            ))}
          </div>
        </>
      ) : (
        <div className="flex-1 flex flex-col items-center justify-center">
          <CalendarCheck size={20} className="text-slate-300 mb-1" />
          <p className="text-xs text-slate-500">Belum ada jadwal pada tanggal ini.</p>
        </div>
      )}
    </div>
  );
}

// ─── Activity icon ─────────────────────────────────────────────
const ACT_MAP = {
  blue:   { bg: '#dbeafe', c: '#2563eb', Icon: CalendarCheck },
  orange: { bg: '#ffedd5', c: '#ea580c', Icon: DollarSign    },
  green:  { bg: '#dcfce7', c: '#16a34a', Icon: RefreshCw     },
  purple: { bg: '#ede9fe', c: '#7c3aed', Icon: BellRing      },
};
function ActIcon({ color }) {
  const { bg, c, Icon } = ACT_MAP[color] || ACT_MAP.blue;
  return (
    <div className="w-10 h-10 rounded-full flex items-center justify-center flex-shrink-0" style={{ backgroundColor: bg }}>
      <Icon size={17} style={{ color: c }} />
    </div>
  );
}

function CustomDropdown({ options, value, onChange, theme = 'emerald' }) {
  const [isOpen, setIsOpen] = useState(false);
  const [dropdownStyle, setDropdownStyle] = useState({});
  const buttonRef = useRef(null);
  const dropdownRef = useRef(null);

  const openDropdown = () => {
    if (buttonRef.current) {
      const rect = buttonRef.current.getBoundingClientRect();
      const spaceBelow = window.innerHeight - rect.bottom;
      const dropdownHeight = options.length * 36 + 16;
      
      let top = rect.bottom + 4;
      if (spaceBelow < dropdownHeight && rect.top > spaceBelow) {
        top = rect.top - dropdownHeight - 4;
      }

      setDropdownStyle({
        top: `${top}px`,
        left: `${rect.right - 144}px`, // w-36 = 144px
        width: '144px'
      });
    }
    setIsOpen(true);
  };

  useEffect(() => {
    if (!isOpen) return;

    function handleClickOutside(event) {
      if (
        buttonRef.current && !buttonRef.current.contains(event.target) &&
        dropdownRef.current && !dropdownRef.current.contains(event.target)
      ) {
        setIsOpen(false);
      }
    }

    function handleScroll() {
      setIsOpen(false);
    }

    window.addEventListener('scroll', handleScroll, true);
    window.addEventListener('resize', handleScroll);
    document.addEventListener('mousedown', handleClickOutside);

    return () => {
      window.removeEventListener('scroll', handleScroll, true);
      window.removeEventListener('resize', handleScroll);
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [isOpen]);

  const ringColor = theme === 'emerald' ? 'focus:ring-emerald-100 focus:border-emerald-400' : 'focus:ring-indigo-100 focus:border-indigo-400';
  const activeColor = theme === 'emerald' ? 'text-emerald-600 bg-emerald-50/50' : 'text-indigo-600 bg-indigo-50/50';

  return (
    <div className="relative inline-block text-left">
      <button
        ref={buttonRef}
        type="button"
        onClick={() => isOpen ? setIsOpen(false) : openDropdown()}
        className={`flex items-center justify-between gap-2 min-w-[115px] text-xs font-semibold border border-slate-200 rounded-lg px-3 py-1.5 text-slate-600 bg-white hover:bg-slate-50 focus:outline-none focus:ring-2 transition-all shadow-sm ${ringColor}`}
      >
        <span>{value}</span>
        <ChevronDown size={14} className={`text-slate-400 transition-transform duration-200 ${isOpen ? 'rotate-180' : ''}`} />
      </button>

      {isOpen && createPortal(
        <div 
          ref={dropdownRef}
          style={dropdownStyle}
          className="fixed z-[9999] rounded-xl bg-white shadow-[0_10px_40px_rgba(0,0,0,0.12)] focus:outline-none overflow-hidden border border-slate-100 animate-in fade-in zoom-in-95 duration-100"
        >
          <div className="py-1">
            {options.map((option) => (
              <button
                key={option}
                onClick={() => {
                  onChange(option);
                  setIsOpen(false);
                }}
                className={`block w-full text-left px-4 py-2 text-xs font-semibold hover:bg-slate-50 transition-colors ${value === option ? activeColor : 'text-slate-600'}`}
              >
                {option}
              </button>
            ))}
          </div>
        </div>,
        document.body
      )}
    </div>
  );
}

// ══════════════════════════════════════════════════════════════
export default function Dashboard() {
  const [period, setPeriod] = useState('Mingguan');
  const [pendapatanPeriod, setPendapatanPeriod] = useState('Bulan Ini');
  
  const [calMonth, setCalMonth] = useState(new Date().getMonth() + 1);
  const [calYear, setCalYear] = useState(new Date().getFullYear());

  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [data, setData] = useState({
    summary: { total_pendapatan: 0, total_armada: 0, jadwal_aktif: 0, permintaan_jadwal: 0, pembayaran_menunggu: 0 },
    booking_statistics: [],
    recent_activities: [],
    latest_schedules: []
  });

  // Calendar specific state
  const [calendarData, setCalendarData] = useState([]);
  const [loadingCalendar, setLoadingCalendar] = useState(true);
  const [calendarError, setCalendarError] = useState(null);
  const [selectedDate, setSelectedDate] = useState(null);

  const fetchDashboard = async () => {
    setLoading(true);
    try {
      const params = {
        income_period: pendapatanPeriod,
        stats_period: period,
      };
      const res = await getDashboardData(params);
      setData(res.data.data);
      setError(null);
    } catch (err) {
      console.error(err);
      setError('Gagal memuat data dashboard.');
    } finally {
      setLoading(false);
    }
  };

  const fetchCalendar = async () => {
    setLoadingCalendar(true);
    setCalendarError(null);
    try {
      const res = await getDashboardCalendar({ month: calMonth, year: calYear });
      setCalendarData(res.data.data.dates || []);
    } catch (err) {
      console.error(err);
      setCalendarError('Gagal memuat kalender jadwal.');
      setCalendarData([]);
    } finally {
      setLoadingCalendar(false);
    }
  };

  useEffect(() => {
    fetchDashboard();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [pendapatanPeriod, period]);

  useEffect(() => {
    fetchCalendar();
    setSelectedDate(null);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [calMonth, calYear]);

  // Handle month change from MiniCalendar
  const handleMonthChange = (newM, newY) => {
    setCalMonth(newM);
    setCalYear(newY);
  };

  const CARDS = [
    { label: 'Jadwal Aktif',       value: data.summary.jadwal_aktif, badge: 'Active',  badgeColor: '#3b82f6', Icon: Calendar,     iconBg: '#f0fdf4', iconColor: '#22c55e' },
    { label: 'Permintaan Jadwal',  value: data.summary.permintaan_jadwal,  badge: 'New',     badgeColor: '#ec4899', Icon: ClipboardList, iconBg: '#fdf4ff', iconColor: '#c026d3' },
    { label: 'Pembayaran Menunggu',value: data.summary.pembayaran_menunggu,  badge: 'Pending', badgeColor: '#f97316', Icon: CreditCard,   iconBg: '#fff7ed', iconColor: '#f97316' },
  ];

  return (
    <Layout>

      {error && (
        <div className="mb-4 bg-red-50 text-red-600 p-3 rounded-xl text-sm font-medium border border-red-100 flex items-center gap-2">
          <AlertCircle size={16} />
          {error}
        </div>
      )}

      {/* ── 1. Summary Cards ─────────────────────────────────── */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5 gap-4 mb-5">
        
        {/* Total Pendapatan Card */}
        <div 
          className="rounded-2xl border border-slate-200 shadow-sm p-5 flex flex-col justify-between animate-fade-in-up"
          style={{ background: 'linear-gradient(to bottom right, #ecfdf5, #ffffff)', animationDelay: '50ms' }}
        >
          <div className="flex items-start justify-between mb-4">
            <div className="w-11 h-11 rounded-xl flex items-center justify-center bg-emerald-50">
              <DollarSign size={21} className="text-emerald-500" />
            </div>
            <CustomDropdown 
              options={['Hari Ini', 'Minggu Ini', 'Bulan Ini', 'Tahun Ini']}
              value={pendapatanPeriod}
              onChange={setPendapatanPeriod}
              theme="emerald"
            />
          </div>
          <div>
            <p className="text-sm text-slate-500 leading-snug">Total Pendapatan</p>
            <p className="text-2xl font-extrabold text-slate-800 mt-1 leading-none tracking-tight">
              {loading ? <span className="inline-block w-24 h-6 bg-slate-100 rounded animate-pulse" /> : formatRupiah(data.summary.total_pendapatan)}
            </p>
          </div>
        </div>

        {/* Total Armada Card */}
        <div
          className="rounded-2xl border border-slate-200 shadow-sm p-5 flex flex-col justify-between animate-fade-in-up"
          style={{ background: 'linear-gradient(to bottom right, #eff6ff, #ffffff)', animationDelay: '100ms' }}
        >
          <div className="flex items-start justify-between mb-4">
            <div className="w-11 h-11 rounded-xl flex items-center justify-center" style={{ backgroundColor: '#eff6ff' }}>
              <Truck size={21} style={{ color: '#6366f1' }} />
            </div>
            <span className="text-xs font-semibold" style={{ color: '#22c55e' }}>Total</span>
          </div>
          <div>
            <p className="text-sm text-slate-500 leading-snug">Total Armada</p>
            <p className="text-3xl font-extrabold text-slate-800 mt-1 leading-none tracking-tight">
              {loading ? <span className="inline-block w-8 h-8 bg-slate-100 rounded animate-pulse" /> : data.summary.total_armada}
            </p>
          </div>
        </div>

        {CARDS.map(({ label, value, badge, badgeColor, Icon, iconBg, iconColor }, index) => (
          <div 
            key={label} 
            className="rounded-2xl border border-slate-200 shadow-sm p-5 flex flex-col justify-between animate-fade-in-up"
            style={{ background: `linear-gradient(to bottom right, ${iconBg}, #ffffff)`, animationDelay: `${150 + (index * 50)}ms` }}
          >
            {/* Icon row */}
            <div className="flex items-start justify-between mb-4">
              <div
                className="w-11 h-11 rounded-xl flex items-center justify-center"
                style={{ backgroundColor: iconBg }}
              >
                <Icon size={21} style={{ color: iconColor }} />
              </div>
              <span className="text-xs font-semibold" style={{ color: badgeColor }}>
                {badge}
              </span>
            </div>
            {/* Label + number */}
            <div>
              <p className="text-sm text-slate-500 leading-snug">{label}</p>
              <p className="text-3xl font-extrabold text-slate-800 mt-1 leading-none tracking-tight">
                {loading ? <span className="inline-block w-8 h-8 bg-slate-100 rounded animate-pulse" /> : value}
              </p>
            </div>
          </div>
        ))}
      </div>

      {/* ── 2. Chart + Calendar + Activity ───────────────────── */}
      <div className="grid grid-cols-1 xl:grid-cols-4 gap-5 mb-5">

        {/* Chart — Spans 2 columns */}
        <div className="xl:col-span-2 bg-white rounded-2xl border border-slate-200 shadow-sm p-5 relative animate-fade-in-up" style={{ animationDelay: '300ms' }}>
          {loading && (
            <div className="absolute inset-0 bg-white/60 z-10 flex items-center justify-center rounded-2xl">
              <Loader2 className="animate-spin text-indigo-500" />
            </div>
          )}
          {/* Header */}
          <div className="flex items-center justify-between mb-3">
            <h2 className="text-base font-bold text-slate-800">Statistik Pemesanan</h2>
            <CustomDropdown 
              options={['Mingguan', 'Bulanan', 'Tahunan']}
              value={period}
              onChange={setPeriod}
              theme="indigo"
            />
          </div>

          {/* Legend */}
          <div className="flex flex-wrap gap-4 mb-3">
            {[
              { label: 'Bus Medium', color: '#22d3ee' },
              { label: 'Elf Long',   color: '#818cf8' },
              { label: 'Truk CDD',   color: '#4f46e5' },
            ].map((l) => (
              <div key={l.label} className="flex items-center gap-1.5">
                <span className="w-2.5 h-2.5 rounded-full" style={{ backgroundColor: l.color }} />
                <span className="text-xs text-slate-500">{l.label}</span>
              </div>
            ))}
          </div>

          {data.booking_statistics.length === 0 && !loading ? (
            <div className="h-[268px] flex items-center justify-center text-sm text-slate-400">
              Belum ada data pemesanan
            </div>
          ) : (
            <ResponsiveContainer width="100%" height={268}>
              <BarChart
                data={data.booking_statistics}
                barSize={32}
                margin={{ top: 4, right: 4, left: -20, bottom: 0 }}
              >
                <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" vertical={false} />
                <XAxis dataKey="hari" axisLine={false} tickLine={false} tick={{ fontSize: 12, fill: '#94a3b8' }} />
                <YAxis axisLine={false} tickLine={false} tick={{ fontSize: 12, fill: '#94a3b8' }} />
                <Tooltip content={<ChartTooltip />} cursor={{ fill: 'rgba(241,245,249,0.5)' }} />
                <Bar dataKey="trukCDD"   name="Truk"       stackId="s" fill="#4f46e5" radius={[0, 0, 4, 4]} />
                <Bar dataKey="elfLong"   name="Elf"        stackId="s" fill="#818cf8" radius={[0, 0, 0, 0]} />
                <Bar dataKey="busMedium" name="Bus"        stackId="s" fill="#22d3ee" radius={[6, 6, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          )}
        </div>

        {/* Center column — Calendar */}
        <div className="xl:col-span-1 flex flex-col gap-4 relative animate-fade-in-up" style={{ animationDelay: '350ms' }}>
           {loadingCalendar && (
            <div className="absolute inset-0 bg-white/60 z-10 flex items-center justify-center rounded-2xl">
              <Loader2 className="animate-spin text-slate-500" />
            </div>
          )}
          <MiniCalendar 
            calendarData={calendarData} 
            curMonth={calMonth} 
            curYear={calYear} 
            onMonthChange={handleMonthChange}
            selectedDate={selectedDate}
            onSelectDate={setSelectedDate}
          />
          
          {selectedDate && (
            <CalendarPanel selectedDate={selectedDate} />
          )}
        </div>

        {/* Right column — Aktivitas Terkini */}
        <div className="xl:col-span-1 bg-white rounded-2xl border border-slate-200 shadow-sm p-4 h-full relative animate-fade-in-up" style={{ animationDelay: '400ms' }}>
          {loading && (
            <div className="absolute inset-0 bg-white/60 z-10 flex items-center justify-center rounded-2xl">
              <Loader2 className="animate-spin text-slate-500" />
            </div>
          )}
          <h3 className="text-sm font-bold text-slate-800 mb-4">Aktivitas Terkini</h3>
          <div className="space-y-4">
            {data.recent_activities.length === 0 && !loading ? (
              <p className="text-sm text-slate-400">Belum ada aktivitas terbaru</p>
            ) : (
              data.recent_activities.map((item) => (
                <div key={item.id} className="flex items-start gap-3">
                  <ActIcon color={item.color} />
                  <div className="flex-1 min-w-0">
                    <p className="text-xs font-bold text-slate-800 leading-snug">{item.title}</p>
                    <p className="text-xs text-slate-500 mt-0.5 leading-snug truncate" title={item.description}>{item.description}</p>
                    <p className="text-xs text-slate-400 mt-0.5">• {item.time}</p>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>
      </div>

      {/* ── 3. Jadwal Terbaru ─────────────────────────────────── */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-5 relative animate-fade-in-up" style={{ animationDelay: '450ms' }}>
        {loading && (
          <div className="absolute inset-0 bg-white/60 z-10 flex items-center justify-center rounded-2xl">
            <Loader2 className="animate-spin text-slate-500" />
          </div>
        )}
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-base font-bold text-slate-800">Jadwal Terbaru</h2>
          <Link
            to="/jadwal"
            className="flex items-center gap-1 text-sm font-semibold hover:opacity-70 transition-opacity"
            style={{ color: '#a3e635' }}
          >
            Lihat Semua <ArrowRight size={14} />
          </Link>
        </div>

        {data.latest_schedules.length === 0 && !loading ? (
          <div className="text-center py-8 text-slate-400 text-sm">
            Belum ada jadwal terbaru
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full min-w-[600px]">
              <thead>
                <tr className="border-b border-slate-100">
                  {['TANGGAL', 'ARMADA', 'RUTE', 'STATUS'].map((h) => (
                    <th
                      key={h}
                      className="text-left pb-3 text-xs font-semibold uppercase tracking-wider text-slate-400"
                      style={{ paddingRight: h !== 'STATUS' ? 24 : 0 }}
                    >
                      {h}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {data.latest_schedules.map((row, i) => (
                  <tr key={i} className="hover:bg-slate-50 transition-colors">
                    <td className="py-4 pr-6 text-sm text-slate-600 whitespace-nowrap">{row.tanggal}</td>
                    <td className="py-4 pr-6">
                      <div className="flex items-center gap-2.5">
                        <div className="w-7 h-7 rounded-lg bg-slate-100 flex items-center justify-center flex-shrink-0">
                          <Truck size={13} className="text-slate-500" />
                        </div>
                        <div>
                          <p className="text-sm font-semibold text-slate-800 leading-tight">{row.armada}</p>
                          <p className="text-xs text-slate-400 mt-0.5">{row.plat}</p>
                        </div>
                      </div>
                    </td>
                    <td className="py-4 pr-6 text-sm text-slate-700">{row.rute}</td>
                    <td className="py-4"><StatusPill status={row.status} /></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

    </Layout>
  );
}
