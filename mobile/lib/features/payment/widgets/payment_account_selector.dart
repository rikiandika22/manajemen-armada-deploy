import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/features/payment/models/payment_account_model.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/utils/app_snackbar.dart';

class PaymentAccountSelector extends StatelessWidget {
  final List<PaymentAccount> accounts;
  final int? selectedAccountId;
  final Function(int) onSelected;
  final bool isLoading;

  const PaymentAccountSelector({
    super.key,
    required this.accounts,
    required this.selectedAccountId,
    required this.onSelected,
    this.isLoading = false,
  });

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    AppSnackBar.showSuccess(context, 'Nomor rekening berhasil disalin');
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (accounts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[500]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Rekening pembayaran belum tersedia. Silakan hubungi admin.',
                style: TextStyle(color: Colors.red[700], fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih Rekening Tujuan',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...accounts.map((account) {
          final isSelected = account.id == selectedAccountId;
          
          return GestureDetector(
            onTap: () => onSelected(account.id),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryNavy.withValues(alpha: 0.05) : Colors.white,
                border: Border.all(
                  color: isSelected ? AppColors.primaryNavy : Colors.grey[200]!,
                  width: isSelected ? 1.5 : 1.0,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryNavy.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.account_balance,
                      color: AppColors.primaryNavy,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.bankName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          account.accountNumber,
                          style: const TextStyle(
                            fontSize: 15,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'a.n ${account.accountHolderName}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20, color: AppColors.primaryNavy),
                      onPressed: () => _copyToClipboard(context, account.accountNumber),
                      tooltip: 'Salin nomor rekening',
                    ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.primaryNavy,
                      size: 24,
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}
