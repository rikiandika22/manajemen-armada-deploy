import { createContext, useContext } from 'react';

export const NotificationContext = createContext({
  notifications: {
    total: 0,
    pemesanan: { count: 0, label: '' },
    pembayaran: { count: 0, label: '' },
    jadwal: { count: 0, label: '' }
  },
  refreshNotifications: () => {}
});

export function useNotifications() {
  return useContext(NotificationContext);
}
