import 'package:flutter/material.dart';

class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  static const Color _primaryColor = Color(0xFF5E5CE6);

  // Sample notifikasi — di production ambil dari Firestore
  final List<Map<String, dynamic>> _notifikasi = [
    {
      'id': '1',
      'judul': 'Booking Dikonfirmasi ✅',
      'pesan': 'Booking kamu di Futsal Arena pada Senin, 21 Apr 2026 pukul 08:00 telah dikonfirmasi.',
      'waktu': '2 jam lalu',
      'tipe': 'booking',
      'dibaca': false,
    },
    {
      'id': '2',
      'judul': 'Promo Spesial 🎉',
      'pesan': 'Diskon 20% untuk semua lapangan badminton setiap Selasa. Berlaku hingga akhir bulan!',
      'waktu': '1 hari lalu',
      'tipe': 'promo',
      'dibaca': false,
    },
    {
      'id': '3',
      'judul': 'Pengingat Booking ⏰',
      'pesan': 'Jangan lupa! Kamu punya booking di K14 Arena besok pukul 10:00. Hadir tepat waktu ya.',
      'waktu': '2 hari lalu',
      'tipe': 'reminder',
      'dibaca': true,
    },
    {
      'id': '4',
      'judul': 'Selamat Datang! 👋',
      'pesan': 'Akun kamu berhasil dibuat. Mulai reservasi lapangan olahraga favoritmu sekarang!',
      'waktu': '5 hari lalu',
      'tipe': 'info',
      'dibaca': true,
    },
  ];

  int get _jumlahBelumDibaca =>
      _notifikasi.where((n) => n['dibaca'] == false).length;

  void _tandaiDibaca(String id) {
    setState(() {
      final notif = _notifikasi.firstWhere((n) => n['id'] == id);
      notif['dibaca'] = true;
    });
  }

  void _tandaiSemuaDibaca() {
    setState(() {
      for (final n in _notifikasi) {
        n['dibaca'] = true;
      }
    });
  }

  IconData _getIcon(String tipe) {
    switch (tipe) {
      case 'booking':
        return Icons.confirmation_number_outlined;
      case 'promo':
        return Icons.local_offer_outlined;
      case 'reminder':
        return Icons.alarm;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getColor(String tipe) {
    switch (tipe) {
      case 'booking':
        return Colors.green;
      case 'promo':
        return Colors.orange;
      case 'reminder':
        return Colors.blue;
      default:
        return _primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Notifikasi',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (_jumlahBelumDibaca > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$_jumlahBelumDibaca',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ]
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        centerTitle: true,
        actions: [
          if (_jumlahBelumDibaca > 0)
            TextButton(
              onPressed: _tandaiSemuaDibaca,
              child: const Text(
                'Baca Semua',
                style: TextStyle(color: _primaryColor, fontSize: 13),
              ),
            ),
        ],
      ),
      body: _notifikasi.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _notifikasi.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _buildNotifCard(_notifikasi[i]),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none,
              size: 72, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          const Text(
            'Tidak ada notifikasi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kamu akan mendapat notifikasi\nseputar booking dan promo di sini',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifCard(Map<String, dynamic> notif) {
    final bool dibaca = notif['dibaca'] as bool;
    final color = _getColor(notif['tipe']);

    return GestureDetector(
      onTap: () => _tandaiDibaca(notif['id']),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: dibaca ? Colors.white : _primaryColor.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: dibaca ? Colors.transparent : _primaryColor.withOpacity(0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon tipe notifikasi
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_getIcon(notif['tipe']), color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif['judul'],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: dibaca
                                ? FontWeight.w500
                                : FontWeight.bold,
                            color: const Color(0xFF1A1A2E),
                          ),
                        ),
                      ),
                      // Dot belum dibaca
                      if (!dibaca)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: _primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif['pesan'],
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notif['waktu'],
                    style: TextStyle(
                        color: Colors.grey.shade400, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}