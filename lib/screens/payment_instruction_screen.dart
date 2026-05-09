import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/venue.dart';
import '../services/booking_service.dart';
import 'riwayat_screen.dart';

/// Screen ini muncul SETELAH user pilih metode pembayaran.
/// Menampilkan instruksi pembayaran → user konfirmasi → baru booking disimpan.
/// Ini mensimulasikan flow nyata: Midtrans / Xendit / dll.
class PaymentInstructionScreen extends StatefulWidget {
  final Venue venue;
  final Court court;
  final DateTime date;
  final int hour;
  final int duration;
  final String paymentMethod;
  final int totalPrice;

  const PaymentInstructionScreen({
    super.key,
    required this.venue,
    required this.court,
    required this.date,
    required this.hour,
    this.duration = 1,
    required this.paymentMethod,
    required this.totalPrice,
  });

  @override
  State<PaymentInstructionScreen> createState() =>
      _PaymentInstructionScreenState();
}

class _PaymentInstructionScreenState extends State<PaymentInstructionScreen> {
  static const Color _primaryColor = Color(0xFF5E5CE6);

  bool _isProcessing = false;

  // ── Timer countdown 30 menit ──
  int _remainingSeconds = 30 * 60;
  Timer? _timer;
  bool _timerExpired = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ── Mulai countdown timer ──
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }

      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timerExpired = true;
          timer.cancel();
        }
      });
    });
  }

  // ── Format detik ke MM:SS ──
  String get _timerDisplay {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // ── Warna timer berdasarkan sisa waktu ──
  Color get _timerColor {
    if (_remainingSeconds <= 60)  return Colors.red.shade700;   // < 1 menit → merah
    if (_remainingSeconds <= 300) return Colors.orange.shade700; // < 5 menit → oranye
    return Colors.green.shade700;  // > 5 menit → hijau
  }

  Color get _timerBgColor {
    if (_remainingSeconds <= 60)  return Colors.red.shade50;
    if (_remainingSeconds <= 300) return Colors.orange.shade50;
    return Colors.green.shade50;
  }

  Color get _timerBorderColor {
    if (_remainingSeconds <= 60)  return Colors.red.shade200;
    if (_remainingSeconds <= 300) return Colors.orange.shade200;
    return Colors.green.shade200;
  }

  // ── Generate nomor/kode palsu yang realistis ──
  String get _virtualAccountNumber {
    final base = DateTime.now().millisecondsSinceEpoch.toString();
    switch (widget.paymentMethod) {
      case 'bca':
        // FIX: base = 13 digit di 2026, substring(11,15) error karena index 15 tidak ada
        // Pakai length - N agar aman berapa pun panjang string timestamp
        return '7382-${base.substring(base.length - 8, base.length - 4)}-${base.substring(base.length - 4)}';
      case 'bni':
        return '8277-${base.substring(base.length - 8, base.length - 4)}-${base.substring(base.length - 4)}';
      case 'mandiri':
        return '8882-${base.substring(base.length - 8, base.length - 4)}-${base.substring(base.length - 4)}';
      case 'bri':
        return '0088-${base.substring(base.length - 8, base.length - 4)}-${base.substring(base.length - 4)}';
      default:
        return base.substring(base.length - 9);
    }
  }

  String get _ewalletCode {
    // FIX: millisecondsSinceEpoch = 13 digit di 2026
    // Ambil dari belakang agar selalu aman berapa pun panjang string-nya
    final ts = DateTime.now().millisecondsSinceEpoch.toString();
    return ts.substring(ts.length - 9);
  }

  // ── Tentukan tipe pembayaran ──
  bool get _isEwallet =>
      ['gopay', 'ovo', 'dana', 'shopeepay'].contains(widget.paymentMethod);
  bool get _isBank =>
      ['bca', 'bni', 'mandiri', 'bri'].contains(widget.paymentMethod);
  bool get _isCash => widget.paymentMethod == 'cash';

  String get _methodName {
    const names = {
      'gopay': 'GoPay', 'ovo': 'OVO', 'dana': 'DANA',
      'shopeepay': 'ShopeePay', 'bca': 'BCA Virtual Account',
      'bni': 'BNI Virtual Account', 'mandiri': 'Mandiri Virtual Account',
      'bri': 'BRI Virtual Account', 'cash': 'Cash (Bayar Langsung)',
    };
    return names[widget.paymentMethod] ?? widget.paymentMethod;
  }

  String _formatHarga(int harga) {
    final str = harga.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return 'Rp $buffer';
  }

  // ── Konfirmasi bayar → simpan booking ke Firestore ──
  Future<void> _konfirmasiBayar() async {
    setState(() => _isProcessing = true);

    final dateStr =
        '${widget.date.year}-${widget.date.month.toString().padLeft(2, '0')}-${widget.date.day.toString().padLeft(2, '0')}';

    final result = await BookingService.createBooking(
      venueId: widget.venue.id,
      courtId: widget.court.id,
      venueName: widget.venue.name,
      courtName: widget.court.name,
      date: dateStr,
      hour: widget.hour,
      duration: widget.duration,
      paymentMethod: _methodName,
      totalPrice: widget.totalPrice,
    );

    setState(() => _isProcessing = false);

    if (!mounted) return;

    if (result['success'] == true) {
      _showSuccessDialog(result['bookingCode'] ?? '');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Pembayaran gagal'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccessDialog(String bookingCode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: Colors.green.shade50, shape: BoxShape.circle),
              child: const Icon(Icons.check_circle,
                  color: Colors.green, size: 52),
            ),
            const SizedBox(height: 16),
            const Text('Pembayaran Terkirim!',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 8),
            Text(
              'Booking ${widget.court.name} di ${widget.venue.name} sedang menunggu konfirmasi admin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.grey.shade600, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.hourglass_top, color: Colors.orange.shade700, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Menunggu konfirmasi admin',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.confirmation_number_outlined,
                      color: _primaryColor, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    bookingCode.isNotEmpty ? bookingCode : '-',
                    style: const TextStyle(
                      color: _primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Kembali ke root lalu buka RiwayatScreen
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const RiwayatScreen()),
                    (route) => route.isFirst,
                  );
                },
                child: const Text('Lihat Riwayat Booking'),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: const Text('Kembali ke Beranda',
                  style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Instruksi Pembayaran',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Timer batas bayar ──
            _buildTimerCard(),
            const SizedBox(height: 16),

            // ── Instruksi sesuai metode ──
            if (_isEwallet) _buildEwalletCard(),
            if (_isBank) _buildBankCard(),
            if (_isCash) _buildCashCard(),
            const SizedBox(height: 16),

            // ── Ringkasan order ──
            _buildOrderSummary(),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildTimerCard() {
    if (_timerExpired) {
      // Timer habis → tampilkan peringatan
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.shade300),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.timer_off, color: Colors.red.shade700, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Waktu pembayaran habis!',
                          style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                      Text('Silakan kembali dan buat booking baru.',
                          style: TextStyle(
                              color: Colors.red.shade600, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () =>
                    Navigator.popUntil(context, (r) => r.isFirst),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red.shade300),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Kembali ke Beranda'),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _timerBgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _timerBorderColor),
      ),
      child: Row(
        children: [
          // Animasi ikon timer
          Icon(
            _remainingSeconds <= 60
                ? Icons.timer_off_outlined
                : Icons.timer_outlined,
            color: _timerColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _remainingSeconds <= 60
                      ? '⚠️ Segera selesaikan pembayaran!'
                      : 'Selesaikan pembayaran dalam',
                  style: TextStyle(
                      color: _timerColor, fontSize: 12),
                ),
                Row(
                  children: [
                    Text(
                      _timerDisplay,
                      style: TextStyle(
                        color: _timerColor,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        fontFeatures: const [
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'menit',
                      style: TextStyle(
                          color: _timerColor,
                          fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEwalletCard() {
    final qrCode = _ewalletCode;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
              Icons.account_balance_wallet_outlined, 'Bayar via $_methodName'),
          const SizedBox(height: 16),

          // QR Code simulasi
          Center(
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code_2,
                      size: 100, color: Color(0xFF1A1A2E)),
                  Text('Scan QR Code',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 11)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Text('Atau masukkan kode pembayaran:',
              style: TextStyle(fontSize: 13, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 8),
          _copyableCode(qrCode),
          const SizedBox(height: 16),

          _buildSteps([
            'Buka aplikasi $_methodName di smartphone kamu',
            'Pilih menu "Bayar" atau "Scan QR"',
            'Scan QR di atas atau masukkan kode pembayaran',
            'Cek detail pembayaran, pastikan nominal benar',
            'Tekan "Konfirmasi Bayar" di bawah setelah selesai',
          ]),
        ],
      ),
    );
  }

  Widget _buildBankCard() {
    final vaNumber = _virtualAccountNumber;
    final bankName = _methodName.replaceAll(' Virtual Account', '');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.account_balance_outlined,
              'Transfer ke $bankName Virtual Account'),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nomor Virtual Account $bankName',
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 12)),
                const SizedBox(height: 6),
                _copyableCode(vaNumber),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildSteps([
            'Login ke mobile banking / ATM $bankName kamu',
            'Pilih menu "Transfer" → "Virtual Account"',
            'Masukkan nomor VA: $vaNumber',
            'Cek nama & nominal — pastikan sudah benar',
            'Selesaikan transfer, lalu tekan "Konfirmasi Bayar" di bawah',
          ]),

          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Nominal transfer harus tepat: ${_formatHarga(widget.totalPrice)}',
                    style: TextStyle(
                        color: Colors.blue.shade700, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
              Icons.payments_outlined, 'Bayar Tunai di Tempat'),
          const SizedBox(height: 16),

          _buildSteps([
            'Datang ke lokasi lapangan sesuai jadwal booking',
            'Tunjukkan kode booking ke petugas',
            'Bayar tunai sebesar ${_formatHarga(widget.totalPrice)}',
            'Petugas akan mengkonfirmasi pembayaran',
          ]),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.amber.shade700, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Hadir minimal 15 menit sebelum jadwal. Booking hangus jika tidak hadir.',
                    style: TextStyle(
                        color: Colors.amber.shade800,
                        fontSize: 12,
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.receipt_long_outlined, 'Ringkasan Pesanan'),
          const SizedBox(height: 14),
          _row('Venue', widget.venue.name),
          const SizedBox(height: 6),
          _row('Lapangan', widget.court.name),
          const SizedBox(height: 6),
          _row('Tanggal',
              '${widget.date.day}/${widget.date.month}/${widget.date.year}'),
          const SizedBox(height: 6),
          _row('Jam',
              '${widget.hour.toString().padLeft(2, '0')}:00 – ${(widget.hour + 1).toString().padLeft(2, '0')}:00'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Bayar',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E))),
              Text(
                _formatHarga(widget.totalPrice),
                style: const TextStyle(
                  color: _primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: (_isProcessing || _timerExpired) ? null : _konfirmasiBayar,
              child: _isProcessing
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 20),
                        SizedBox(width: 8),
                        Text('Saya Sudah Bayar',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey,
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: const Text('Batalkan & Pilih Metode Lain'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper widgets ──

  Widget _copyableCode(String code) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              code,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: _primaryColor,
                letterSpacing: 2,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Kode disalin!'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: const Icon(Icons.copy, color: _primaryColor, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSteps(List<String> steps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cara Pembayaran:',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.grey.shade700)),
        const SizedBox(height: 8),
        ...steps.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22, height: 22,
                    decoration: const BoxDecoration(
                        color: _primaryColor, shape: BoxShape.circle),
                    child: Center(
                      child: Text('${e.key + 1}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(e.value,
                        style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                            height: 1.4)),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: _primaryColor, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E))),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: Color(0xFF1A1A2E))),
      ],
    );
  }

  BoxDecoration _cardDecor() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );
}