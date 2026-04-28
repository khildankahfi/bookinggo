import 'package:flutter/material.dart';
import '../models/venue.dart';
import 'booking_screen.dart';

class VenueDetailScreen extends StatefulWidget {
  final Venue venue;
  const VenueDetailScreen({super.key, required this.venue});

  @override
  State<VenueDetailScreen> createState() => _VenueDetailScreenState();
}

class _VenueDetailScreenState extends State<VenueDetailScreen> {
  static const Color _primaryColor = Color(0xFF5E5CE6);
  bool _isFavorite = false;

  final List<Map<String, dynamic>> _reviews = [
    {
      'name': 'Budi S.',
      'rating': 5.0,
      'comment': 'Lapangan bersih, pelayanan ramah. Recommended!',
      'date': '20 Mar 2026',
    },
    {
      'name': 'Andi R.',
      'rating': 4.5,
      'comment': 'Tempatnya nyaman, harga terjangkau.',
      'date': '18 Mar 2026',
    },
    {
      'name': 'Sari W.',
      'rating': 4.0,
      'comment': 'Fasilitasnya lengkap, parkir luas.',
      'date': '15 Mar 2026',
    },
  ];

  Color get _categoryColor {
    switch (widget.venue.category) {
      case 'Futsal': return Colors.green;
      case 'Basket': return Colors.orange;
      case 'Badminton': return Colors.blue;
      case 'Voli': return Colors.teal;
      default: return _primaryColor;
    }
  }

  IconData get _categoryIcon {
    switch (widget.venue.category) {
      case 'Futsal': return Icons.sports_soccer;
      case 'Basket': return Icons.sports_basketball;
      case 'Badminton': return Icons.sports_tennis;
      case 'Voli': return Icons.sports_volleyball;
      default: return Icons.sports;
    }
  }

  String _formatHarga(int harga) {
    final str = harga.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return 'Rp $buffer';
  }

  double get _averageRating {
    if (_reviews.isEmpty) return 0;
    final total = _reviews.fold(0.0, (sum, r) => sum + (r['rating'] as double));
    return total / _reviews.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(),
                const SizedBox(height: 12),
                _buildCourtsSection(),
                const SizedBox(height: 12),
                _buildReviewsSection(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ── Sliver App Bar ──
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          onPressed: () => setState(() => _isFavorite = !_isFavorite),
          icon: Icon(
            _isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _isFavorite ? Colors.red.shade300 : Colors.white,
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_categoryColor, _primaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 48),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(_categoryIcon, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 10),
              Text(
                widget.venue.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.venue.category,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Info Card ──
  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          // Rating besar
          Column(
            children: [
              Text(
                _averageRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < _averageRating.floor()
                        ? Icons.star
                        : i < _averageRating
                            ? Icons.star_half
                            : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  );
                }),
              ),
              const SizedBox(height: 4),
              Text(
                '${_reviews.length} ulasan',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Container(width: 1, height: 70, color: Colors.grey.shade200),
          const SizedBox(width: 16),
          // Info venue
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow(Icons.location_on_outlined, widget.venue.location),
                const SizedBox(height: 6),
                _infoRow(
                  Icons.crop_square_rounded,
                  '${widget.venue.courts.length} Lapangan tersedia',
                ),
                const SizedBox(height: 6),
                _infoRow(
                  Icons.payments_outlined,
                  widget.venue.getPriceLabel(DateTime.now()),
                  valueColor: _primaryColor,
                  bold: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text,
      {Color? valueColor, bool bold = false}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: valueColor ?? Colors.grey.shade700,
              fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ── Daftar Lapangan ──
  Widget _buildCourtsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.crop_square_rounded, 'Daftar Lapangan'),
          const SizedBox(height: 12),
          ...widget.venue.courts.asMap().entries.map((entry) {
            final index = entry.key;
            final court = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _primaryColor.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  // Nomor
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: _primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Nama court
                  Expanded(
                    child: Text(
                      court.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                  // Badge aktif
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Text(
                      'Aktif',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Review & Rating ──
  Widget _buildReviewsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.rate_review_outlined, 'Ulasan Pengguna'),
          const SizedBox(height: 12),
          ..._reviews.map((review) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header review
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: _primaryColor.withOpacity(0.15),
                        child: Text(
                          review['name'][0],
                          style: const TextStyle(
                            color: _primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              review['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                            Text(
                              review['date'],
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Bintang rating
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star,
                                color: Colors.amber, size: 13),
                            const SizedBox(width: 3),
                            Text(
                              '${review['rating']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Komentar
                  Text(
                    review['comment'],
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Bottom Bar ──
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mulai dari',
                  style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 11)),
              Text(
                _formatHarga(widget.venue.pricePerHour),
                style: const TextStyle(
                  color: _primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BookingScreen(venue: widget.venue),
                ),
              ),
              icon: const Icon(Icons.calendar_month, size: 18),
              label: const Text('Pesan Sekarang'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──
  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: _primaryColor, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }
}