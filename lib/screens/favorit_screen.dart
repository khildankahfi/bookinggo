import 'package:flutter/material.dart';
import '../models/venue.dart';
import '../services/favorite_service.dart';
import 'venue_detail_screen.dart';
import 'booking_screen.dart';

class FavoritScreen extends StatefulWidget {
  const FavoritScreen({super.key});

  @override
  State<FavoritScreen> createState() => _FavoritScreenState();
}

class _FavoritScreenState extends State<FavoritScreen> {
  static const Color _primaryColor = Color(0xFF5E5CE6);
  List<Venue> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    final favs = await FavoriteService.getFavorites();
    if (mounted) setState(() { _favorites = favs; _isLoading = false; });
  }

  Future<void> _hapusFavorit(String venueId) async {
    await FavoriteService.removeFavorite(venueId);
    setState(() => _favorites.removeWhere((v) => v.id == venueId));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dihapus dari favorit'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          const Text('Favorit',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          if (_favorites.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: _primaryColor, borderRadius: BorderRadius.circular(10)),
              child: Text('${_favorites.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ]
        ]),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favorites.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadFavorites,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _favorites.length,
                    itemBuilder: (_, i) => _buildCard(_favorites[i]),
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 72, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          const Text('Belum ada favorit',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 8),
          Text('Tap ikon ❤️ di halaman venue untuk\nmenambahkan ke favorit',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildCard(Venue venue) {
    final catColor = {'Futsal': Colors.green, 'Basket': Colors.orange,
        'Badminton': Colors.blue, 'Voli': Colors.teal}[venue.category] ?? _primaryColor;
    final catIcon = {'Futsal': Icons.sports_soccer, 'Basket': Icons.sports_basketball,
        'Badminton': Icons.sports_tennis, 'Voli': Icons.sports_volleyball}[venue.category]
        ?? Icons.sports;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => VenueDetailScreen(venue: venue))),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: catColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(catIcon, color: catColor, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(venue.name, style: const TextStyle(fontWeight: FontWeight.bold,
                    fontSize: 15, color: Color(0xFF1A1A2E))),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.location_on_outlined, size: 13,
                      color: Colors.grey.shade500),
                  const SizedBox(width: 2),
                  Text(venue.location,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.star, size: 13, color: Colors.amber),
                  const SizedBox(width: 2),
                  Text(venue.rating.toString(),
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  const SizedBox(width: 8),
                  Text('Rp ${venue.pricePerHour ~/ 1000}k/jam',
                      style: const TextStyle(color: _primaryColor,
                          fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ]),
            ),
            Column(children: [
              IconButton(
                icon: const Icon(Icons.favorite, color: Colors.redAccent, size: 22),
                onPressed: () => _hapusFavorit(venue.id),
                tooltip: 'Hapus favorit',
              ),
              SizedBox(
                height: 32,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => BookingScreen(venue: venue))),
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      textStyle: const TextStyle(fontSize: 11),
                      minimumSize: Size.zero),
                  child: const Text('Pesan'),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}