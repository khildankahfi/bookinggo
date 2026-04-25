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

      // FIX RIWAYAT: hapus .orderBy() — ini yang bikin query diam-diam gagal
      // karena butuh Composite Index yang belum dibuat di Firebase Console.
      // Sort dilakukan lokal setelah data masuk — hasilnya sama, tanpa index.
      final snapshot = await _db
          .collection('bookings')
          .where('userId', isEqualTo: uid)
          .get()
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () => throw Exception('timeout'),
          );

      final bookings = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Sort lokal: terbaru di atas — pakai bookingCode karena serverTimestamp
      // bisa null sesaat setelah write (belum sync dari server)
      bookings.sort((a, b) {
        final aTime = (a['createdAt'] as dynamic)?.millisecondsSinceEpoch ?? 0;
        final bTime = (b['createdAt'] as dynamic)?.millisecondsSinceEpoch ?? 0;
        // Fallback ke bookingCode jika timestamp sama/null
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

  // ── Buat booking baru ──
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

      final bookingCode =
          'BK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      // WRITE: tidak pakai timeout — Firestore write butuh 1–15 detik
      // tergantung koneksi. Timeout bikin booking tetap tersimpan tapi
      // user dapat error palsu (bug lama).
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
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'bookingId': docRef.id,
        'bookingCode': bookingCode,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal menyimpan booking, cek koneksi internet kamu',
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