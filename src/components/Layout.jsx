import { useState, useEffect } from 'react';
import { getNotificationSummary } from '../services/api';
import { NotificationContext } from '../contexts/NotificationContext';
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

  const [notifications, setNotifications] = useState({
    total: 0,
    pemesanan: { count: 0, label: '' },
    pembayaran: { count: 0, label: '' },
    jadwal: { count: 0, label: '' }
  });

  const refreshNotifications = async () => {
    try {
      const res = await getNotificationSummary();
      if (res.data?.data) {
        setNotifications(res.data.data);
      }
    } catch (error) {
      console.error('Failed to fetch notifications', error);
      // Fallback 0 is maintained if it fails initially
    }
  };

  useEffect(() => {
    refreshNotifications();
    const interval = setInterval(() => {
      refreshNotifications();
    }, 30000); // 30 seconds
    return () => clearInterval(interval);
  }, []);

  return (
    <NotificationContext.Provider value={{ notifications, refreshNotifications }}>
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
    </NotificationContext.Provider>
  );
}
