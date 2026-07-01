import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/auth/auth_state.dart';
import 'package:mobile/core/utils/app_snackbar.dart';
import 'package:mobile/shared/widgets/custom_input_field.dart';
import 'package:mobile/features/auth/login_page.dart';

class RegisterPage extends StatefulWidget {
  final VoidCallback? onRegisterSuccess;

  const RegisterPage({super.key, this.onRegisterSuccess});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      AppSnackBar.showWarning(context, 'Semua form wajib diisi');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      AppSnackBar.showWarning(context, 'Konfirmasi password tidak cocok');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthState.instance.register(
        _nameController.text,
        _emailController.text,
        _phoneController.text,
        _passwordController.text,
        _confirmPasswordController.text,
      );
      
      if (!mounted) return;

      AppSnackBar.showSuccess(context, 'Pendaftaran berhasil. Silakan masuk ke akun Anda.');

      // Redirect to login page and prepopulate email/username
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoginPage(
            onLoginSuccess: widget.onRegisterSuccess,
            initialEmail: _emailController.text,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryNavy,
        title: const Text('Daftar Akun', style: TextStyle(color: Colors.white, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Buat Akun Baru',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Daftar untuk menikmati pengalaman pemesanan yang lebih mudah.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              
              CustomInputField(
                label: 'Nama Lengkap',
                hintText: 'Masukkan nama Anda',
                prefixIcon: Icons.person_outline,
                controller: _nameController,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),

              CustomInputField(
                label: 'Email',
                hintText: 'Masukkan email Anda',
                prefixIcon: Icons.email_outlined,
                controller: _emailController,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),

              CustomInputField(
                label: 'Nomor HP',
                hintText: 'Masukkan nomor HP',
                prefixIcon: Icons.phone_outlined,
                controller: _phoneController,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              
              CustomInputField(
                label: 'Password',
                hintText: 'Masukkan password (min 8 karakter)',
                prefixIcon: Icons.lock_outline,
                controller: _passwordController,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),

              CustomInputField(
                label: 'Konfirmasi Password',
                hintText: 'Ulangi password',
                prefixIcon: Icons.lock_outline,
                controller: _confirmPasswordController,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading 
                      ? const SizedBox(
                          width: 20, 
                          height: 20, 
                          child: CircularProgressIndicator(color: AppColors.accentLime, strokeWidth: 2)
                        )
                      : const Text(
                          'Daftar Sekarang',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Sudah punya akun? ',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoginPage(onLoginSuccess: widget.onRegisterSuccess),
                        ),
                      );
                    },
                    child: const Text(
                      'Masuk',
                      style: TextStyle(
                        color: AppColors.primaryNavy,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
