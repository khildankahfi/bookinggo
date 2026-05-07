import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/venue.dart';
import 'venue_service.dart';

class FavoriteService {
  static final _db   = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String? get _uid => _auth.currentUser?.uid;

  // ── Ambil semua venue favorit user ──
  static Future<List<Venue>> getFavorites() async {
    try {
      final uid = _uid;
      if (uid == null) return [];

      final snapshot = await _db
          .collection('favorites')
          .where('userId', isEqualTo: uid)
          .get()
          .timeout(const Duration(seconds: 5));

      if (snapshot.docs.isEmpty) return [];

      // Ambil venueId dari koleksi favorit
      final venueIds = snapshot.docs
          .map((d) => d.data()['venueId'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      // Fetch detail setiap venue
      final venues = <Venue>[];
      for (final id in venueIds) {
        final venue = await VenueService.getVenueDetail(id);
        if (venue != null) venues.add(venue);
      }

      return venues;
    } catch (_) {
      return [];
    }
  }

  // ── Cek apakah venue sudah difavoritkan ──
  static Future<bool> isFavorite(String venueId) async {
    try {
      final uid = _uid;
      if (uid == null) return false;

      final snapshot = await _db
          .collection('favorites')
          .where('userId', isEqualTo: uid)
          .where('venueId', isEqualTo: venueId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ── Toggle favorit (tambah/hapus) ──
  static Future<bool> toggleFavorite(String venueId) async {
    try {
      final uid = _uid;
      if (uid == null) return false;

      final snapshot = await _db
          .collection('favorites')
          .where('userId', isEqualTo: uid)
          .where('venueId', isEqualTo: venueId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // Sudah favorit → hapus
        await snapshot.docs.first.reference.delete();
        return false; // false = sudah dihapus dari favorit
      } else {
        // Belum favorit → tambah
        await _db.collection('favorites').add({
          'userId':    uid,
          'venueId':   venueId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return true; // true = berhasil ditambah
      }
    } catch (_) {
      return false;
    }
  }

  // ── Hapus dari favorit ──
  static Future<void> removeFavorite(String venueId) async {
    try {
      final uid = _uid;
      if (uid == null) return;

      final snapshot = await _db
          .collection('favorites')
          .where('userId', isEqualTo: uid)
          .where('venueId', isEqualTo: venueId)
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (_) {}
  }
}