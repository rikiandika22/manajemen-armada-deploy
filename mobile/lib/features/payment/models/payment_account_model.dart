class PaymentAccount {
  final int id;
  final String bankName;
  final String accountNumber;
  final String accountHolderName;

  PaymentAccount({
    required this.id,
    required this.bankName,
    required this.accountNumber,
    required this.accountHolderName,
  });

  factory PaymentAccount.fromJson(Map<String, dynamic> json) {
    return PaymentAccount(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      bankName: json['bank_name']?.toString() ?? json['bankName']?.toString() ?? '',
      accountNumber: json['account_number']?.toString() ?? json['accountNumber']?.toString() ?? '',
      accountHolderName: json['account_holder_name']?.toString() ?? json['accountHolderName']?.toString() ?? '',
    );
  }
}
