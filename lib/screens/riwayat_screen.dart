import 'package:flutter/material.dart';
import '../services/booking_service.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen>
    with SingleTickerProviderStateMixin {
  static const Color _primaryColor = Color(0xFF5E5CE6);
  late TabController _tabController;
  List<Map<String, dynamic>> _allBookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    final bookings = await BookingService.getBookings();
    setState(() {
      _allBookings = bookings;
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> _getByStatus(String status) {
    if (status == 'semua') return _allBookings;
    return _allBookings.where((b) => b['status'] == status).toList();
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

  // FIX BUG 3: Format jam dari int ke string 'HH:00 – HH+1:00'
  String _formatJam(dynamic hour) {
    if (hour == null) return '-';
    final h = (hour as num).toInt();
    return '${h.toString().padLeft(2, '0')}:00 – ${(h + 1).toString().padLeft(2, '0')}:00';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Riwayat Booking',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: _primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: _primaryColor,
          indicatorWeight: 3,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'Semua'),
            Tab(text: 'Aktif'),
            Tab(text: 'Menunggu'),
            Tab(text: 'Dibatalkan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList('semua'),
          _buildList('active'),
          _buildList('pending'),
          _buildList('cancelled'),
        ],
      ),
    );
  }

  Widget _buildList(String status) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final bookings = _getByStatus(status);
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey.shade200),
            const SizedBox(height: 12),
            Text(
              'Belum ada riwayat',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (_, i) => _buildBookingCard(bookings[i]),
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final status = booking['status'] as String? ?? '';

    Color statusColor;
    Color statusBg;
    String statusLabel;
    IconData statusIcon;

    switch (status) {
      // FIX BUG 3: Status dari Firestore adalah 'active', bukan 'confirmed'
      case 'active':
        statusColor = Colors.green.shade700;
        statusBg = Colors.green.shade50;
        statusLabel = 'Aktif';
        statusIcon = Icons.check_circle_outline;
        break;
      case 'pending':
        statusColor = Colors.orange.shade700;
        statusBg = Colors.orange.shade50;
        statusLabel = 'Menunggu Konfirmasi';
        statusIcon = Icons.hourglass_top;
        break;
      case 'cancelled':
        statusColor = Colors.red.shade700;
        statusBg = Colors.red.shade50;
        statusLabel = 'Dibatalkan';
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = Colors.grey;
        statusBg = Colors.grey.shade50;
        statusLabel = status;
        statusIcon = Icons.info_outline;
    }

    final categoryIcon = {
      'Futsal': Icons.sports_soccer,
      'Basket': Icons.sports_basketball,
      'Badminton': Icons.sports_tennis,
      'Voli': Icons.sports_volleyball,
    }[booking['category']] ??
        Icons.sports;

    final categoryColor = {
      'Futsal': Colors.green,
      'Basket': Colors.orange,
      'Badminton': Colors.blue,
      'Voli': Colors.teal,
    }[booking['category']] ??
        _primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(categoryIcon, color: categoryColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        // FIX BUG 3: Firestore menyimpan key 'venueName' (camelCase)
                        booking['venueName'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        // FIX BUG 3: key 'courtName' bukan 'court_name'
                        booking['courtName'] ?? '',
                        style:
                            TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey.shade100),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // FIX BUG 3: key 'bookingCode' bukan 'booking_code'
                _detailRow(Icons.tag, 'Kode Booking',
                    booking['bookingCode'] ?? booking['id'] ?? ''),
                const SizedBox(height: 6),
                _detailRow(Icons.calendar_today_outlined, 'Tanggal',
                    booking['date'] ?? ''),
                const SizedBox(height: 6),
                // FIX BUG 3: Firestore menyimpan 'hour' (int), bukan 'jam' (string)
                _detailRow(Icons.access_time, 'Jam',
                    _formatJam(booking['hour'])),
                const SizedBox(height: 6),
                // FIX BUG 3: key 'paymentMethod' bukan 'payment_method'
                _detailRow(Icons.payment, 'Pembayaran',
                    booking['paymentMethod'] ?? '-'),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Bayar',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13)),
                    Text(
                      // FIX BUG 3: key 'totalPrice' bukan 'total_price'
                      _formatHarga(
                          ((booking['totalPrice'] ?? 0) as num).toInt()),
                      style: const TextStyle(
                        color: _primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // FIX BUG 3: Tombol aksi untuk status 'active', bukan 'confirmed'
          if (status == 'active' || status == 'pending') ...[
            Divider(height: 1, color: Colors.grey.shade100),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _konfirmasiBatal(booking),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Batalkan',
                          style: TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade400),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
            color: Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }

  void _konfirmasiBatal(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Batalkan Booking?',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(
          'Apakah kamu yakin ingin membatalkan booking ini?',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tidak', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final result =
                  await BookingService.cancelBooking(booking['id']);
              if (result['success'] == true) {
                _loadBookings();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Booking berhasil dibatalkan'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
  }
}