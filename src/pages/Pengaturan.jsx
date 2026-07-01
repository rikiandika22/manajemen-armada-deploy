import { useState, useEffect } from 'react';
import { Save, Eye, EyeOff, Building2, Phone, MapPin, User, Lock, Loader2, CreditCard, Plus, Edit2, Trash2, Power, PowerOff } from 'lucide-react';
import Layout from '../components/Layout';
import Card from '../components/Card';
import AppSelect from '../components/AppSelect';
import api, { getPaymentAccounts, createPaymentAccount, updatePaymentAccount, togglePaymentAccount, deletePaymentAccount } from '../services/api';

export default function Pengaturan() {
  const [activeTab, setActiveTab] = useState('profil');
  
  const [showPassword, setShowPassword] = useState(false);
  const [showNewPassword, setShowNewPassword] = useState(false);
  
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const [feedback, setFeedback] = useState({ type: '', message: '' });
  const [errors, setErrors] = useState({});

  const [form, setForm] = useState({
    namaAdmin: '',
    emailAdmin: '',
    namaUsaha: '',
    teleponUsaha: '',
    alamatUsaha: '',
    passwordLama: '',
    passwordBaru: '',
    konfirmasiPassword: '',
  });

  // Rekening state
  const [accounts, setAccounts] = useState([]);
  const [isAccountModalOpen, setIsAccountModalOpen] = useState(false);
  const [accountForm, setAccountForm] = useState({ id: null, bank_name: 'BCA', custom_bank_name: '', account_number: '', account_holder_name: '', is_active: true, sort_order: 0, notes: '' });

  const handleChange = (key, value) => {
    setForm((prev) => ({ ...prev, [key]: value }));
    if (errors[key]) {
      setErrors((prev) => ({ ...prev, [key]: null }));
    }
  };

  const fetchSettings = async () => {
    try {
      setIsLoading(true);
      const [userRes, businessRes, accountsRes] = await Promise.all([
        api.get('/me'),
        api.get('/business-setting'),
        getPaymentAccounts().catch(() => ({ data: { data: [] } }))
      ]);

      setForm((prev) => ({
        ...prev,
        namaAdmin: userRes.data.name || '',
        emailAdmin: userRes.data.email || '',
        namaUsaha: businessRes.data.business_name || '',
        teleponUsaha: businessRes.data.business_phone || '',
        alamatUsaha: businessRes.data.business_address || '',
      }));

      if (accountsRes.data?.data) {
        setAccounts(accountsRes.data.data);
      }
    } catch (error) {
      console.error('Failed to fetch settings:', error);
      setFeedback({ type: 'error', message: 'Gagal mengambil data pengaturan dari server.' });
    } finally {
      setIsLoading(false);
    }
  };

  const fetchAccounts = async () => {
    try {
      const res = await getPaymentAccounts();
      setAccounts(res.data.data);
    } catch (error) {
      console.error(error);
    }
  };

  useEffect(() => {
    fetchSettings();
  }, []);

  const handleSave = async () => {
    setIsSaving(true);
    setFeedback({ type: '', message: '' });
    setErrors({});
    let successMessage = '';
    let hasError = false;

    try {
      await api.put('/profile', { name: form.namaAdmin, email: form.emailAdmin });
      successMessage += 'Profil diperbarui. ';

      await api.put('/business-setting', {
        business_name: form.namaUsaha,
        business_phone: form.teleponUsaha,
        business_address: form.alamatUsaha,
      });
      successMessage += 'Informasi usaha diperbarui. ';

      if (form.passwordLama || form.passwordBaru || form.konfirmasiPassword) {
        await api.put('/change-password', {
          old_password: form.passwordLama,
          new_password: form.passwordBaru,
          new_password_confirmation: form.konfirmasiPassword,
        });
        successMessage += 'Password diperbarui. ';
        setForm((prev) => ({
          ...prev,
          passwordLama: '',
          passwordBaru: '',
          konfirmasiPassword: '',
        }));
      }

      setFeedback({ type: 'success', message: successMessage });
      fetchSettings();

    } catch (error) {
      hasError = true;
      if (error.response?.status === 422) {
        const validationErrors = error.response.data.errors || {};
        const mappedErrors = {};
        if (validationErrors.name) mappedErrors.namaAdmin = validationErrors.name[0];
        if (validationErrors.email) mappedErrors.emailAdmin = validationErrors.email[0];
        if (validationErrors.business_name) mappedErrors.namaUsaha = validationErrors.business_name[0];
        setErrors(mappedErrors);
        setFeedback({ type: 'error', message: 'Gagal menyimpan perubahan. Periksa input form Anda.' });
      } else {
        setFeedback({ type: 'error', message: error.response?.data?.message || 'Terjadi kesalahan pada server.' });
      }
    } finally {
      setIsSaving(false);
      if (!hasError) setTimeout(() => setFeedback({ type: '', message: '' }), 5000);
    }
  };

  const openAddAccountModal = () => {
    setAccountForm({ id: null, bank_name: 'BCA', custom_bank_name: '', account_number: '', account_holder_name: '', is_active: true, sort_order: 0, notes: '' });
    setIsAccountModalOpen(true);
  };

  const openEditAccountModal = (account) => {
    const defaultBanks = ['BCA', 'BRI', 'BNI', 'Mandiri', 'BSI', 'CIMB Niaga', 'BTN'];
    const isCustom = !defaultBanks.includes(account.bank_name);
    setAccountForm({
      id: account.id,
      bank_name: isCustom ? 'Lainnya' : account.bank_name,
      custom_bank_name: isCustom ? account.bank_name : '',
      account_number: account.account_number,
      account_holder_name: account.account_holder_name,
      is_active: account.is_active,
      sort_order: account.sort_order,
      notes: account.notes || ''
    });
    setIsAccountModalOpen(true);
  };

  const handleSaveAccount = async () => {
    try {
      const finalBankName = accountForm.bank_name === 'Lainnya' ? accountForm.custom_bank_name : accountForm.bank_name;
      if (!finalBankName || !accountForm.account_number || !accountForm.account_holder_name) {
        alert('Bank, Nomor Rekening, dan Atas Nama wajib diisi.');
        return;
      }
      
      const payload = {
        bank_name: finalBankName,
        account_number: accountForm.account_number,
        account_holder_name: accountForm.account_holder_name,
        is_active: accountForm.is_active,
        sort_order: accountForm.sort_order,
        notes: accountForm.notes
      };

      if (accountForm.id) {
        await updatePaymentAccount(accountForm.id, payload);
      } else {
        await createPaymentAccount(payload);
      }
      setIsAccountModalOpen(false);
      fetchAccounts();
    } catch (error) {
      alert(error.response?.data?.message || 'Gagal menyimpan rekening.');
    }
  };

  const handleToggleAccount = async (id) => {
    try {
      await togglePaymentAccount(id);
      fetchAccounts();
    } catch (error) {
      alert('Gagal mengubah status rekening.');
    }
  };

  const handleDeleteAccount = async (id) => {
    if (confirm('Yakin ingin menghapus rekening ini?')) {
      try {
        await deletePaymentAccount(id);
        fetchAccounts();
      } catch (error) {
        alert(error.response?.data?.message || 'Gagal menghapus rekening.');
      }
    }
  };

  if (isLoading) {
    return (
      <Layout>
        <div className="flex items-center justify-center h-[60vh]">
          <Loader2 className="animate-spin text-lime-500" size={40} />
        </div>
      </Layout>
    );
  }

  return (
    <Layout>
      <div className="mb-6">
        <h2 className="text-xl font-bold text-slate-800">Pengaturan</h2>
        <p className="text-sm text-slate-500 mt-0.5">Kelola pengaturan sistem, profil, dan informasi pembayaran</p>
      </div>

      <div className="flex gap-4 border-b border-slate-200 mb-6">
        <button
          onClick={() => setActiveTab('profil')}
          className={`pb-3 px-1 text-sm font-semibold border-b-2 transition-colors ${activeTab === 'profil' ? 'border-lime-500 text-lime-600' : 'border-transparent text-slate-500 hover:text-slate-700'}`}
        >
          <div className="flex items-center gap-2">
            <User size={16} /> Profil & Info Usaha
          </div>
        </button>
        <button
          onClick={() => setActiveTab('rekening')}
          className={`pb-3 px-1 text-sm font-semibold border-b-2 transition-colors ${activeTab === 'rekening' ? 'border-lime-500 text-lime-600' : 'border-transparent text-slate-500 hover:text-slate-700'}`}
        >
          <div className="flex items-center gap-2">
            <CreditCard size={16} /> Rekening Pembayaran
          </div>
        </button>
      </div>

      {feedback.message && (
        <div className={`p-4 rounded-xl mb-6 flex items-start gap-3 border ${feedback.type === 'success' ? 'bg-green-50 border-green-200 text-green-700' : 'bg-red-50 border-red-200 text-red-700'}`}>
          <div className="flex-1 text-sm font-medium">{feedback.message}</div>
        </div>
      )}

      {activeTab === 'profil' && (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 animate-fade-in-up">
          <div className="lg:col-span-1">
            <Card className="p-6 text-center">
              <div
                className="w-20 h-20 rounded-full flex items-center justify-center text-white text-3xl font-bold mx-auto mb-4 shadow-sm"
                style={{ background: 'linear-gradient(135deg, #a3e635, #65a30d)' }}
              >
                {form.namaAdmin ? form.namaAdmin.charAt(0).toUpperCase() : 'A'}
              </div>
              <h3 className="text-base font-bold text-slate-800">{form.namaAdmin || '-'}</h3>
              <p className="text-sm text-slate-500 mt-1">{form.emailAdmin || '-'}</p>
              <span className="inline-block mt-3 text-xs font-semibold px-3 py-1 rounded-full bg-green-100 text-green-600">
                Admin / Pengelola
              </span>
              <div className="mt-5 pt-5 border-t border-slate-100 text-left space-y-3">
                <div className="flex items-center gap-2 text-sm text-slate-600">
                  <Building2 size={15} className="text-slate-400" />
                  {form.namaUsaha || '-'}
                </div>
                <div className="flex items-center gap-2 text-sm text-slate-600">
                  <Phone size={15} className="text-slate-400" />
                  {form.teleponUsaha || '-'}
                </div>
                <div className="flex items-start gap-2 text-sm text-slate-600">
                  <MapPin size={15} className="text-slate-400 mt-0.5 flex-shrink-0" />
                  <span>{form.alamatUsaha || '-'}</span>
                </div>
              </div>
            </Card>
          </div>

          <div className="lg:col-span-2 space-y-5">
            <Card className="p-6">
              <div className="flex items-center gap-2 mb-5">
                <User size={18} className="text-slate-600" />
                <h3 className="text-sm font-bold text-slate-800">Profil Admin</h3>
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-medium text-slate-600 mb-1.5">Nama Admin</label>
                  <input type="text" value={form.namaAdmin} onChange={(e) => handleChange('namaAdmin', e.target.value)} className="w-full border rounded-xl px-3.5 py-2.5 text-sm text-slate-800 focus:outline-none focus:ring-2 border-slate-200 focus:ring-slate-100" />
                  {errors.namaAdmin && <p className="text-red-500 text-xs mt-1">{errors.namaAdmin}</p>}
                </div>
                <div>
                  <label className="block text-xs font-medium text-slate-600 mb-1.5">Email Admin</label>
                  <input type="email" value={form.emailAdmin} onChange={(e) => handleChange('emailAdmin', e.target.value)} className="w-full border rounded-xl px-3.5 py-2.5 text-sm text-slate-800 focus:outline-none focus:ring-2 border-slate-200 focus:ring-slate-100" />
                </div>
              </div>
            </Card>

            <Card className="p-6">
              <div className="flex items-center gap-2 mb-5">
                <Building2 size={18} className="text-slate-600" />
                <h3 className="text-sm font-bold text-slate-800">Informasi Usaha</h3>
              </div>
              <div className="space-y-4">
                <div>
                  <label className="block text-xs font-medium text-slate-600 mb-1.5">Nama Usaha</label>
                  <input type="text" value={form.namaUsaha} onChange={(e) => handleChange('namaUsaha', e.target.value)} className="w-full border rounded-xl px-3.5 py-2.5 text-sm text-slate-800 focus:outline-none focus:ring-2 border-slate-200 focus:ring-slate-100" />
                </div>
                <div>
                  <label className="block text-xs font-medium text-slate-600 mb-1.5">Nomor Kontak Usaha</label>
                  <input type="text" value={form.teleponUsaha} onChange={(e) => handleChange('teleponUsaha', e.target.value)} className="w-full border rounded-xl px-3.5 py-2.5 text-sm text-slate-800 focus:outline-none focus:ring-2 border-slate-200 focus:ring-slate-100" />
                </div>
                <div>
                  <label className="block text-xs font-medium text-slate-600 mb-1.5">Alamat Usaha</label>
                  <textarea value={form.alamatUsaha} onChange={(e) => handleChange('alamatUsaha', e.target.value)} rows={3} className="w-full border rounded-xl px-3.5 py-2.5 text-sm text-slate-800 focus:outline-none focus:ring-2 border-slate-200 focus:ring-slate-100 resize-none" />
                </div>
              </div>
            </Card>

            <Card className="p-6">
              <div className="flex items-center gap-2 mb-5">
                <Lock size={18} className="text-slate-600" />
                <h3 className="text-sm font-bold text-slate-800">Ubah Password</h3>
              </div>
              <div className="space-y-4">
                <div>
                  <label className="block text-xs font-medium text-slate-600 mb-1.5">Password Lama</label>
                  <div className="relative">
                    <input type={showPassword ? 'text' : 'password'} value={form.passwordLama} onChange={(e) => handleChange('passwordLama', e.target.value)} placeholder="Biarkan kosong jika tidak ingin mengubah" className="w-full border rounded-xl px-3.5 py-2.5 pr-10 text-sm text-slate-800 focus:outline-none focus:ring-2 border-slate-200 focus:ring-slate-100" />
                    <button type="button" onClick={() => setShowPassword(!showPassword)} className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400">
                      {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                    </button>
                  </div>
                </div>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-xs font-medium text-slate-600 mb-1.5">Password Baru</label>
                    <div className="relative">
                      <input type={showNewPassword ? 'text' : 'password'} value={form.passwordBaru} onChange={(e) => handleChange('passwordBaru', e.target.value)} placeholder="Password baru" className="w-full border rounded-xl px-3.5 py-2.5 pr-10 text-sm text-slate-800 focus:outline-none focus:ring-2 border-slate-200 focus:ring-slate-100" />
                      <button type="button" onClick={() => setShowNewPassword(!showNewPassword)} className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400">
                        {showNewPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                      </button>
                    </div>
                  </div>
                  <div>
                    <label className="block text-xs font-medium text-slate-600 mb-1.5">Konfirmasi Password</label>
                    <input type="password" value={form.konfirmasiPassword} onChange={(e) => handleChange('konfirmasiPassword', e.target.value)} placeholder="Ulangi password baru" className="w-full border border-slate-200 rounded-xl px-3.5 py-2.5 text-sm text-slate-800 focus:outline-none focus:ring-2 border-slate-200 focus:ring-slate-100" />
                  </div>
                </div>
              </div>
            </Card>

            <div className="flex justify-end">
              <button onClick={handleSave} disabled={isSaving} className="flex items-center gap-2 px-6 py-2.5 rounded-xl text-sm font-semibold text-slate-900 bg-lime-400 hover:bg-lime-500 transition-colors shadow-sm disabled:opacity-50">
                {isSaving ? <Loader2 size={16} className="animate-spin" /> : <Save size={16} />}
                Simpan Perubahan
              </button>
            </div>
          </div>
        </div>
      )}

      {activeTab === 'rekening' && (
        <Card className="p-6 animate-fade-in-up">
          <div className="flex justify-between items-center mb-6">
            <div>
              <h3 className="text-lg font-bold text-slate-800">Daftar Rekening Pembayaran</h3>
              <p className="text-sm text-slate-500 mt-1">Rekening aktif akan ditampilkan di aplikasi pelanggan</p>
            </div>
            <button
              onClick={openAddAccountModal}
              className="flex items-center gap-2 px-4 py-2 bg-lime-500 text-white rounded-lg text-sm font-semibold hover:bg-lime-600 transition-colors shadow-sm"
            >
              <Plus size={16} /> Tambah Rekening
            </button>
          </div>

          <div className="overflow-x-auto rounded-xl border border-slate-200">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-slate-50 border-b border-slate-200">
                  <th className="px-5 py-4 text-xs font-bold text-slate-500 uppercase tracking-wider">Urutan</th>
                  <th className="px-5 py-4 text-xs font-bold text-slate-500 uppercase tracking-wider">Bank & Nomor</th>
                  <th className="px-5 py-4 text-xs font-bold text-slate-500 uppercase tracking-wider">Atas Nama</th>
                  <th className="px-5 py-4 text-xs font-bold text-slate-500 uppercase tracking-wider">Status</th>
                  <th className="px-5 py-4 text-xs font-bold text-slate-500 uppercase tracking-wider text-center">Aksi</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {accounts.length === 0 ? (
                  <tr>
                    <td colSpan="5" className="px-5 py-8 text-center text-slate-500 text-sm">Belum ada data rekening.</td>
                  </tr>
                ) : (
                  accounts.map((acc) => (
                    <tr key={acc.id} className="hover:bg-slate-50/50 transition-colors">
                      <td className="px-5 py-4 text-sm text-slate-600">{acc.sort_order}</td>
                      <td className="px-5 py-4">
                        <div className="font-bold text-slate-800">{acc.bank_name}</div>
                        <div className="text-sm text-slate-500 font-mono mt-0.5">{acc.account_number}</div>
                      </td>
                      <td className="px-5 py-4 text-sm font-medium text-slate-700">{acc.account_holder_name}</td>
                      <td className="px-5 py-4">
                        <span className={`inline-flex px-2 py-1 rounded-full text-xs font-bold ${acc.is_active ? 'bg-green-100 text-green-700' : 'bg-slate-100 text-slate-600'}`}>
                          {acc.is_active ? 'Aktif' : 'Nonaktif'}
                        </span>
                      </td>
                      <td className="px-5 py-4">
                        <div className="flex items-center justify-center gap-2">
                          <button onClick={() => openEditAccountModal(acc)} className="p-1.5 text-blue-500 hover:bg-blue-50 rounded-lg" title="Edit">
                            <Edit2 size={16} />
                          </button>
                          <button onClick={() => handleToggleAccount(acc.id)} className={`p-1.5 rounded-lg ${acc.is_active ? 'text-slate-500 hover:bg-slate-100' : 'text-green-500 hover:bg-green-50'}`} title={acc.is_active ? 'Nonaktifkan' : 'Aktifkan'}>
                            {acc.is_active ? <PowerOff size={16} /> : <Power size={16} />}
                          </button>
                          <button onClick={() => handleDeleteAccount(acc.id)} className="p-1.5 text-red-500 hover:bg-red-50 rounded-lg" title="Hapus">
                            <Trash2 size={16} />
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </Card>
      )}

      {/* Rekening Modal */}
      {isAccountModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-sm">
          <div className="bg-white rounded-2xl w-full max-w-md overflow-hidden shadow-xl animate-scale-in">
            <div className="px-6 py-4 border-b border-slate-100 flex justify-between items-center bg-slate-50/50">
              <h3 className="font-bold text-slate-800">{accountForm.id ? 'Edit Rekening' : 'Tambah Rekening'}</h3>
              <button onClick={() => setIsAccountModalOpen(false)} className="text-slate-400 hover:text-slate-600">&times;</button>
            </div>
            <div className="p-6 space-y-4">
              <div>
                <label className="block text-xs font-medium text-slate-600 mb-1.5">Bank</label>
                <AppSelect
                  value={accountForm.bank_name}
                  onChange={(v) => setAccountForm({ ...accountForm, bank_name: v })}
                  options={[
                    { value: 'BCA', label: 'BCA' },
                    { value: 'BRI', label: 'BRI' },
                    { value: 'BNI', label: 'BNI' },
                    { value: 'Mandiri', label: 'Mandiri' },
                    { value: 'BSI', label: 'BSI' },
                    { value: 'CIMB Niaga', label: 'CIMB Niaga' },
                    { value: 'BTN', label: 'BTN' },
                    { value: 'Lainnya', label: 'Lainnya' }
                  ]}
                  className="w-full"
                />
              </div>
              {accountForm.bank_name === 'Lainnya' && (
                <div>
                  <label className="block text-xs font-medium text-slate-600 mb-1.5">Nama Bank Custom</label>
                  <input
                    type="text"
                    value={accountForm.custom_bank_name}
                    onChange={(e) => setAccountForm({ ...accountForm, custom_bank_name: e.target.value })}
                    placeholder="Masukkan nama bank"
                    className="w-full border rounded-xl px-3.5 py-2.5 text-sm text-slate-800 focus:outline-none focus:ring-2 border-slate-200 focus:ring-slate-100"
                  />
                </div>
              )}
              <div>
                <label className="block text-xs font-medium text-slate-600 mb-1.5">Nomor Rekening</label>
                <input
                  type="text"
                  value={accountForm.account_number}
                  onChange={(e) => setAccountForm({ ...accountForm, account_number: e.target.value.replace(/\D/g, '') })}
                  placeholder="Contoh: 1234567890"
                  className="w-full border rounded-xl px-3.5 py-2.5 text-sm text-slate-800 focus:outline-none focus:ring-2 border-slate-200 focus:ring-slate-100 font-mono"
                />
              </div>
              <div>
                <label className="block text-xs font-medium text-slate-600 mb-1.5">Atas Nama</label>
                <input
                  type="text"
                  value={accountForm.account_holder_name}
                  onChange={(e) => setAccountForm({ ...accountForm, account_holder_name: e.target.value })}
                  placeholder="Sesuai buku tabungan"
                  className="w-full border rounded-xl px-3.5 py-2.5 text-sm text-slate-800 focus:outline-none focus:ring-2 border-slate-200 focus:ring-slate-100"
                />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-medium text-slate-600 mb-1.5">Status Aktif</label>
                  <AppSelect
                    value={accountForm.is_active ? 'true' : 'false'}
                    onChange={(v) => setAccountForm({ ...accountForm, is_active: v === 'true' })}
                    options={[
                      { value: 'true', label: 'Aktif' },
                      { value: 'false', label: 'Nonaktif' }
                    ]}
                    className="w-full"
                  />
                </div>
                <div>
                  <label className="block text-xs font-medium text-slate-600 mb-1.5">Urutan Tampil</label>
                  <input
                    type="number"
                    value={accountForm.sort_order}
                    onChange={(e) => setAccountForm({ ...accountForm, sort_order: parseInt(e.target.value) || 0 })}
                    className="w-full border rounded-xl px-3.5 py-2.5 text-sm text-slate-800 focus:outline-none focus:ring-2 border-slate-200 focus:ring-slate-100"
                  />
                </div>
              </div>
            </div>
            <div className="px-6 py-4 border-t border-slate-100 flex justify-end gap-3 bg-slate-50/50">
              <button
                onClick={() => setIsAccountModalOpen(false)}
                className="px-4 py-2 text-sm font-medium text-slate-600 bg-white border border-slate-200 rounded-lg hover:bg-slate-50 transition-colors"
              >
                Batal
              </button>
              <button
                onClick={handleSaveAccount}
                className="px-4 py-2 text-sm font-semibold text-white bg-lime-500 rounded-lg hover:bg-lime-600 transition-colors shadow-sm"
              >
                Simpan Rekening
              </button>
            </div>
          </div>
        </div>
      )}
    </Layout>
  );
}
