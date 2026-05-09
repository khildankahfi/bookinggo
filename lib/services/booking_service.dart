import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingService {
  static final FirebaseFirestore _db   = FirebaseFirestore.instance;
  static final FirebaseAuth      _auth = FirebaseAuth.instance;

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

  // ── Buat booking baru dengan Firestore Transaction ──
  // Transaction = atomic: cek + tulis tidak bisa diinterupsi user lain
  static Future<Map<String, dynamic>> createBooking({
    required String venueId,
    required String courtId,
    required String venueName,
    required String courtName,
    required String date,
    required int hour,
    int duration = 1,
    required String paymentMethod,
    required int totalPrice,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        return {'success': false, 'message': 'User belum login'};
      }

      // ── Cek slot diblok admin (di luar transaction — read only) ──
      final blockedDoc = await _db
          .collection('blocked_slots')
          .doc('${courtId}_$date')
          .get()
          .timeout(const Duration(seconds: 5));

      if (blockedDoc.exists) {
        final blockedHours = List<int>.from(blockedDoc.data()?['hours'] ?? []);
        final slotsNeeded  = List.generate(duration, (i) => hour + i);
        final blockedSlot  = slotsNeeded.firstWhere(
            (h) => blockedHours.contains(h), orElse: () => -1);
        if (blockedSlot != -1) {
          return {
            'success': false,
            'message': 'Slot jam ${blockedSlot.toString().padLeft(2, '0')}:00 ditutup oleh admin.',
          };
        }
      }

      // ── Kode booking ──
      final ts          = DateTime.now().millisecondsSinceEpoch.toString();
      final bookingCode = 'BK-${ts.substring(ts.length - 9)}';

      // ── Firestore Transaction: atomic check + write ──
      // Semua operasi dalam runTransaction dijamin tidak bisa diinterupsi
      // Kalau dua user coba bersamaan, Firestore otomatis retry salah satunya
      String? bookingId;
      String? errorMessage;

      await _db.runTransaction((transaction) async {
        final slotsNeeded = List.generate(duration, (i) => hour + i);

        // Baca semua dokumen slot yang dibutuhkan DALAM transaction
        // Format doc ID: {courtId}_{date}_{hour} — satu dokumen per slot
        final slotRefs = slotsNeeded.map((h) =>
            _db.collection('slot_locks').doc('${courtId}_${date}_$h')).toList();

        final slotSnaps = await Future.wait(
            slotRefs.map((ref) => transaction.get(ref)));

        // Cek apakah ada slot yang sudah terkunci
        for (int i = 0; i < slotSnaps.length; i++) {
          final snap   = slotSnaps[i];
          final slotH  = slotsNeeded[i];

          if (snap.exists) {
            final status = snap.data()?['status'] as String? ?? '';
            if (status == 'locked' || status == 'booked') {
              // STOP transaction — slot sudah diambil
              errorMessage =
                  'Maaf, slot jam ${slotH.toString().padLeft(2, '0')}:00 '
                  'baru saja dipesan orang lain. Silakan pilih jam lain.';
              return; // keluar dari transaction
            }
          }
        }

        // Kalau semua slot kosong → KUNCI semua slot dalam satu transaction
        for (int i = 0; i < slotRefs.length; i++) {
          transaction.set(slotRefs[i], {
            'venueId':  venueId,  // FIX: simpan venueId untuk filter
            'courtId':  courtId,
            'date':     date,
            'hour':     slotsNeeded[i],
            'status':   'locked',
            'userId':   uid,
            'lockedAt': FieldValue.serverTimestamp(),
          });
        }

        // Buat dokumen booking
        final bookingRef = _db.collection('bookings').doc();
        bookingId = bookingRef.id;

        transaction.set(bookingRef, {
          'userId':        uid,
          'venueId':       venueId,
          'courtId':       courtId,
          'venueName':     venueName,
          'courtName':     courtName,
          'date':          date,
          'hour':          hour,
          'duration':      duration,
          'endHour':       hour + duration,
          'paymentMethod': paymentMethod,
          'totalPrice':    totalPrice,
          'bookingCode':   bookingCode,
          'status':        'pending',
          'createdAt':     FieldValue.serverTimestamp(),
        });

        // Update status slot dari 'locked' → 'booked'
        for (final slotRef in slotRefs) {
          transaction.update(slotRef, {'status': 'booked'});
        }
      });

      // Cek apakah transaction gagal karena slot sudah terpakai
      if (errorMessage != null) {
        return {'success': false, 'message': errorMessage!};
      }

      return {
        'success':     true,
        'bookingId':   bookingId ?? '',
        'bookingCode': bookingCode,
      };

    } on FirebaseException catch (e) {
      // Transaction conflict → Firestore retry otomatis, kalau tetap gagal
      if (e.code == 'aborted' || e.code == 'failed-precondition') {
        return {
          'success': false,
          'message': 'Slot sudah dipesan oleh orang lain. Silakan pilih jam lain.',
        };
      }
      return {'success': false, 'message': 'Gagal booking: ${e.message}'};
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
      // Ambil data booking dulu untuk hapus slot_locks-nya
      final bookingDoc = await _db.collection('bookings').doc(bookingId).get();
      if (bookingDoc.exists) {
        final data     = bookingDoc.data()!;
        final venueId = data['venueId'] as String? ?? '';
        final courtId  = data['courtId'] as String? ?? '';
        final date     = data['date']    as String? ?? '';
        final hour     = (data['hour']   as num?)?.toInt() ?? 0;
        final duration = (data['duration'] as num?)?.toInt() ?? 1;

        // Hapus slot_locks agar slot bisa dipesan lagi
        final batch = _db.batch();
        batch.update(_db.collection('bookings').doc(bookingId),
            {'status': 'cancelled'});

        for (int i = 0; i < duration; i++) {
          final slotRef = _db
              .collection('slot_locks')
              .doc('${venueId}_${courtId}_${date}_${hour + i}');
          batch.delete(slotRef);
        }

        await batch.commit();
      } else {
        await _db.collection('bookings').doc(bookingId)
            .update({'status': 'cancelled'});
      }

      return {'success': true};
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal membatalkan booking, cek koneksi internet kamu',
      };
    }
  }
}