import { Loader2, AlertTriangle, CheckCircle, Info } from 'lucide-react';
import ModalOverlay from './ModalOverlay';

export default function ConfirmModal({
  isOpen,
  title,
  message,
  confirmText = 'Konfirmasi',
  cancelText = 'Batal',
  variant = 'default',
  isLoading = false,
  onConfirm,
  onCancel,
  children,
}) {
  if (!isOpen) return null;

  // Variant configuration
  let colorClass = 'bg-blue-500 hover:bg-blue-600';
  let iconClass = 'text-blue-500';
  let bgIconClass = 'bg-blue-50';
  let Icon = Info;

  if (variant === 'success') {
    colorClass = 'bg-emerald-500 hover:bg-emerald-600';
    iconClass = 'text-emerald-500';
    bgIconClass = 'bg-emerald-50';
    Icon = CheckCircle;
  } else if (variant === 'danger') {
    colorClass = 'bg-red-500 hover:bg-red-600';
    iconClass = 'text-red-500';
    bgIconClass = 'bg-red-50';
    Icon = AlertTriangle;
  } else if (variant === 'default') {
    // Re-use lime/primary colors of the app or standard blue
    colorClass = 'bg-lime-500 hover:bg-lime-600'; // Or whatever is standard primary
    iconClass = 'text-lime-500';
    bgIconClass = 'bg-lime-50';
  }

  return (
    <ModalOverlay onClose={isLoading ? undefined : onCancel}>
      <div className="bg-white rounded-2xl shadow-xl w-full max-w-sm overflow-hidden animate-in fade-in zoom-in-95 duration-200">
        <div className="p-6 text-center">
          <div className={`w-14 h-14 rounded-full flex items-center justify-center mx-auto mb-4 ${bgIconClass}`}>
            <Icon size={24} className={iconClass} />
          </div>
          <h3 className="text-lg font-bold text-slate-800 mb-2">{title}</h3>
          <div className="text-sm text-slate-500">{message}</div>
          {children && <div className="mt-4 text-left">{children}</div>}
        </div>
        <div className="px-6 pb-6 flex gap-3">
          <button
            onClick={onCancel}
            disabled={isLoading}
            className="flex-1 py-2.5 text-sm font-semibold text-slate-700 bg-white border border-slate-200 rounded-full hover:bg-slate-50 transition-colors disabled:opacity-50"
          >
            {cancelText}
          </button>
          <button
            onClick={onConfirm}
            disabled={isLoading}
            className={`flex-1 flex items-center justify-center gap-2 py-2.5 text-sm font-semibold text-white rounded-full transition-colors disabled:opacity-70 ${colorClass}`}
          >
            {isLoading ? <Loader2 size={14} className="animate-spin" /> : <Icon size={14} />}
            {confirmText}
          </button>
        </div>
      </div>
    </ModalOverlay>
  );
}
