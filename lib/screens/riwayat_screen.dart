import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // FIX: Format jam dengan baca duration dari Firestore
  // Sebelumnya selalu +1 jam, sekarang pakai field 'duration' yang tersimpan
  String _formatJam(dynamic hour, {dynamic duration}) {
    if (hour == null) return '-';
    final h = (hour as num).toInt();
    final dur = duration != null ? (duration as num).toInt() : 1;
    return '${h.toString().padLeft(2, '0')}:00 – ${(h + dur).toString().padLeft(2, '0')}:00';
  }

  // Format label durasi
  String _formatDurasi(dynamic duration) {
    if (duration == null) return '1 Jam';
    final dur = (duration as num).toInt();
    return '$dur Jam';
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
            color: Colors.black.withValues(alpha: 0.05),
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
                    color: categoryColor.withValues(alpha: 0.15),
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
                    _formatJam(booking['hour'], duration: booking['duration'])),
                const SizedBox(height: 6),
                _detailRow(Icons.timelapse, 'Durasi',
                    _formatDurasi(booking['duration'])),
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
                  const SizedBox(width: 8),
                  // Tombol share kode booking
                  OutlinedButton(
                    onPressed: () => _shareBooking(booking),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF5E5CE6),
                      side: const BorderSide(color: Color(0xFF5E5CE6)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.share_outlined, size: 14),
                        SizedBox(width: 4),
                        Text('Share', style: TextStyle(fontSize: 13)),
                      ],
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

  void _shareBooking(Map<String, dynamic> booking) {
    final code    = booking['bookingCode'] ?? '-';
    final venue   = booking['venueName']   ?? '-';
    final court   = booking['courtName']   ?? '-';
    final date    = booking['date']        ?? '-';
    final hour    = (booking['hour'] as num?)?.toInt() ?? 0;
    final jamStr  = '${hour.toString().padLeft(2, '0')}:00 – ${(hour+1).toString().padLeft(2, '0')}:00';
    final price   = (booking['totalPrice'] as num?)?.toInt() ?? 0;

    final text = '''
🏟️ Booking Reservasi Lapangan

📋 Kode: $code
🏟️ Venue: $venue
🎯 Lapangan: $court
📅 Tanggal: $date
⏰ Jam: $jamStr
💰 Total: Rp ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '\${m[1]}.')}

Tunjukkan kode ini ke petugas saat tiba di lokasi.
''';

    // Copy ke clipboard
    Clipboard.setData(ClipboardData(text: text.trim()));

    // Tampilkan bottom sheet
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Bagikan Kode Booking',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 16),

            // Kode booking besar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF5E5CE6).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF5E5CE6).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    code,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5E5CE6),
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$venue • \$court',
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 12),
                  ),
                  Text(
                    '\$date • \$jamStr',
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tombol copy
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text('Info booking disalin ke clipboard!'),
                      ]),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Salin Info Booking'),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup',
                  style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
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