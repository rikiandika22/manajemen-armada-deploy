import axios from 'axios';

const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || 'http://127.0.0.1:8000/api',
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
});

// Interceptor to add auth token
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Interceptor to handle 401 Unauthorized responses
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response && error.response.status === 401) {
      // Jangan redirect jika error berasal dari halaman login itu sendiri
      const url = error.config?.url || '';
      if (!url.includes('/login')) {
        localStorage.removeItem('token');
        localStorage.removeItem('user');
        window.location.href = '/login';
      }
    }
    return Promise.reject(error);
  }
);

// --- SOPIR ---
export const getSopir = () => api.get('/sopirs');
export const getSopirById = (id) => api.get(`/sopirs/${id}`);
export const createSopir = (data) => api.post('/sopirs', data);
export const updateSopir = (id, data) => api.post(`/sopirs/${id}`, data);
export const deleteSopir = (id) => api.delete(`/sopirs/${id}`);

// --- JADWAL ---
export const getJadwal = () => api.get('/jadwals');
export const getJadwalById = (id) => api.get(`/jadwals/${id}`);
export const createJadwal = (data) => api.post('/jadwals', data);
export const updateJadwal = (id, data) => api.put(`/jadwals/${id}`, data);
export const deleteJadwal = (id) => api.delete(`/jadwals/${id}`);
export const getJadwalSummary = () => api.get('/admin/jadwals/summary');

// --- PAYMENT ACCOUNTS ---
export const getPaymentAccounts = () => api.get('/admin/payment_accounts');
export const createPaymentAccount = (data) => api.post('/admin/payment_accounts', data);
export const updatePaymentAccount = (id, data) => api.put(`/admin/payment_accounts/${id}`, data);
export const togglePaymentAccount = (id) => api.patch(`/admin/payment_accounts/${id}/toggle`);
export const deletePaymentAccount = (id) => api.delete(`/admin/payment_accounts/${id}`);

// --- NOTIFICATIONS ---
export const getNotificationSummary = () => api.get('/admin/notifications/summary');

// --- REPORTS ---
export const getReportSummary = (params) => api.get('/admin/reports/summary', { params });
export const getOperationalReports = (params) => api.get('/admin/reports/operational', { params });
export const exportReportPdf = (params) => api.get('/admin/reports/export/pdf', { params, responseType: 'blob' });
export const exportReportExcel = (params) => api.get('/admin/reports/export/excel', { params, responseType: 'blob' });

// --- DASHBOARD ---
export const getDashboardData = (params) => api.get('/admin/dashboard', { params });
export const getDashboardCalendar = (params) => api.get('/admin/dashboard/calendar', { params });

// --- GLOBAL SEARCH ---
export const globalSearch = (q) => api.get('/admin/search/global', { params: { q } });

export default api;
