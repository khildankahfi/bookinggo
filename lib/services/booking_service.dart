import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Ambil riwayat booking user ──
  static Future<List<Map<String, dynamic>>> getBookings() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return [];

      final snapshot = await _db
          .collection('bookings')
          .where('userId', isEqualTo: uid)
          .get()
          .timeout(const Duration(seconds: 8),
              onTimeout: () => throw Exception('timeout'));

      final bookings = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      bookings.sort((a, b) {
        final aTime = (a['createdAt'] as dynamic)?.millisecondsSinceEpoch ?? 0;
        final bTime = (b['createdAt'] as dynamic)?.millisecondsSinceEpoch ?? 0;
        if (aTime == bTime) {
          return (b['bookingCode'] ?? '').compareTo(a['bookingCode'] ?? '');
        }
        return bTime.compareTo(aTime);
      });

      return bookings;
    } catch (_) {
      return [];
    }
  }

  // ── Buat booking baru + cek double booking ──
  static Future<Map<String, dynamic>> createBooking({
    required String venueId,
    required String courtId,
    required String venueName,
    required String courtName,
    required String date,
    required int hour,
    required String paymentMethod,
    required int totalPrice,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        return {'success': false, 'message': 'User belum login'};
      }

      // ── STEP 1: Cek double booking ──
      // Query hanya 2 field (courtId + date) → tidak butuh composite index
      // Filter hour dan status dilakukan lokal di Dart
      final snapshot = await _db
          .collection('bookings')
          .where('courtId', isEqualTo: courtId)
          .where('date', isEqualTo: date)
          .get()
          .timeout(const Duration(seconds: 5),
              onTimeout: () => throw Exception('timeout'));

      // Cek lokal: ada booking active/pending di jam yang sama?
      // Tolak jika sudah ada booking active ATAU pending (menunggu konfirmasi)
      final isDoubleBooked = snapshot.docs.any((doc) {
        final data = doc.data();
        final sameHour = data['hour'] == hour;
        final status = data['status'] as String? ?? '';
        return sameHour && (status == 'active' || status == 'pending');
      });

      if (isDoubleBooked) {
        return {
          'success': false,
          'message':
              'Maaf, slot ${hour.toString().padLeft(2, '0')}:00 baru saja dipesan orang lain. Silakan pilih jam lain.',
        };
      }

      // ── STEP 2: Cek slot diblok admin ──
      final blockedDoc = await _db
          .collection('blocked_slots')
          .doc('${courtId}_$date')
          .get()
          .timeout(const Duration(seconds: 5));

      if (blockedDoc.exists) {
        final blockedHours =
            List<int>.from(blockedDoc.data()?['hours'] ?? []);
        if (blockedHours.contains(hour)) {
          return {
            'success': false,
            'message':
                'Slot ${hour.toString().padLeft(2, '0')}:00 ditutup oleh admin.',
          };
        }
      }

      // ── STEP 3: Simpan booking ──
      final ts = DateTime.now().millisecondsSinceEpoch.toString();
      final bookingCode = 'BK-${ts.substring(ts.length - 9)}';

      final docRef = await _db.collection('bookings').add({
        'userId': uid,
        'venueId': venueId,
        'courtId': courtId,
        'venueName': venueName,
        'courtName': courtName,
        'date': date,
        'hour': hour,
        'paymentMethod': paymentMethod,
        'totalPrice': totalPrice,
        'bookingCode': bookingCode,
        // Status awal 'pending' — menunggu konfirmasi admin
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'bookingId': docRef.id,
        'bookingCode': bookingCode,
      };
    } on FirebaseException catch (e) {
      return {
        'success': false,
        'message': 'Gagal booking: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString().contains('timeout')
            ? 'Koneksi lambat, coba lagi'
            : 'Gagal menyimpan booking, cek koneksi internet kamu',
      };
    }
  }

  // ── Batalkan booking ──
  static Future<Map<String, dynamic>> cancelBooking(String bookingId) async {
    try {
      await _db
          .collection('bookings')
          .doc(bookingId)
          .update({'status': 'cancelled'});
      return {'success': true};
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal membatalkan booking, cek koneksi internet kamu',
      };
    }
  }
}