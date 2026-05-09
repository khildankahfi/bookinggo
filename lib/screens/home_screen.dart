import 'package:flutter/material.dart';
import '../models/venue.dart';
import '../widgets/venue_card.dart';
import '../services/venue_service.dart';
import '../services/auth_service.dart';
import 'booking_screen.dart';
import 'login_screen.dart';
import 'venue_detail_screen.dart';
import 'riwayat_screen.dart';
import 'edit_profil_screen.dart';
import 'favorit_screen.dart';
import 'notifikasi_screen.dart';
import 'bantuan_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userName;

  const HomeScreen({super.key, this.userName = 'Pengguna'});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  List<Venue> _venues = [];
  bool _isLoading = true;

  // FIX: simpan nama sebagai state agar bisa diupdate setelah edit profil
  String _userName  = 'Pengguna'; // nilai default dulu
  String _userEmail = '';

  static const Color _primaryColor = Color(0xFF5E5CE6);

  @override
  void initState() {
    super.initState();
    // Gunakan widget.userName sebagai nilai awal
    if (widget.userName.isNotEmpty) _userName = widget.userName;
    _userEmail = '';
    _loadVenues();
    _loadUserData(); // load data terbaru dari Firebase
  }

  // Load data user terbaru dari Firebase Auth
  Future<void> _loadUserData() async {
    final user = await AuthService.getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        _userName  = user['name'] ?? _userName;
        _userEmail = user['email'] ?? '';
      });
    }
  }

  Future<void> _loadVenues() async {
    setState(() => _isLoading = true);

    // FIX SPEED: tampilkan sample data DULU agar tidak spinner lama
    // VenueService sudah handle timeout 3 detik dan fallback ke sample
    // Jadi ini sudah cukup cepat — tidak perlu dua-tahap
    final venues = await VenueService.getVenues(
      category: _selectedCategory == 'Semua' ? null : _selectedCategory,
      search: _searchQuery.isEmpty ? null : _searchQuery,
    );

    if (!mounted) return;
    setState(() {
      _venues = venues;
      _isLoading = false;
    });
  }
  final List<Map<String, dynamic>> _categories = [
    {'label': 'Futsal', 'icon': Icons.sports_soccer, 'color': Colors.green},
    {
      'label': 'Badminton',
      'icon': Icons.sports_tennis,
      'color': Colors.blue
    },
    {
      'label': 'Basket',
      'icon': Icons.sports_basketball,
      'color': Colors.orange
    },
    {
      'label': 'Voli',
      'icon': Icons.sports_volleyball,
      'color': Colors.teal
    },
  ];

  List<Venue> get _filteredVenues {
    return _venues.where((v) {
      final matchSearch =
          v.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              v.category.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchCategory =
          _selectedCategory == 'Semua' || v.category == _selectedCategory;
      return matchSearch && matchCategory;
    }).toList();
  }

  void _navigateToBooking(Venue venue) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingScreen(venue: venue),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          _buildExploreTab(),
          _buildProfilTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ════════════════════════════════════════════
  //  HOME TAB
  // ════════════════════════════════════════════
  Widget _buildHomeTab() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader()),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildSearchBar(),
                const SizedBox(height: 24),
                _buildCategorySection(),
                const SizedBox(height: 24),
                _buildPopularSection(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Custom Clipper Header ──
  Widget _buildHeader() {
    return ClipPath(
      clipper: _HeaderClipper(),
      child: Container(
        height: 180,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF5E5CE6), Color(0xFF8B89F0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Halo, $_userName ',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text('👋', style: TextStyle(fontSize: 22)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Mau reservasi apa hari ini?',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white24,
                  child: Text(
                    _userName.isNotEmpty
                        ? _userName[0].toUpperCase()
                        : 'P',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Search Bar ──
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: 'Cari lapangan...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon:
              Icon(Icons.search, color: Colors.grey.shade400, size: 22),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // ── Category Section ──
  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'KATEGORI',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: Color(0xFF888888),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: GridView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              mainAxisSpacing: 12,
              crossAxisSpacing: 0,
              childAspectRatio: 0.85,
            ),
            itemCount: _categories.length,
            itemBuilder: (_, i) {
              final cat = _categories[i];
              final isSelected = _selectedCategory == cat['label'];
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedCategory =
                      isSelected ? 'Semua' : cat['label'] as String;
                }),
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _primaryColor
                        : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        cat['icon'] as IconData,
                        color: isSelected
                            ? Colors.white
                            : cat['color'] as Color,
                        size: 28,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        cat['label'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color:
                              isSelected ? Colors.white : const Color(0xFF1A1A2E),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Popular Section ──
  Widget _buildPopularSection() {
    final venues = _filteredVenues;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'TEMPAT POPULER',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: Color(0xFF888888),
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _currentIndex = 1),
              child: const Text(
                'Lihat Semua',
                style: TextStyle(
                  color: _primaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (venues.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.search_off, color: Colors.grey.shade300, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    'Lapangan tidak ditemukan',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          )
        else
          ...venues.map((v) => GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VenueDetailScreen(venue: v),
                  ),
                ),
                child: VenueCard(
                  venue: v,
                  onPesan: () => _navigateToBooking(v),
                ),
              )),
      ],
    );
  }

  // ════════════════════════════════════════════
  //  EXPLORE TAB
  // ════════════════════════════════════════════
  Widget _buildExploreTab() {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Explore Lapangan',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 12),
                _buildSearchBar(),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _venues.length,
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VenueDetailScreen(venue: _venues[i]),
                  ),
                ),
                child: VenueCard(
                  venue: _venues[i],
                  onPesan: () => _navigateToBooking(_venues[i]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════
  //  PROFIL TAB
  // ════════════════════════════════════════════
  Widget _buildProfilTab() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 48,
              backgroundColor: _primaryColor.withValues(alpha: 0.15),
              child: Text(
                _userName.isNotEmpty
                    ? _userName[0].toUpperCase()
                    : 'P',
                style: const TextStyle(
                  color: _primaryColor,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _userName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Anggota Aktif',
              style: TextStyle(color: Colors.grey.shade500),
            ),
            const SizedBox(height: 12),
            // Tombol Edit Profil
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final updatedName = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProfilScreen(
                        userName: _userName,
                        userEmail: _userEmail,
                      ),
                    ),
                  );
                  // FIX: update nama di state agar langsung berubah di UI
                  if (updatedName != null && mounted) {
                    setState(() => _userName = updatedName);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profil berhasil diperbarui!'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit Profil'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primaryColor,
                  side: const BorderSide(color: _primaryColor),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildProfileMenu(Icons.history, 'Riwayat Reservasi', onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const RiwayatScreen()));
            }),
            _buildProfileMenu(Icons.favorite_outline, 'Favorit', onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const FavoritScreen()));
            }),
            _buildProfileMenu(Icons.notifications_outlined, 'Notifikasi', onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const NotifikasiScreen()));
            }),
            _buildProfileMenu(Icons.help_outline, 'Bantuan', onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const BantuanScreen()));
            }),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      title: const Text('Keluar',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      content:
                          const Text('Apakah kamu yakin ingin keluar?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Batal',
                              style: TextStyle(color: Colors.grey)),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            await AuthService.logout(); // FIX: logout Firebase dulu
                            if (!mounted) return;
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LoginScreen()),
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent),
                          child: const Text('Keluar'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: const Text(
                  'Keluar',
                  style: TextStyle(color: Colors.redAccent),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileMenu(IconData icon, String label, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: _primaryColor),
        title: Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        trailing:
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        onTap: onTap ?? () => _showComingSoon(label),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showComingSoon(String fitur) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.construction_rounded,
                  color: _primaryColor, size: 34),
            ),
            const SizedBox(height: 16),
            Text(
              fitur,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fitur ini sedang dalam pengembangan.\nSegera hadir!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Oke, Mengerti'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════
  //  BOTTOM NAV BAR
  // ════════════════════════════════════════════
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: _primaryColor,
        unselectedItemColor: Colors.grey.shade400,
        backgroundColor: Colors.white,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════
//  CUSTOM CLIPPER
// ════════════════════════════════════════════
class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 20,
      size.width,
      size.height - 40,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_HeaderClipper oldClipper) => false;
}