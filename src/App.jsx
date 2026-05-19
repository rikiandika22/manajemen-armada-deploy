import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { SpeedInsights } from '@vercel/speed-insights/react';
import ProtectedRoute from './components/ProtectedRoute';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Armada from './pages/Armada';
import Jadwal from './pages/Jadwal';
import Pemesanan from './pages/Pemesanan';
import Pembayaran from './pages/Pembayaran';
import Sopir from './pages/Sopir';
import Laporan from './pages/Laporan';
import Pengaturan from './pages/Pengaturan';

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Navigate to="/dashboard" replace />} />
        <Route path="/login" element={<Login />} />
        <Route path="/dashboard" element={<ProtectedRoute><Dashboard /></ProtectedRoute>} />
        <Route path="/armada" element={<ProtectedRoute><Armada /></ProtectedRoute>} />
        <Route path="/jadwal" element={<ProtectedRoute><Jadwal /></ProtectedRoute>} />
        <Route path="/pemesanan" element={<ProtectedRoute><Pemesanan /></ProtectedRoute>} />
        <Route path="/pembayaran" element={<ProtectedRoute><Pembayaran /></ProtectedRoute>} />
        <Route path="/sopir" element={<ProtectedRoute><Sopir /></ProtectedRoute>} />
        <Route path="/laporan" element={<ProtectedRoute><Laporan /></ProtectedRoute>} />
        <Route path="/pengaturan" element={<ProtectedRoute><Pengaturan /></ProtectedRoute>} />
        <Route path="*" element={<Navigate to="/login" replace />} />
      </Routes>
      <SpeedInsights />
    </BrowserRouter>
  );
}
