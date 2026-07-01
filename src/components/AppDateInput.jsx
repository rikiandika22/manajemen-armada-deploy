import { Calendar } from 'lucide-react';
import { useRef } from 'react';

export default function AppDateInput({ 
  value, 
  onChange, 
  placeholder = 'Pilih Tanggal',
  disabled = false,
  className = '',
  min,
  max
}) {
  const inputRef = useRef(null);

  // Format value for display: YYYY-MM-DD -> 31 Mei 2026
  const displayValue = () => {
    if (!value) return '';
    try {
      const date = new Date(value);
      if (isNaN(date.getTime())) return value;
      return date.toLocaleDateString('id-ID', { 
        day: 'numeric', 
        month: 'long', 
        year: 'numeric' 
      });
    } catch (e) {
      return value;
    }
  };

  return (
    <div 
      className={`relative inline-flex items-center text-left ${className}`}
      onClick={() => {
        if (!disabled && inputRef.current) {
          // Attempt to open the native date picker popup
          inputRef.current.showPicker ? inputRef.current.showPicker() : inputRef.current.focus();
        }
      }}
    >
      <div
        className={`flex items-center justify-between gap-2 w-full text-xs font-semibold border rounded-lg px-3 py-2 transition-all shadow-sm cursor-pointer
          ${disabled 
            ? 'bg-slate-50 text-slate-400 border-slate-200 cursor-not-allowed' 
            : 'bg-white border-slate-200 hover:bg-slate-50 focus-within:ring-2 focus-within:ring-emerald-100 focus-within:border-emerald-400'
          }`}
      >
        <span className={`truncate ${!value ? 'text-slate-400' : 'text-slate-600'}`}>
          {value ? displayValue() : placeholder}
        </span>
        <Calendar size={14} className="text-slate-400 flex-shrink-0" />
      </div>

      {/* Hidden Native Input overlaid to capture interactions natively */}
      <input 
        ref={inputRef}
        type="date"
        value={value || ''}
        min={min}
        max={max}
        onChange={(e) => onChange(e.target.value)}
        disabled={disabled}
        className="absolute inset-0 w-full h-full opacity-0 cursor-pointer disabled:cursor-not-allowed z-10"
      />
    </div>
  );
}
