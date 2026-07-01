import { useState, useRef, useEffect } from 'react';
import { createPortal } from 'react-dom';
import { ChevronDown } from 'lucide-react';

export default function AppSelect({ 
  options = [], 
  value, 
  onChange, 
  placeholder = 'Pilih...',
  disabled = false,
  className = '',
  icon: Icon
}) {
  const [isOpen, setIsOpen] = useState(false);
  const [dropdownStyle, setDropdownStyle] = useState({});
  const buttonRef = useRef(null);
  const dropdownRef = useRef(null);

  const openDropdown = () => {
    if (disabled) return;
    
    // Calculate position
    if (buttonRef.current) {
      const rect = buttonRef.current.getBoundingClientRect();
      const spaceBelow = window.innerHeight - rect.bottom;
      const dropdownHeight = 240; // max-h-60 is 240px
      
      let top = rect.bottom + 4;
      // If space below is not enough and space above is larger, show above
      if (spaceBelow < dropdownHeight && rect.top > spaceBelow) {
        top = rect.top - dropdownHeight - 4;
      }

      setDropdownStyle({
        top: `${top}px`,
        left: `${rect.left}px`,
        width: `${rect.width}px`
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
      // Close dropdown on scroll to avoid detached floating menus
      setIsOpen(false);
    }

    // Use capture phase to catch all scrolls in nested containers
    window.addEventListener('scroll', handleScroll, true);
    window.addEventListener('resize', handleScroll);
    document.addEventListener('mousedown', handleClickOutside);
    
    return () => {
      window.removeEventListener('scroll', handleScroll, true);
      window.removeEventListener('resize', handleScroll);
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [isOpen]);

  const handleKeyDown = (e) => {
    if (e.key === 'Escape') setIsOpen(false);
  };

  const selectedOption = options.find(opt => {
    const optVal = typeof opt === 'object' ? opt.value : opt;
    return optVal === value;
  });

  const displayLabel = selectedOption 
    ? (typeof selectedOption === 'object' ? selectedOption.label : selectedOption)
    : placeholder;

  return (
    <div className={`relative inline-block text-left ${className}`}>
      <button
        ref={buttonRef}
        type="button"
        disabled={disabled}
        onKeyDown={handleKeyDown}
        onClick={() => isOpen ? setIsOpen(false) : openDropdown()}
        className={`flex items-center justify-between gap-2 w-full text-xs font-semibold border rounded-lg px-3 py-2 transition-all shadow-sm
          ${disabled 
            ? 'bg-slate-50 text-slate-400 border-slate-200 cursor-not-allowed' 
            : 'bg-white text-slate-600 border-slate-200 hover:bg-slate-50 focus:outline-none focus:ring-2 focus:ring-emerald-100 focus:border-emerald-400'
          }`}
      >
        <div className="flex items-center gap-2 truncate">
          {Icon && <Icon size={14} className="text-slate-400 flex-shrink-0" />}
          <span className="truncate">{displayLabel}</span>
        </div>
        <ChevronDown size={14} className={`text-slate-400 transition-transform duration-200 flex-shrink-0 ${isOpen ? 'rotate-180' : ''}`} />
      </button>

      {isOpen && createPortal(
        <div 
          ref={dropdownRef}
          style={dropdownStyle}
          className="fixed z-[9999] origin-top-left rounded-xl bg-white shadow-[0_10px_40px_rgba(0,0,0,0.12)] focus:outline-none border border-slate-100 animate-in fade-in zoom-in-95 duration-100 overflow-hidden"
        >
          <div className="py-1 max-h-60 overflow-y-auto">
            {options.length === 0 ? (
              <div className="px-4 py-2 text-xs text-slate-400 text-center">Tidak ada opsi</div>
            ) : (
              options.map((opt, i) => {
                const optVal = typeof opt === 'object' ? opt.value : opt;
                const optLabel = typeof opt === 'object' ? opt.label : opt;
                const isSelected = optVal === value;

                return (
                  <button
                    key={`${optVal}-${i}`}
                    onClick={() => {
                      onChange(optVal);
                      setIsOpen(false);
                    }}
                    className={`block w-full text-left px-4 py-2 text-xs font-semibold hover:bg-slate-50 transition-colors truncate
                      ${isSelected ? 'text-emerald-600 bg-emerald-50/50' : 'text-slate-600'}
                    `}
                  >
                    {optLabel}
                  </button>
                );
              })
            )}
          </div>
        </div>,
        document.body
      )}
    </div>
  );
}
