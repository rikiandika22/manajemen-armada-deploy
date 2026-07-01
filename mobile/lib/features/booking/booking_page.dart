import 'dart:io';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/auth/auth_state.dart';
import 'package:mobile/features/booking/booking_success_page.dart';
import 'package:mobile/core/services/order_service.dart';
import 'package:mobile/core/services/payment_account_service.dart';
import 'package:mobile/features/payment/models/payment_account_model.dart';
import 'package:mobile/features/payment/widgets/payment_account_selector.dart';
import 'package:mobile/core/utils/app_snackbar.dart';

class BookingPage extends StatefulWidget {
  final Map<String, dynamic>? bookingData;

  const BookingPage({super.key, this.bookingData});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  bool _isAgreed = false;
  bool _isLoading = false;
  final TextEditingController _notesController = TextEditingController();

  File? _proofFile;
  String? _proofFileName;
  int? _proofFileSize;
  
  int? _selectedAccountId;
  List<PaymentAccount> _accounts = [];
  bool _isLoadingAccounts = false;

  bool get _isUploadValid => _proofFile != null;
  bool get _isAccountValid => _selectedAccountId != null;

  @override
  void initState() {
    super.initState();
    _fetchAccounts();
    if (widget.bookingData?['catatanPerjalanan'] != null) {
      _notesController.text = widget.bookingData!['catatanPerjalanan'];
    }
  }

  Future<void> _fetchAccounts() async {
    setState(() => _isLoadingAccounts = true);
    try {
      final service = PaymentAccountService();
      final accounts = await service.fetchPaymentAccounts();
      setState(() {
        _accounts = accounts;
        if (accounts.isNotEmpty) {
          _selectedAccountId = accounts.first.id;
        }
      });
    } catch (e) {
      debugPrint('Failed to load accounts: $e');
    } finally {
      setState(() => _isLoadingAccounts = false);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        return '${parts[2]}-${parts[1]}-${parts[0]}';
      }
    } catch (_) {}
    return DateTime.now().toIso8601String().split('T')[0];
  }

  String _parseDateTime(String dateStr, dynamic timeStr) {
    final date = _parseDate(dateStr);
    final time = timeStr?.toString().replaceAll(' WIB', '').replaceAll('.', ':') ?? '00:00';
    return '$date $time:00';
  }

  void _handleSubmit() async {
    if (!_isAgreed) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final requestData = {
        'service_type': widget.bookingData?['armadaType'] ?? 'Bus Pariwisata',
        'fleet_name': widget.bookingData?['armadaName'] ?? 'Bus Executive 40 Seat',
        'fleet_type': widget.bookingData?['armadaType']?.toString().contains('Bus') == true ? 'Bus' : (widget.bookingData?['armadaType']?.toString().contains('Elf') == true ? 'Elf' : 'Truk'),
        'origin': widget.bookingData?['lokasiJemputText'] ?? 'Grobogan',
        'destination': widget.bookingData?['lokasiTujuanText'] ?? 'Semarang',
        'departure_date': widget.bookingData?['tanggalBerangkatRaw'] ?? (widget.bookingData?['tanggalBerangkat'] != null ? _parseDate(widget.bookingData!['tanggalBerangkat']) : DateTime.now().toIso8601String().split('T')[0]),
        'departure_time': widget.bookingData?['jamBerangkatRaw'] ?? (widget.bookingData?['jamBerangkat']?.toString().replaceAll(' WIB', '').replaceAll('.', ':') ?? '07:00'),
        'estimated_finish': widget.bookingData?['tanggalSelesaiRaw'] != null && widget.bookingData?['jamSelesaiRaw'] != null
            ? '${widget.bookingData!['tanggalSelesaiRaw']} ${widget.bookingData!['jamSelesaiRaw']}'
            : (widget.bookingData?['tanggalSelesai'] != null ? _parseDateTime(widget.bookingData!['tanggalSelesai'], widget.bookingData?['jamSelesai']) : null),
        if (widget.bookingData?['lokasiJemputLat'] != null) 'origin_latitude': widget.bookingData!['lokasiJemputLat'],
        if (widget.bookingData?['lokasiJemputLng'] != null) 'origin_longitude': widget.bookingData!['lokasiJemputLng'],
        if (widget.bookingData?['lokasiTujuanLat'] != null) 'destination_latitude': widget.bookingData!['lokasiTujuanLat'],
        if (widget.bookingData?['lokasiTujuanLng'] != null) 'destination_longitude': widget.bookingData!['lokasiTujuanLng'],
        'notes': _notesController.text,
        'payment_account_id': _selectedAccountId,
      };

      await OrderService().createOrder(requestData, paymentProof: _proofFile);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BookingSuccessPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        AppSnackBar.showError(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTruk = widget.bookingData?['armadaType']?.toString().contains('Truk') == true || widget.bookingData?['armadaType']?.toString().contains('Truck') == true;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Konfirmasi Reservasi',
          style: TextStyle(
            color: AppColors.primaryNavy,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryNavy),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildFleetCard(),
                      const SizedBox(height: 16),
                      _buildScheduleCard(context),
                      const SizedBox(height: 16),
                      _buildCustomerCard(),
                      const SizedBox(height: 16),
                      _buildNotesField(),
                      const SizedBox(height: 16),
                      _buildPaymentInfoCard(),
                      if (!isTruk) ...[
                        const SizedBox(height: 16),
                        _buildBankSelectionCard(),
                        const SizedBox(height: 16),
                        _buildPaymentInstructions(),
                        const SizedBox(height: 16),
                        _buildUploadProofCard(),
                        const SizedBox(height: 24),
                      ],
                      if (isTruk) const SizedBox(height: 24),
                      _buildAgreementCheck(),
                      const SizedBox(height: 120), // Spacer for sticky bottom action
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildBottomAction(),
    );
  }

  Widget _buildFleetCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.textMuted.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.softNavy,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.directions_bus, color: AppColors.surface, size: 40),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.bookingData?['armadaName'] ?? 'Bus Executive 40 Seat',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.bookingData?['armadaType'] ?? 'Bus Pariwisata'} • ${widget.bookingData?['capacity'] ?? '40 Kursi'}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${widget.bookingData?['price'] ?? 'Rp 2.500.000'} / hari',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.accentLime),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Tersedia',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildScheduleCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.textMuted.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Jadwal Pemakaian',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); 
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryNavy,
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Ubah Jadwal', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.borderSoft),
          _buildInfoRow('Lokasi Jemput', widget.bookingData?['lokasiJemputText'] ?? 'Grobogan'),
          const SizedBox(height: 12),
          _buildInfoRow('Lokasi Tujuan', widget.bookingData?['lokasiTujuanText'] ?? 'Semarang'),
          const SizedBox(height: 12),
          _buildInfoRow('Tanggal Berangkat', widget.bookingData?['tanggalBerangkat'] ?? '28 Mei 2026'),
          const SizedBox(height: 12),
          _buildInfoRow('Jam Berangkat', '${widget.bookingData?['jamBerangkat'] ?? '07.00'} WIB'),
          const SizedBox(height: 12),
          _buildInfoRow('Perkiraan Selesai', '${widget.bookingData?['tanggalSelesai'] ?? '28 Mei 2026'}, ${widget.bookingData?['jamSelesai'] ?? '18.00'} WIB'),
        ],
      ),
    );
  }

  Widget _buildCustomerCard() {
    final user = AuthState.instance.user ?? {};
    final name = user['name'] ?? 'User Name';
    final email = user['email'] ?? 'email@example.com';
    final phone = user['phone'] ?? 'Belum ditambahkan';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.textMuted.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Data Pemesan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
              ),
              TextButton(
                onPressed: () {
                  AppSnackBar.showInfo(context, 'Fitur ubah profil akan dibuat');
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryNavy,
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Ubah Profil', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          if (phone == 'Belum ditambahkan') ...[
            const SizedBox(height: 4),
            const Text(
              'Lengkapi data profil agar admin lebih mudah menghubungi Anda',
              style: TextStyle(fontSize: 11, color: Colors.orange),
            ),
          ],
          const Divider(height: 24, color: AppColors.borderSoft),
          _buildInfoRow('Nama', name),
          const SizedBox(height: 12),
          _buildInfoRow('Email', email),
          const SizedBox(height: 12),
          _buildInfoRow('Nomor HP', phone),
        ],
      ),
    );
  }

  Widget _buildNotesField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Catatan Tambahan',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Contoh: Jemput di depan rumah, rombongan keluarga, membawa barang bawaan',
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderSoft),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderSoft),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primaryNavy),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfoCard() {
    final isTruk = widget.bookingData?['armadaType']?.toString().contains('Truk') == true || widget.bookingData?['armadaType']?.toString().contains('Truck') == true;

    String priceStr = widget.bookingData?['price'] ?? '0';
    int basePrice = 0;
    try {
      basePrice = int.parse(priceStr.replaceAll(RegExp(r'[^0-9]'), ''));
    } catch (_) {}

    final dp = (basePrice * 0.2).toInt();
    final sisa = basePrice - dp;

    String formatCurrency(int value) {
      return 'Rp ${value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rincian Pembayaran',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isTruk ? 'Harga Sewa' : 'Estimasi Harga',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              Text(
                isTruk ? 'Menunggu Harga' : formatCurrency(basePrice),
                style: TextStyle(
                  fontSize: 13, 
                  fontWeight: FontWeight.bold, 
                  color: isTruk ? Colors.orange : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          
          if (!isTruk) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'DP yang harus dibayar',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                ),
                Text(
                  formatCurrency(dp),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.accentLime),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sisa Pembayaran',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                Text(
                  formatCurrency(sisa),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Status Pembayaran',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Belum Membayar',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '*Estimasi harga dihitung di sistem berdasarkan lokasi, tujuan, dan durasi penggunaan. Harga final dapat menyesuaikan hasil kalkulasi backend.',
              style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontStyle: FontStyle.italic),
            ),
          ] else ...[
            const SizedBox(height: 8),
            const Text(
              '*Admin akan mengirimkan rincian harga setelah Anda menyelesaikan permintaan ini. Pembayaran dilakukan setelah harga dikirim.',
              style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBankSelectionCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: PaymentAccountSelector(
        accounts: _accounts,
        selectedAccountId: _selectedAccountId,
        isLoading: _isLoadingAccounts,
        onSelected: (id) {
          setState(() {
            _selectedAccountId = id;
          });
        },
      ),
    );
  }

  Widget _buildPaymentInstructions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.primaryNavy.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.primaryNavy.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.info_outline, color: AppColors.primaryNavy, size: 20),
              SizedBox(width: 8),
              Text(
                'Instruksi Pembayaran',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInstructionStep('1', 'Transfer nominal DP ke salah satu rekening yang tersedia.'),
          const SizedBox(height: 8),
          _buildInstructionStep('2', 'Pastikan nama pengirim sesuai dengan data pemesan.'),
          const SizedBox(height: 8),
          _buildInstructionStep('3', 'Simpan bukti transfer dan unggah pada form di bawah.'),
          const SizedBox(height: 8),
          _buildInstructionStep('4', 'Admin akan memvalidasi pembayaran setelah reservasi dikirim.'),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$number. ',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
          ),
        ),
      ],
    );
  }

  Future<void> _pickProofFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final sizeInBytes = file.lengthSync();
        final sizeInMb = sizeInBytes / (1024 * 1024);

        if (sizeInMb > 2) {
          if (!mounted) return;
          AppSnackBar.showWarning(context, 'Ukuran file maksimal 2 MB');
          return;
        }

        setState(() {
          _proofFile = file;
          _proofFileName = result.files.single.name;
          _proofFileSize = sizeInBytes;
        });
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, 'Terjadi kesalahan saat memilih file: $e');
    }
  }

  Widget _buildUploadProofCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upload Bukti Transfer',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
          ),
          const SizedBox(height: 12),
          if (_proofFile != null)
            _buildProofPreview()
          else
            _buildUploadPlaceholder(),
        ],
      ),
    );
  }

  Widget _buildUploadPlaceholder() {
    return InkWell(
      onTap: _pickProofFile,
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: AppColors.borderSoft, style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            const Icon(Icons.cloud_upload_outlined, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 16),
            const Text(
              'Unggah Bukti Transfer',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
            ),
            const SizedBox(height: 4),
            const Text(
              'Format JPG, PNG, atau PDF. Maksimal 2 MB.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickProofFile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                foregroundColor: AppColors.surface,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Pilih File', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProofPreview() {
    final isPdf = _proofFileName?.toLowerCase().endsWith('.pdf') ?? false;
    final sizeKb = (_proofFileSize ?? 0) / 1024;
    final sizeText = sizeKb > 1024 ? '${(sizeKb / 1024).toStringAsFixed(1)} MB' : '${sizeKb.toStringAsFixed(0)} KB';

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.accentLime),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(8.0),
            ),
            clipBehavior: Clip.hardEdge,
            child: isPdf
                ? const Icon(Icons.picture_as_pdf, color: Colors.red, size: 32)
                : Image.file(_proofFile!, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _proofFileName ?? 'file',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  sizeText,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _proofFile = null;
                _proofFileName = null;
                _proofFileSize = null;
              });
            },
            icon: const Icon(Icons.close, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildAgreementCheck() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: CheckboxListTile(
        value: _isAgreed,
        onChanged: (val) {
          setState(() {
            _isAgreed = val ?? false;
          });
        },
        activeColor: AppColors.primaryNavy,
        controlAffinity: ListTileControlAffinity.leading,
        title: const Text(
          'Saya memastikan data reservasi dan bukti pembayaran sudah benar.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction() {
    final bool canSubmit = _isAgreed && _isAccountValid && _isUploadValid;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            if (!_isAccountValid) {
              AppSnackBar.showWarning(context, 'Pilih rekening tujuan terlebih dahulu');
              return;
            }
            if (!_isUploadValid) {
              AppSnackBar.showWarning(context, 'Upload bukti transfer terlebih dahulu');
              return;
            }
            if (!_isAgreed) {
              AppSnackBar.showWarning(context, 'Anda harus mencentang persetujuan');
              return;
            }
            
            if (!_isLoading) {
              _handleSubmit();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: canSubmit ? AppColors.accentLime : AppColors.borderSoft,
            foregroundColor: canSubmit ? AppColors.primaryNavy : AppColors.textSecondary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isLoading 
            ? const SizedBox(
                width: 20, 
                height: 20, 
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryNavy),
              )
            : const Text(
                'Kirim Reservasi dan Bukti Transfer',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
        ),
      ),
    );
  }
}
