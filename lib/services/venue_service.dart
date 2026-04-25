import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/venue.dart';

class VenueService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Ambil venue: sample data DULU, Firestore di background ──
  static Future<List<Venue>> getVenues({
    String? category,
    String? search,
  }) async {
    try {
      // FIX SPEED: Firestore diberi timeout 3 detik
      // Kalau lebih dari itu, langsung pakai sample data — tidak nunggu terus
      Query query = _db.collection('venues');
      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }

      final snapshot = await query
          .get()
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () => throw Exception('timeout'),
          );

      List<Venue> venues = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return _parseVenue(data);
      }).toList();

      // Kalau Firestore kosong, pakai sample data
      if (venues.isEmpty) venues = _filteredSample(category, search);

      // Filter search lokal
      if (search != null && search.isNotEmpty) {
        final q = search.toLowerCase();
        venues = venues
            .where((v) =>
                v.name.toLowerCase().contains(q) ||
                v.category.toLowerCase().contains(q))
            .toList();
      }

      return venues;
    } catch (_) {
      // Timeout atau error → langsung pakai sample, tidak spinner lama
      return _filteredSample(category, search);
    }
  }

  // ── Detail venue ──
  static Future<Venue?> getVenueDetail(String id) async {
    try {
      final doc = await _db
          .collection('venues')
          .doc(id)
          .get()
          .timeout(const Duration(seconds: 3));

      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return _parseVenue(data);
      }
      // Fallback ke sample
      return sampleVenues.where((v) => v.id == id).firstOrNull;
    } catch (_) {
      return sampleVenues.where((v) => v.id == id).firstOrNull;
    }
  }

  // ── Filter sample data lokal ──
  static List<Venue> _filteredSample(String? category, String? search) {
    var venues = sampleVenues;
    if (category != null && category.isNotEmpty) {
      venues = venues.where((v) => v.category == category).toList();
    }
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      venues = venues
          .where((v) =>
              v.name.toLowerCase().contains(q) ||
              v.category.toLowerCase().contains(q))
          .toList();
    }
    return venues;
  }

  // ── Parse Firestore data ke Venue model ──
  static Venue _parseVenue(Map<String, dynamic> data) {
    final List courtsData = data['courts'] ?? [];
    final courts = courtsData
        .map((c) => Court(
              id: c['id'].toString(),
              name: c['name'],
              bookedSlots: List<String>.from(c['bookedSlots'] ?? []),
            ))
        .toList();

    if (courts.isEmpty) {
      courts.addAll([
        Court(id: '${data['id']}-a', name: 'Lapangan 1'),
        Court(id: '${data['id']}-b', name: 'Lapangan 2'),
      ]);
    }

    return Venue(
      id: data['id'].toString(),
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 4.5,
      imageUrl: data['imageUrl'] ?? '',
      location: data['location'] ?? '',
      pricePerHour: (data['pricePerHour'] as num?)?.toInt() ?? 100000,
      courts: courts,
    );
  }
}