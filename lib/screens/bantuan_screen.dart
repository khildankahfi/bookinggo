import 'package:flutter/material.dart';

class BantuanScreen extends StatefulWidget {
  const BantuanScreen({super.key});

  @override
  State<BantuanScreen> createState() => _BantuanScreenState();
}

class _BantuanScreenState extends State<BantuanScreen> {
  static const Color _primaryColor = Color(0xFF5E5CE6);

  final List<Map<String, dynamic>> _faqList = [
    {
      'pertanyaan': 'Bagaimana cara melakukan reservasi lapangan?',
      'jawaban':
          'Pilih lapangan yang ingin kamu pesan dari halaman Home atau Explore, lalu pilih tanggal dan jam yang tersedia, kemudian pilih metode pembayaran dan konfirmasi booking.',
      'isOpen': false,
    },
    {
      'pertanyaan': 'Berapa lama sebelum booking harus dikonfirmasi?',
      'jawaban':
          'Booking harus dikonfirmasi maksimal 1 jam sebelum jadwal. Jika tidak dikonfirmasi, slot akan otomatis dibatalkan dan tersedia untuk pengguna lain.',
      'isOpen': false,
    },
    {
      'pertanyaan': 'Bagaimana jika saya ingin membatalkan booking?',
      'jawaban':
          'Kamu bisa membatalkan booking melalui menu Riwayat Reservasi. Pilih booking yang ingin dibatalkan dan tekan tombol "Batalkan". Pembatalan dapat dilakukan minimal 2 jam sebelum jadwal.',
      'isOpen': false,
    },
    {
      'pertanyaan': 'Apakah ada refund jika booking dibatalkan?',
      'jawaban':
          'Kebijakan refund bergantung pada waktu pembatalan. Pembatalan lebih dari 24 jam sebelum jadwal mendapat refund penuh. Pembatalan kurang dari 24 jam tidak mendapat refund.',
      'isOpen': false,
    },
    {
      'pertanyaan': 'Metode pembayaran apa saja yang tersedia?',
      'jawaban':
          'Kami menerima pembayaran melalui E-Wallet (GoPay, OVO, DANA, ShopeePay), Transfer Bank (BCA, BNI, Mandiri, BRI Virtual Account), dan pembayaran tunai langsung di tempat.',
      'isOpen': false,
    },
    {
      'pertanyaan': 'Bagaimana cara mengubah profil saya?',
      'jawaban':
          'Masuk ke tab Profil, lalu tekan tombol "Edit Profil". Kamu bisa mengubah nama, email, nomor HP, dan password dari halaman tersebut.',
      'isOpen': false,
    },
  ];

  final List<Map<String, dynamic>> _kontakList = [
    {
      'icon': Icons.phone_outlined,
      'label': 'Telepon',
      'value': '021-1234-5678',
      'color': Colors.green,
    },
    {
      'icon': Icons.email_outlined,
      'label': 'Email',
      'value': 'support@reservasilapangan.id',
      'color': Colors.blue,
    },
    {
      'icon': Icons.chat_bubble_outline,
      'label': 'WhatsApp',
      'value': '0812-3456-7890',
      'color': Colors.green,
    },
    {
      'icon': Icons.access_time,
      'label': 'Jam Operasional',
      'value': 'Senin–Minggu, 07:00–22:00',
      'color': _primaryColor,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Bantuan',
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
            // ── Header ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5E5CE6), Color(0xFF8B89F0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.support_agent,
                      color: Colors.white, size: 36),
                  const SizedBox(height: 10),
                  const Text(
                    'Ada yang bisa kami bantu?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tim kami siap membantu kamu\n7 hari seminggu',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── FAQ ──
            const Text(
              'Pertanyaan Umum (FAQ)',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 10),
            Container(
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
                children: _faqList.asMap().entries.map((entry) {
                  final index = entry.key;
                  final faq = entry.value;
                  final isLast = index == _faqList.length - 1;

                  return Column(
                    children: [
                      InkWell(
                        onTap: () => setState(
                            () => faq['isOpen'] = !(faq['isOpen'] as bool)),
                        borderRadius: BorderRadius.vertical(
                          top: index == 0
                              ? const Radius.circular(16)
                              : Radius.zero,
                          bottom: isLast
                              ? const Radius.circular(16)
                              : Radius.zero,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  faq['pertanyaan'],
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: faq['isOpen']
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: faq['isOpen']
                                        ? _primaryColor
                                        : const Color(0xFF1A1A2E),
                                  ),
                                ),
                              ),
                              Icon(
                                faq['isOpen']
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: Colors.grey,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Jawaban accordion
                      AnimatedCrossFade(
                        duration: const Duration(milliseconds: 200),
                        crossFadeState: faq['isOpen']
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                        firstChild: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                          child: Text(
                            faq['jawaban'],
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                        secondChild: const SizedBox.shrink(),
                      ),
                      if (!isLast)
                        Divider(height: 1, color: Colors.grey.shade100),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // ── Kontak ──
            const Text(
              'Hubungi Kami',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 10),
            Container(
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
                children: _kontakList.asMap().entries.map((entry) {
                  final index = entry.key;
                  final kontak = entry.value;
                  final isLast = index == _kontakList.length - 1;

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: (kontak['color'] as Color)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                kontak['icon'] as IconData,
                                color: kontak['color'] as Color,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  kontak['label'],
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 11),
                                ),
                                Text(
                                  kontak['value'],
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A1A2E),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (!isLast)
                        Divider(height: 1, color: Colors.grey.shade100,
                            indent: 66),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // ── Versi Aplikasi ──
            Center(
              child: Text(
                'Reservasi Lapangan v1.0.0',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}