import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  static const Color _primaryColor = Color(0xFF5E5CE6);
  static final _db   = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _notifikasi = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifikasi();
  }

  Future<void> _loadNotifikasi() async {
    setState(() => _isLoading = true);
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) { setState(() => _isLoading = false); return; }

      final snapshot = await _db
          .collection('notifications')
          .where('userId', isEqualTo: uid)
          .get()
          .timeout(const Duration(seconds: 8));

      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      list.sort((a, b) => (b['sentAt'] ?? '').compareTo(a['sentAt'] ?? ''));
      setState(() { _notifikasi = list; _isLoading = false; });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _tandaiDibaca(String id) async {
    await _db.collection('notifications').doc(id).update({'isRead': true});
    setState(() {
      final i = _notifikasi.indexWhere((n) => n['id'] == id);
      if (i != -1) _notifikasi[i]['isRead'] = true;
    });
  }

  Future<void> _tandaiSemuaDibaca() async {
    final batch = _db.batch();
    for (final n in _notifikasi) {
      if (n['isRead'] != true) {
        batch.update(_db.collection('notifications').doc(n['id']), {'isRead': true});
      }
    }
    await batch.commit();
    setState(() { 
      for (final n in _notifikasi) {
        n['isRead'] = true;
        }
      });
  }

  int get _jumlahBelumDibaca =>
      _notifikasi.where((n) => n['isRead'] != true).length;

  IconData _getIcon(String tipe) {
    switch (tipe) {
      case 'promo':    return Icons.local_offer_outlined;
      case 'reminder': return Icons.alarm;
      case 'warning':  return Icons.warning_amber_rounded;
      default:         return Icons.notifications_outlined;
    }
  }

  Color _getColor(String tipe) {
    switch (tipe) {
      case 'promo':    return Colors.orange;
      case 'reminder': return _primaryColor;
      case 'warning':  return Colors.red;
      default:         return Colors.blue;
    }
  }

  String _formatWaktu(String? sentAt) {
    if (sentAt == null) return '-';
    try {
      final dt   = DateTime.parse(sentAt).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Baru saja';
      if (diff.inHours < 1)   return '${diff.inMinutes} menit lalu';
      if (diff.inDays < 1)    return '${diff.inHours} jam lalu';
      if (diff.inDays < 7)    return '${diff.inDays} hari lalu';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) { return '-'; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          const Text('Notifikasi',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          if (_jumlahBelumDibaca > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(10)),
              child: Text('$_jumlahBelumDibaca',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ]
        ]),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        centerTitle: true,
        actions: [
          if (_jumlahBelumDibaca > 0)
            TextButton(
              onPressed: _tandaiSemuaDibaca,
              child: const Text('Baca Semua',
                  style: TextStyle(color: _primaryColor, fontSize: 13)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifikasi.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none,
                          size: 72, color: Colors.grey.shade200),
                      const SizedBox(height: 16),
                      const Text('Tidak ada notifikasi',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A2E))),
                      const SizedBox(height: 8),
                      Text('Notifikasi dari admin akan muncul di sini',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 13)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifikasi,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifikasi.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _buildNotifCard(_notifikasi[i]),
                  ),
                ),
    );
  }

  Widget _buildNotifCard(Map<String, dynamic> notif) {
    final bool dibaca = notif['isRead'] == true;
    final tipe  = notif['type'] as String? ?? 'info';
    final color = _getColor(tipe);

    return GestureDetector(
      onTap: () { if (!dibaca) _tandaiDibaca(notif['id']); },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: dibaca ? Colors.white : _primaryColor.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: dibaca
                  ? Colors.transparent
                  : _primaryColor.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(_getIcon(tipe), color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(notif['title'] ?? '',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              dibaca ? FontWeight.w500 : FontWeight.bold,
                          color: const Color(0xFF1A1A2E))),
                ),
                if (!dibaca)
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                        color: _primaryColor, shape: BoxShape.circle),
                  ),
              ]),
              const SizedBox(height: 4),
              Text(notif['message'] ?? '',
                  style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12, height: 1.4)),
              const SizedBox(height: 6),
              Text(_formatWaktu(notif['sentAt']),
                  style: TextStyle(
                      color: Colors.grey.shade400, fontSize: 11)),
            ]),
          ),
        ]),
      ),
    );
  }
}