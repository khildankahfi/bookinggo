import 'package:flutter/material.dart';
import '../models/venue.dart';
import '../services/booking_service.dart';
import 'riwayat_screen.dart';
import 'payment_instruction_screen.dart';

class PaymentScreen extends StatefulWidget {
  final Venue venue;
  final Court court;
  final DateTime date;
  final int hour;

  const PaymentScreen({
    super.key,
    required this.venue,
    required this.court,
    required this.date,
    required this.hour,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  static const Color _primaryColor = Color(0xFF5E5CE6);

  String _selectedPayment = '';
  bool _isProcessing = false;

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'group': 'E-Wallet',
      'methods': [
        {'id': 'gopay', 'name': 'GoPay', 'icon': Icons.account_balance_wallet, 'color': Colors.green},
        {'id': 'ovo', 'name': 'OVO', 'icon': Icons.account_balance_wallet, 'color': Colors.purple},
        {'id': 'dana', 'name': 'DANA', 'icon': Icons.account_balance_wallet, 'color': Colors.blue},
        {'id': 'shopeepay', 'name': 'ShopeePay', 'icon': Icons.account_balance_wallet, 'color': Colors.orange},
      ],
    },
    {
      'group': 'Transfer Bank',
      'methods': [
        {'id': 'bca', 'name': 'BCA Virtual Account', 'icon': Icons.account_balance, 'color': Colors.blue},
        {'id': 'bni', 'name': 'BNI Virtual Account', 'icon': Icons.account_balance, 'color': Colors.orange},
        {'id': 'mandiri', 'name': 'Mandiri Virtual Account', 'icon': Icons.account_balance, 'color': Colors.yellow},
        {'id': 'bri', 'name': 'BRI Virtual Account', 'icon': Icons.account_balance, 'color': Colors.lightBlue},
      ],
    },
    {
      'group': 'Bayar di Tempat',
      'methods': [
        {'id': 'cash', 'name': 'Cash (Bayar Langsung)', 'icon': Icons.payments_outlined, 'color': Colors.teal},
      ],
    },
  ];

  String _formatHarga(int harga) {
    final str = harga.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return 'Rp $buffer';
  }

  String _formatDate(DateTime d) {
    const hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const bulan = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${hari[d.weekday - 1]}, ${d.day} ${bulan[d.month]} ${d.year}';
  }

  // FIX: harga dinamis berdasarkan hari (weekday/weekend)
  int get _totalBayar => widget.venue.getPriceForDate(widget.date);
  String get _priceLabel => widget.venue.getPriceLabel(widget.date);
  int get _biayaAdmin => 2000;
  int get _grandTotal => _totalBayar + _biayaAdmin;

  Future<void> _prosesPayment() async {
    if (_selectedPayment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih metode pembayaran terlebih dahulu'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // FIX FLOW: Jangan langsung simpan booking saat user tekan "Bayar Sekarang"
    // Arahkan dulu ke instruksi pembayaran → user konfirmasi → baru booking disimpan
    // Ini mensimulasikan flow nyata payment gateway (Midtrans/Xendit)
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentInstructionScreen(
          venue: widget.venue,
          court: widget.court,
          date: widget.date,
          hour: widget.hour,
          paymentMethod: _selectedPayment,
          totalPrice: _grandTotal,
        ),
      ),
    );
  }

  void _showSuccessDialog(String bookingCode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 52),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pembayaran Berhasil!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Booking ${widget.court.name} di ${widget.venue.name} telah dikonfirmasi.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.08),
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
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const RiwayatScreen()),
                    (route) => route.isFirst,
                  );
                },
                child: const Text('Lihat Riwayat Booking'),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: const Text('Kembali ke Beranda',
                  style: TextStyle(color: Colors.grey)),
            ),
            const SizedBox(height: 4),
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
        title: const Text(
          'Pembayaran',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBookingSummary(),
            const SizedBox(height: 16),
            _buildPriceSummary(),
            const SizedBox(height: 16),
            _buildPaymentMethods(),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBookingSummary() {
    final categoryColor = {
      'Futsal': Colors.green,
      'Basket': Colors.orange,
      'Badminton': Colors.blue,
      'Voli': Colors.teal,
    }[widget.venue.category] ?? _primaryColor;

    final categoryIcon = {
      'Futsal': Icons.sports_soccer,
      'Basket': Icons.sports_basketball,
      'Badminton': Icons.sports_tennis,
      'Voli': Icons.sports_volleyball,
    }[widget.venue.category] ?? Icons.sports;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long_outlined, color: _primaryColor, size: 18),
              SizedBox(width: 8),
              Text(
                'Ringkasan Booking',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(categoryIcon, color: categoryColor, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.venue.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.court.name,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          _summaryRow(
            Icons.calendar_today_outlined,
            'Tanggal',
            _formatDate(widget.date),
          ),
          const SizedBox(height: 8),
          _summaryRow(
            Icons.access_time,
            'Jam',
            '${widget.hour.toString().padLeft(2, '0')}:00 – ${(widget.hour + 1).toString().padLeft(2, '0')}:00',
          ),
          const SizedBox(height: 8),
          _summaryRow(Icons.timelapse, 'Durasi', '1 Jam'),
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.payments_outlined, color: _primaryColor, size: 18),
              SizedBox(width: 8),
              Text(
                'Rincian Harga',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _priceRow(_priceLabel, _formatHarga(_totalBayar)),
          const SizedBox(height: 8),
          _priceRow('Biaya admin', _formatHarga(_biayaAdmin)),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Pembayaran',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              Text(
                _formatHarga(_grandTotal),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: _primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: Color(0xFF1A1A2E))),
      ],
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            children: [
              Icon(Icons.credit_card, color: _primaryColor, size: 18),
              SizedBox(width: 8),
              Text(
                'Metode Pembayaran',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
        ),
        ..._paymentMethods.map((group) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 4),
                child: Text(
                  group['group'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                decoration: _cardDecoration(),
                child: Column(
                  children: (group['methods'] as List).asMap().entries.map((entry) {
                    final index = entry.key;
                    final method = entry.value as Map<String, dynamic>;
                    final isLast = index == (group['methods'] as List).length - 1;
                    final isSelected = _selectedPayment == method['id'];

                    return Column(
                      children: [
                        InkWell(
                          onTap: () =>
                              setState(() => _selectedPayment = method['id']),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: (method['color'] as Color)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    method['icon'] as IconData,
                                    color: method['color'] as Color,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    method['name'] as String,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF1A1A2E),
                                    ),
                                  ),
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? _primaryColor
                                          : Colors.grey.shade300,
                                      width: 2,
                                    ),
                                    color: isSelected
                                        ? _primaryColor
                                        : Colors.white,
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check,
                                          color: Colors.white, size: 12)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (!isLast)
                          Divider(
                            height: 1,
                            indent: 64,
                            color: Colors.grey.shade100,
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Bayar',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              Text(
                _formatHarga(_grandTotal),
                style: const TextStyle(
                  color: _primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _prosesPayment,
              child: _isProcessing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text('Bayar Sekarang',
                      style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}