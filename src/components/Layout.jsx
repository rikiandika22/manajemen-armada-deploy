import { useState } from 'react';
import Sidebar from './Sidebar';
import Topbar from './Topbar';

// Preserve sidebar state across page navigation
let globalSidebarState = true;

export default function Layout({ children }) {
  const [isSidebarOpen, setIsSidebarOpen] = useState(globalSidebarState);

  const handleSetSidebarOpen = (val) => {
    const newVal = typeof val === 'function' ? val(isSidebarOpen) : val;
    globalSidebarState = newVal;
    setIsSidebarOpen(newVal);
  };

  return (
    <div className="min-h-screen bg-slate-100 flex">
      <Sidebar isOpen={isSidebarOpen} setIsOpen={handleSetSidebarOpen} />
      
      <div 
        className="flex-1 flex flex-col min-w-0 transition-all duration-300" 
        style={{ marginLeft: isSidebarOpen ? 230 : 80 }}
      >
        <Topbar isOpen={isSidebarOpen} setIsOpen={handleSetSidebarOpen} />
        <main
          className="flex-1 bg-slate-100"
          style={{ paddingTop: 62 }}
        >
          <div className="p-6">{children}</div>
        </main>
      </div>
    </div>
  );
}
