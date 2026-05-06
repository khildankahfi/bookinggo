import 'package:cloud_firestore/cloud_firestore.dart';

/// Service untuk cek ketersediaan slot secara real-time dari Firestore.
/// Mengambil data dari DUA sumber:
/// 1. collection 'bookings'      → slot yang sudah dipesan user
/// 2. collection 'blocked_slots' → slot yang diblok admin
class SlotService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Ambil semua jam yang tidak tersedia untuk satu lapangan + tanggal.
  /// Return: Set<int> berisi jam yang sudah terpakai (0-23)
  static Future<SlotAvailability> getUnavailableSlots({
    required String courtId,
    required String date, // format: 'yyyy-MM-dd'
  }) async {
    try {
      // Jalankan kedua query secara paralel agar lebih cepat
      final results = await Future.wait([
        _fetchBookedHours(courtId, date),
        _fetchBlockedHours(courtId, date),
      ]);

      return SlotAvailability(
        bookedHours:  results[0],
        blockedHours: results[1],
      );
    } catch (e) {
      // Kalau gagal (offline/timeout), return kosong — tidak blok user
      return SlotAvailability(bookedHours: {}, blockedHours: {});
    }
  }

  /// Ambil jam yang sudah dipesan dari collection 'bookings'
  static Future<Set<int>> _fetchBookedHours(String courtId, String date) async {
    try {
      final snapshot = await _db
          .collection('bookings')
          .where('courtId', isEqualTo: courtId)
          .where('date', isEqualTo: date)
          .get()
          .timeout(const Duration(seconds: 5));

      final bookedHours = <int>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String? ?? '';
        if (status != 'active' && status != 'pending') continue;

        final hour     = (data['hour'] as num?)?.toInt() ?? -1;
        final duration = (data['duration'] as num?)?.toInt() ?? 1;

        // Tambahkan semua slot yang dipakai booking ini
        // Misal: jam 08:00 durasi 2 jam → block 8 dan 9
        if (hour >= 0) {
          for (int i = 0; i < duration; i++) {
            bookedHours.add(hour + i);
          }
        }
      }
      return bookedHours;
    } catch (_) {
      return {};
    }
  }

  /// Ambil jam yang diblok admin dari collection 'blocked_slots'
  /// Doc ID format: '{courtId}_{date}'
  static Future<Set<int>> _fetchBlockedHours(String courtId, String date) async {
    try {
      final doc = await _db
          .collection('blocked_slots')
          .doc('${courtId}_$date')
          .get()
          .timeout(const Duration(seconds: 5));

      if (!doc.exists) return {};

      final hours = doc.data()?['hours'] as List<dynamic>? ?? [];
      return hours.map((h) => (h as num).toInt()).toSet();
    } catch (_) {
      return {};
    }
  }
}

/// Data class hasil query slot
class SlotAvailability {
  final Set<int> bookedHours;   // dipesan user lain
  final Set<int> blockedHours;  // diblok admin

  const SlotAvailability({
    required this.bookedHours,
    required this.blockedHours,
  });

  /// Cek apakah jam tertentu tidak tersedia (karena alasan apapun)
  bool isUnavailable(int hour) =>
      bookedHours.contains(hour) || blockedHours.contains(hour);

  /// Cek spesifik kenapa tidak tersedia
  bool isBooked(int hour)  => bookedHours.contains(hour);
  bool isBlocked(int hour) => blockedHours.contains(hour);

  /// Berapa slot yang masih tersedia dari jam operasional
  int availableCount(List<int> operationalHours) =>
      operationalHours.where((h) => !isUnavailable(h)).length;
}