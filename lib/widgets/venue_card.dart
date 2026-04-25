import 'package:flutter/material.dart';
import '../models/venue.dart';

class VenueCard extends StatelessWidget {
  final Venue venue;
  final VoidCallback onPesan;

  const VenueCard({
    super.key,
    required this.venue,
    required this.onPesan,
  });

  static const Color _primaryColor = Color(0xFF5E5CE6);

  Color get _categoryColor {
    switch (venue.category) {
      case 'Futsal':
        return Colors.green;
      case 'Basket':
        return Colors.orange;
      case 'Badminton':
        return Colors.blue;
      case 'Voli':
        return Colors.teal;
      default:
        return _primaryColor;
    }
  }

  IconData get _categoryIcon {
    switch (venue.category) {
      case 'Futsal':
        return Icons.sports_soccer;
      case 'Basket':
        return Icons.sports_basketball;
      case 'Badminton':
        return Icons.sports_tennis;
      case 'Voli':
        return Icons.sports_volleyball;
      default:
        return Icons.sports;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // ── Venue Icon / Image ──
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _categoryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _categoryIcon,
                color: _categoryColor,
                size: 32,
              ),
            ),
            const SizedBox(width: 14),

            // ── Venue Info ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    venue.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 3),
                      Text(
                        venue.rating.toString(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    venue.category,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),

            // ── Pesan Button ──
            ElevatedButton(
              onPressed: onPesan,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(72, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              ),
              child: const Text('Pesan'),
            ),
          ],
        ),
      ),
    );
  }
}