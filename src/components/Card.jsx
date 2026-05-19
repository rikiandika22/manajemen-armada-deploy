// Reusable Card component
export default function Card({ children, className = '', style = {} }) {
  return (
    <div
      className={`bg-white rounded-2xl border border-slate-200/70 shadow-sm ${className}`}
      style={style}
    >
      {children}
    </div>
  );
}
