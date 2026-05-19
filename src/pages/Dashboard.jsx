import { useState, useRef, useEffect } from 'react';
import {
  Truck, Calendar, ClipboardList, CreditCard,
  ChevronLeft, ChevronRight, ArrowRight, ChevronDown,
  CalendarCheck, DollarSign, RefreshCw, BellRing
} from 'lucide-react';
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid,
  Tooltip, ResponsiveContainer,
} from 'recharts';
import Layout from '../components/Layout';
import { mockAktivitas } from '../data/mockData';
import { Link } from 'react-router-dom';

// ─── Chart data ────────────────────────────────────────────────
const chartData = [
  { hari: 'Min', trukCDD: 5,  elfLong: 3,  busMedium: 4  },
  { hari: 'Sen', trukCDD: 7,  elfLong: 4,  busMedium: 6  },
  { hari: 'Sel', trukCDD: 10, elfLong: 5,  busMedium: 9  },
  { hari: 'Rab', trukCDD: 12, elfLong: 8,  busMedium: 11 },
  { hari: 'Kam', trukCDD: 11, elfLong: 6,  busMedium: 10 },
  { hari: 'Jum', trukCDD: 14, elfLong: 9,  busMedium: 14 },
  { hari: 'Sab', trukCDD: 12, elfLong: 11, busMedium: 16 },
];

// ─── Jadwal table data ─────────────────────────────────────────
const jadwalRows = [
  { tanggal: '02 Juli, 10:30', armada: 'Bus Medium A1', plat: 'H 1234 AA', rute: 'Semarang → Solo',           status: 'Dalam Perjalanan' },
  { tanggal: '14 Juni, 12:45', armada: 'Elf Long 02',   plat: 'H 5678 BB', rute: 'Grobogan → Semarang',      status: 'Selesai'          },
  { tanggal: '12 Mei, 11:00',  armada: 'Truk CDD C3',   plat: 'H 9012 CC', rute: 'Pengiriman Pasir – Grobogan',status: 'Menunggu'       },
];

// ─── Summary cards config ──────────────────────────────────────
const CARDS = [
  { label: 'Total Armada',       value: '6',  badge: 'Total',   badgeColor: '#22c55e', Icon: Truck,        iconBg: '#eff6ff', iconColor: '#6366f1' },
  { label: 'Jadwal Aktif',       value: '12', badge: 'Active',  badgeColor: '#3b82f6', Icon: Calendar,     iconBg: '#f0fdf4', iconColor: '#22c55e' },
  { label: 'Permintaan Jadwal',  value: '4',  badge: 'New',     badgeColor: '#ec4899', Icon: ClipboardList, iconBg: '#fdf4ff', iconColor: '#c026d3' },
  { label: 'Pembayaran Menunggu',value: '3',  badge: 'Pending', badgeColor: '#f97316', Icon: CreditCard,   iconBg: '#fff7ed', iconColor: '#f97316' },
];

// ─── Status pill  ──────────────────────────────────────────────
const STATUS_STYLE = {
  'Dalam Perjalanan': { bg: '#1e293b', color: '#f8fafc' },
  'Selesai':          { bg: '#dcfce7', color: '#15803d' },
  'Menunggu':         { bg: '#f1f5f9', color: '#64748b' },
  'Tersedia':         { bg: '#dbeafe', color: '#1d4ed8' },
  'Dipesan':          { bg: '#fce7f3', color: '#9d174d' },
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
    <div className="bg-white rounded-xl shadow-lg border border-slate-100 px-3 py-2 text-xs">
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
function MiniCalendar() {
  const today = { d: 19, m: 4, y: 2026 }; // May 19 2026
  const [cur, setCur] = useState({ m: 4, y: 2026 });

  const { m, y } = cur;
  const monthLabel =
    new Date(y, m, 1).toLocaleString('en-US', { month: 'long' }) + ', ' + y;

  const firstDow = new Date(y, m, 1).getDay(); // Sun=0
  const daysInM  = new Date(y, m + 1, 0).getDate();
  const prevDaysInM = new Date(y, m, 0).getDate();

  const cells = [];
  for (let i = firstDow - 1; i >= 0; i--)
    cells.push({ d: prevDaysInM - i, cur: false });
  for (let d = 1; d <= daysInM; d++)
    cells.push({ d, cur: true });
  while (cells.length < 42) cells.push({ d: cells.length - daysInM - firstDow + 1, cur: false });

  const prev = () => setCur(({ m, y }) => m === 0 ? { m: 11, y: y - 1 } : { m: m - 1, y });
  const next = () => setCur(({ m, y }) => m === 11 ? { m: 0, y: y + 1 } : { m: m + 1, y });

  return (
    <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-4 h-full">
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
        {['S','M','T','W','T','F','S'].map((d, i) => (
          <div key={i} className="text-center text-xs font-medium text-slate-400 pb-1">{d}</div>
        ))}
      </div>

      {/* Date cells */}
      <div className="grid grid-cols-7 gap-y-0.5">
        {cells.map((cell, i) => {
          const isToday = cell.cur && cell.d === today.d && m === today.m && y === today.y;
          return (
            <div
              key={i}
              className="flex items-center justify-center text-xs rounded-full mx-auto cursor-default transition-all"
              style={{
                width: 28, height: 28,
                backgroundColor: isToday ? '#a3e635' : 'transparent',
                color: !cell.cur ? '#cbd5e1' : isToday ? '#0f172a' : '#374151',
                fontWeight: isToday ? '700' : '400',
              }}
            >
              {cell.d}
            </div>
          );
        })}
      </div>
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

  const ringColor = theme === 'emerald' ? 'focus:ring-emerald-100 focus:border-emerald-400' : 'focus:ring-indigo-100 focus:border-indigo-400';
  const activeColor = theme === 'emerald' ? 'text-emerald-600 bg-emerald-50/50' : 'text-indigo-600 bg-indigo-50/50';

  return (
    <div className="relative inline-block text-left" ref={dropdownRef}>
      <button
        type="button"
        onClick={() => setIsOpen(!isOpen)}
        className={`flex items-center justify-between gap-2 min-w-[115px] text-xs font-semibold border border-slate-200 rounded-lg px-3 py-1.5 text-slate-600 bg-white hover:bg-slate-50 focus:outline-none focus:ring-2 transition-all shadow-sm ${ringColor}`}
      >
        <span>{value}</span>
        <ChevronDown size={14} className={`text-slate-400 transition-transform duration-200 ${isOpen ? 'rotate-180' : ''}`} />
      </button>

      {isOpen && (
        <div className="absolute right-0 mt-2 w-36 origin-top-right rounded-xl bg-white shadow-[0_10px_40px_rgba(0,0,0,0.12)] focus:outline-none z-50 overflow-hidden border border-slate-100 animate-in fade-in zoom-in-95 duration-100">
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
        </div>
      )}
    </div>
  );
}

// ══════════════════════════════════════════════════════════════
export default function Dashboard() {
  const [period, setPeriod] = useState('Mingguan');
  const [pendapatanPeriod, setPendapatanPeriod] = useState('Bulan Ini');

  return (
    <Layout>

      {/* ── 1. Summary Cards ─────────────────────────────────── */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5 gap-4 mb-5">
        
        {/* Total Pendapatan Card */}
        <div 
          className="rounded-2xl border border-slate-200 shadow-sm p-5 flex flex-col justify-between"
          style={{ background: 'linear-gradient(to bottom right, #ecfdf5, #ffffff)' }}
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
            <p className="text-3xl font-extrabold text-slate-800 mt-1 leading-none tracking-tight">Rp 12,5 Jt</p>
          </div>
        </div>

        {CARDS.map(({ label, value, badge, badgeColor, Icon, iconBg, iconColor }) => (
          <div 
            key={label} 
            className="rounded-2xl border border-slate-200 shadow-sm p-5 flex flex-col justify-between"
            style={{ background: `linear-gradient(to bottom right, ${iconBg}, #ffffff)` }}
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
              <p className="text-3xl font-extrabold text-slate-800 mt-1 leading-none tracking-tight">{value}</p>
            </div>
          </div>
        ))}
      </div>

      {/* ── 2. Chart + Calendar + Activity ───────────────────── */}
      <div className="grid grid-cols-1 xl:grid-cols-4 gap-5 mb-5">

        {/* Chart — Spans 2 columns */}
        <div className="xl:col-span-2 bg-white rounded-2xl border border-slate-200 shadow-sm p-5">
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

          <ResponsiveContainer width="100%" height={268}>
            <BarChart
              data={chartData}
              barSize={32}
              margin={{ top: 4, right: 4, left: -20, bottom: 0 }}
            >
              <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" vertical={false} />
              <XAxis dataKey="hari" axisLine={false} tickLine={false} tick={{ fontSize: 12, fill: '#94a3b8' }} />
              <YAxis axisLine={false} tickLine={false} tick={{ fontSize: 12, fill: '#94a3b8' }} domain={[0, 50]} ticks={[0,10,20,30,40,50]} />
              <Tooltip content={<ChartTooltip />} cursor={{ fill: 'rgba(241,245,249,0.5)' }} />
              {/* Stacked bottom→top: indigo, purple, cyan */}
              <Bar dataKey="trukCDD"   name="Truk CDD"   stackId="s" fill="#4f46e5" radius={[0, 0, 4, 4]} />
              <Bar dataKey="elfLong"   name="Elf Long"   stackId="s" fill="#818cf8" radius={[0, 0, 0, 0]} />
              <Bar dataKey="busMedium" name="Bus Medium" stackId="s" fill="#22d3ee" radius={[6, 6, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>

        {/* Center column — Calendar */}
        <div className="xl:col-span-1">
          <MiniCalendar />
        </div>

        {/* Right column — Aktivitas Terkini */}
        <div className="xl:col-span-1 bg-white rounded-2xl border border-slate-200 shadow-sm p-4 h-full">
          <h3 className="text-sm font-bold text-slate-800 mb-4">Aktivitas Terkini</h3>
          <div className="space-y-4">
            {mockAktivitas.slice(0, 3).map((item) => (
              <div key={item.id} className="flex items-start gap-3">
                <ActIcon color={item.color} />
                <div className="flex-1 min-w-0">
                  <p className="text-xs font-bold text-slate-800 leading-snug">{item.title}</p>
                  <p className="text-xs text-slate-500 mt-0.5 leading-snug">{item.desc}</p>
                  <p className="text-xs text-slate-400 mt-0.5">• {item.waktu}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* ── 3. Jadwal Terbaru ─────────────────────────────────── */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-5">
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

        <table className="w-full">
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
            {jadwalRows.map((row, i) => (
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

    </Layout>
  );
}
