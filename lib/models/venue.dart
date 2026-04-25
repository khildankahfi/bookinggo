class Court {
  final String id;
  final String name; // "Lapangan 1", "Lapangan 2", dst
  final List<String> bookedSlots; // Format: 'YYYY-MM-DD_HH:00'

  const Court({
    required this.id,
    required this.name,
    this.bookedSlots = const [],
  });

  bool isSlotBooked(DateTime date, int hour) {
    final key =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}_${hour.toString().padLeft(2, '0')}:00';
    return bookedSlots.contains(key);
  }
}

class Venue {
  final String id;
  final String name;
  final String category;
  final double rating;
  final String imageUrl;
  final String location;
  final int pricePerHour;
  final List<Court> courts;

  const Venue({
    required this.id,
    required this.name,
    required this.category,
    required this.rating,
    required this.imageUrl,
    required this.location,
    required this.pricePerHour,
    required this.courts,
  });

  // Cek apakah semua court penuh di slot tertentu
  bool isAllCourtsBooked(DateTime date, int hour) {
    return courts.every((c) => c.isSlotBooked(date, hour));
  }

  // Hitung jumlah court tersedia di slot tertentu
  int availableCourtsCount(DateTime date, int hour) {
    return courts.where((c) => !c.isSlotBooked(date, hour)).length;
  }
}

// ════════════════════════════════════════════
//  SAMPLE DATA — Setiap venue punya 3-4 court
// ════════════════════════════════════════════
final List<Venue> sampleVenues = [
  Venue(
    id: '1',
    name: 'Futsal Arena',
    category: 'Futsal',
    rating: 4.8,
    imageUrl: '',
    location: 'Jakarta Selatan',
    pricePerHour: 150000,
    courts: [
      Court(
        id: '1-a',
        name: 'Lapangan 1',
        bookedSlots: [
          '2026-03-27_08:00',
          '2026-03-27_09:00',
          '2026-03-27_14:00',
        ],
      ),
      Court(
        id: '1-b',
        name: 'Lapangan 2',
        bookedSlots: [
          '2026-03-27_08:00',
          '2026-03-27_10:00',
          '2026-03-28_13:00',
        ],
      ),
      Court(
        id: '1-c',
        name: 'Lapangan 3',
        bookedSlots: [
          '2026-03-27_14:00',
          '2026-03-27_15:00',
          '2026-03-28_09:00',
        ],
      ),
    ],
  ),
  Venue(
    id: '2',
    name: 'K14 Arena',
    category: 'Basket',
    rating: 4.6,
    imageUrl: '',
    location: 'Jakarta Pusat',
    pricePerHour: 200000,
    courts: [
      Court(
        id: '2-a',
        name: 'Lapangan 1',
        bookedSlots: [
          '2026-03-27_10:00',
          '2026-03-27_11:00',
        ],
      ),
      Court(
        id: '2-b',
        name: 'Lapangan 2',
        bookedSlots: [
          '2026-03-28_15:00',
          '2026-03-28_16:00',
        ],
      ),
      Court(
        id: '2-c',
        name: 'Lapangan 3',
        bookedSlots: [
          '2026-03-27_09:00',
          '2026-03-28_10:00',
        ],
      ),
    ],
  ),
  Venue(
    id: '3',
    name: 'Pro Master',
    category: 'Badminton',
    rating: 4.9,
    imageUrl: '',
    location: 'Jakarta Barat',
    pricePerHour: 100000,
    courts: [
      Court(
        id: '3-a',
        name: 'Lapangan 1',
        bookedSlots: [
          '2026-03-27_07:00',
          '2026-03-27_08:00',
        ],
      ),
      Court(
        id: '3-b',
        name: 'Lapangan 2',
        bookedSlots: [
          '2026-03-28_16:00',
          '2026-03-28_17:00',
        ],
      ),
      Court(
        id: '3-c',
        name: 'Lapangan 3',
        bookedSlots: [
          '2026-03-27_10:00',
          '2026-03-27_11:00',
        ],
      ),
      Court(
        id: '3-d',
        name: 'Lapangan 4',
        bookedSlots: [
          '2026-03-27_13:00',
        ],
      ),
    ],
  ),
  Venue(
    id: '4',
    name: 'Voli Center',
    category: 'Voli',
    rating: 4.5,
    imageUrl: '',
    location: 'Jakarta Timur',
    pricePerHour: 120000,
    courts: [
      Court(
        id: '4-a',
        name: 'Lapangan 1',
        bookedSlots: [
          '2026-03-27_13:00',
        ],
      ),
      Court(
        id: '4-b',
        name: 'Lapangan 2',
        bookedSlots: [
          '2026-03-28_09:00',
          '2026-03-28_10:00',
        ],
      ),
      Court(
        id: '4-c',
        name: 'Lapangan 3',
        bookedSlots: [],
      ),
    ],
  ),
];