class Court {
  final String id;
  final String name;
  final List<String> bookedSlots;
  final bool isAvailable; // FIX: field baru dari admin toggle

  const Court({
    required this.id,
    required this.name,
    this.bookedSlots = const [],
    this.isAvailable = true, // default tersedia
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

  bool isAllCourtsBooked(DateTime date, int hour) {
    return courts.every((c) => c.isSlotBooked(date, hour));
  }

  int availableCourtsCount(DateTime date, int hour) {
    return courts.where((c) => !c.isSlotBooked(date, hour)).length;
  }
}

// ════════════════════════════════════════════
//  SAMPLE DATA
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
      Court(id: '1-a', name: 'Lapangan 1', isAvailable: true),
      Court(id: '1-b', name: 'Lapangan 2', isAvailable: true),
      Court(id: '1-c', name: 'Lapangan 3', isAvailable: true),
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
      Court(id: '2-a', name: 'Lapangan 1', isAvailable: true),
      Court(id: '2-b', name: 'Lapangan 2', isAvailable: true),
      Court(id: '2-c', name: 'Lapangan 3', isAvailable: true),
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
      Court(id: '3-a', name: 'Lapangan 1', isAvailable: true),
      Court(id: '3-b', name: 'Lapangan 2', isAvailable: true),
      Court(id: '3-c', name: 'Lapangan 3', isAvailable: true),
      Court(id: '3-d', name: 'Lapangan 4', isAvailable: true),
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
      Court(id: '4-a', name: 'Lapangan 1', isAvailable: true),
      Court(id: '4-b', name: 'Lapangan 2', isAvailable: true),
      Court(id: '4-c', name: 'Lapangan 3', isAvailable: true),
    ],
  ),
];