import 'package:flutter/material.dart';
import '../models/venue.dart';
import '../services/slot_service.dart';
import 'payment_screen.dart';
import 'package:intl/intl.dart';

enum SlotStatus { available, booked, selected }

class BookingScreen extends StatefulWidget {
  final Venue venue;
  const BookingScreen({super.key, required this.venue});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  static const Color _primaryColor = Color(0xFF5E5CE6);

  // Step 1: Pilih Court
  Court? _selectedCourt;

  // Step 2: Pilih Tanggal
  DateTime _selectedDate = DateTime.now();

  // Step 3: Pilih Jam
  int? _selectedHour;
  int _selectedDuration = 1; // durasi dalam jam (1, 2, 3)

  bool _showMessage = false;
  bool _isAvailable = false;
  String _availabilityMessage = '';
  bool _isLoadingSlots = false;
  SlotAvailability _slotAvailability = const SlotAvailability(
    bookedHours: {},
    blockedHours: {},
  );

  static const int _openHour = 7;
  static const int _closeHour = 21;

  // ── Load slot real-time dari Firestore saat court/tanggal berubah ──
  Future<void> _loadSlots() async {
    if (_selectedCourt == null) return;
    setState(() => _isLoadingSlots = true);

    final dateStr =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

    final availability = await SlotService.getUnavailableSlots(
      venueId: widget.venue.id, // FIX: tambah venueId agar tidak bentrok antar venue
      courtId: _selectedCourt!.id,
      date: dateStr,
    );

    if (mounted) {
      setState(() {
        _slotAvailability = availability;
        _isLoadingSlots = false;
        // Reset pilihan jam kalau slot yang dipilih sudah terpakai
        if (_selectedHour != null &&
            _slotAvailability.isUnavailable(_selectedHour!)) {
          _selectedHour = null;
          _showMessage = false;
        }
      });
    }
  }

  // ── Cek slot: gabungan booking user + blok admin ──
  bool _isBooked(int hour) => _slotAvailability.bookedHours.contains(hour);
  bool _isBlockedByAdmin(int hour) => _slotAvailability.blockedHours.contains(hour);

  // ── Hitung court tersedia di jam tertentu ──
  int _availableCourtsAt(int hour) {
    return widget.venue.availableCourtsCount(_selectedDate, hour);
  }

  void _onSelectCourt(Court court) {
    // Cek apakah lapangan ditutup total oleh admin
    if (!court.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.block, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('${court.name} sedang ditutup oleh admin'),
          ]),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() {
      _selectedCourt = court;
      _selectedHour = null;
      _selectedDuration = 1;
      _showMessage = false;
    });
    // FIX: load slot real-time dari Firestore setelah pilih lapangan
    _loadSlots();
  }

  void _onSelectHour(int hour) {
    if (_selectedCourt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih lapangan terlebih dahulu'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() {
      _selectedHour = hour;
      _showMessage = true;

      // Cek semua slot untuk durasi yang dipilih
      // Contoh: pilih jam 08:00 durasi 2 jam → cek 08:00 dan 09:00
      final slotsToCheck = List.generate(
          _selectedDuration, (i) => hour + i);

      final blockedSlot = slotsToCheck.firstWhere(
          (h) => _isBlockedByAdmin(h), orElse: () => -1);
      final bookedSlot = slotsToCheck.firstWhere(
          (h) => _isBooked(h), orElse: () => -1);

      if (blockedSlot != -1) {
        _isAvailable = false;
        _availabilityMessage =
            '🚫 Slot jam ${blockedSlot.toString().padLeft(2, '0')}:00 ditutup oleh admin.\nKurangi durasi atau pilih jam lain.';
      } else if (bookedSlot != -1) {
        _isAvailable = false;
        _availabilityMessage =
            '⚠️ Slot jam ${bookedSlot.toString().padLeft(2, '0')}:00 sudah dipesan.\nKurangi durasi atau pilih jam lain.';
      } else if (hour + _selectedDuration - 1 > _closeHour) {
        _isAvailable = false;
        _availabilityMessage =
            '⚠️ Durasi melebihi jam tutup ($_closeHour:00).\nKurangi durasi atau pilih jam lebih awal.';
      } else {
        _isAvailable = true;
        final endHour = hour + _selectedDuration;
        _availabilityMessage =
            '✅ ${_selectedCourt!.name} tersedia!\n'
            'Jam ${hour.toString().padLeft(2, '0')}:00 – '
            '${endHour.toString().padLeft(2, '0')}:00 ($_selectedDuration jam) bisa dipesan.';
      }
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _primaryColor,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedHour = null;
        _showMessage = false;
      });
      // FIX: reload slot saat tanggal berubah
      _loadSlots();
    }
  }

  void _lanjutKonfirmasi() {
    if (_selectedCourt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih lapangan terlebih dahulu'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_selectedHour == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih jam terlebih dahulu'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!_isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jam yang dipilih tidak tersedia. Pilih jam lain.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    // Navigasi ke Payment Screen dengan durasi
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          venue: widget.venue,
          court: _selectedCourt!,
          date: _selectedDate,
          hour: _selectedHour!,
          duration: _selectedDuration,
        ),
      ),
    );
  }

  // ── Harga dinamis berdasarkan hari yang dipilih ──
  int get _currentPrice => widget.venue.getPriceForDate(_selectedDate);

  // Format tanggal manual tanpa intl
  String _formatDate(DateTime d) {
    const hari = [
      'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
    ];
    const bulan = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${hari[d.weekday - 1]}, ${d.day} ${bulan[d.month]} ${d.year}';
  }

  // Format harga manual tanpa intl
  String _formatHarga(int harga) {
    final str = harga.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return 'Rp $buffer';
  }

  void showConfirmationSheet() {
    final hour = _selectedHour!;
    final dateStr = _formatDate(_selectedDate);
    final jamStr =
        '${hour.toString().padLeft(2, '0')}:00 – ${(hour + 1).toString().padLeft(2, '0')}:00';
    // FIX: gunakan harga dinamis weekday/weekend
    final harga = _formatHarga(_currentPrice);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
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
            const SizedBox(height: 20),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline,
                  color: _primaryColor, size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'Konfirmasi Pemesanan',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 20),
            _confirmRow('Venue', widget.venue.name),
            _confirmRow('Lapangan', _selectedCourt!.name),
            _confirmRow('Kategori', widget.venue.category),
            _confirmRow('Tanggal', dateStr),
            _confirmRow('Jam', jamStr),
            _confirmRow('Harga', harga),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showSuccessDialog();
                },
                child: const Text('Konfirmasi & Bayar'),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal',
                  style: TextStyle(color: Colors.grey)),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _confirmRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF1A1A2E))),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  color: Colors.green, size: 48),
            ),
            const SizedBox(height: 16),
            const Text('Pemesanan Berhasil!',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 8),
            Text(
              '${_selectedCourt!.name} di ${widget.venue.name}\nberhasil dipesan.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Selesai'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Reservasi Lapangan',
            style:
                TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVenueInfoCard(),
            const SizedBox(height: 20),

            // STEP 1: Pilih Lapangan (Court)
            _buildStepTitle('1', 'Pilih Lapangan'),
            const SizedBox(height: 10),
            _buildCourtSelector(),
            const SizedBox(height: 20),

            // STEP 2: Pilih Tanggal
            _buildStepTitle('2', 'Pilih Tanggal'),
            const SizedBox(height: 10),
            // ── Pilihan Durasi ──
            _buildDurationPicker(),
            const SizedBox(height: 16),
            _buildDatePicker(),
            const SizedBox(height: 20),

            // STEP 3: Pilih Jam
            _buildStepTitle('3', 'Pilih Jam'),
            const SizedBox(height: 4),
            Text(
              _selectedCourt == null
                  ? 'Pilih lapangan dulu untuk melihat ketersediaan jam'
                  : 'Ketersediaan jam untuk ${_selectedCourt!.name}',
              style:
                  TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
            const SizedBox(height: 10),
            _buildTimePicker(),
            const SizedBox(height: 10),
            _buildLegend(),
            const SizedBox(height: 16),

            // Pesan ketersediaan (output flowchart)
            if (_showMessage) _buildAvailabilityMessage(),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _lanjutKonfirmasi,
                child: const Text('Lanjut ke Konfirmasi'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Venue Info Card ──
  Widget _buildVenueInfoCard() {
    final categoryColors = {
      'Futsal': Colors.green,
      'Basket': Colors.orange,
      'Badminton': Colors.blue,
      'Voli': Colors.teal,
    };
    final categoryIcons = {
      'Futsal': Icons.sports_soccer,
      'Basket': Icons.sports_basketball,
      'Badminton': Icons.sports_tennis,
      'Voli': Icons.sports_volleyball,
    };
    final color = categoryColors[widget.venue.category] ?? _primaryColor;
    final icon =
        categoryIcons[widget.venue.category] ?? Icons.sports;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.venue.name,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E))),
                const SizedBox(height: 3),
                Row(children: [
                  const Icon(Icons.star, color: Colors.amber, size: 13),
                  const SizedBox(width: 3),
                  Text(
                      '${widget.venue.rating}  •  ${widget.venue.category}  •  ${widget.venue.courts.length} Lapangan',
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 12)),
                ]),
                const SizedBox(height: 3),
                Text(
                  'Rp ${NumberFormat('#,###').format(widget.venue.pricePerHour)} / jam',
                  style: const TextStyle(
                      color: _primaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepTitle(String step, String title) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
              color: _primaryColor, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(step,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E))),
      ],
    );
  }

  // ── Court Selector ──
  Widget _buildCourtSelector() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: widget.venue.courts.map((court) {
        final isSelected = _selectedCourt?.id == court.id;
        // Hitung sisa slot penuh di tanggal ini (info)
        final bookedCount = court.bookedSlots
            .where((s) => s.startsWith(
                '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}'))
            .length;

        return GestureDetector(
          onTap: () => _onSelectCourt(court),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? _primaryColor : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isSelected ? _primaryColor : Colors.grey.shade200,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                    color: isSelected
                        ? _primaryColor.withValues(alpha: 0.25)
                        : Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.crop_square_rounded,
                  color:
                      isSelected ? Colors.white : _primaryColor,
                  size: 28,
                ),
                const SizedBox(height: 4),
                Text(
                  court.name,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF1A1A2E)),
                ),
                const SizedBox(height: 2),
                Text(
                  '$bookedCount slot booked',
                  style: TextStyle(
                      fontSize: 10,
                      color: isSelected
                          ? Colors.white70
                          : Colors.grey.shade500),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Duration Picker ──
  Widget _buildDurationPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.timelapse, color: _primaryColor, size: 18),
            const SizedBox(width: 8),
            const Text(
              'Durasi',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$_selectedDuration jam',
              style: const TextStyle(
                color: _primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [1, 2, 3].map((d) {
            final isSelected = _selectedDuration == d;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDuration = d;
                    // Reset jam kalau durasi berubah — perlu cek ulang ketersediaan
                    if (_selectedHour != null) {
                      _onSelectHour(_selectedHour!);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? _primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? _primaryColor
                          : Colors.grey.shade200,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? _primaryColor.withValues(alpha: 0.25)
                            : Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$d Jam',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF1A1A2E),
                        ),
                      ),
                      Text(
                        _formatHarga(_currentPrice * d),
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected
                              ? Colors.white70
                              : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Date Picker ──
  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: _primaryColor.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today,
                color: _primaryColor, size: 20),
            const SizedBox(width: 12),
            Text(
              DateFormat('EEE, dd MMM yyyy')
                  .format(_selectedDate),
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E)),
            ),
            const Spacer(),
            const Icon(Icons.edit_calendar_outlined,
                color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }

  // ── Time Picker Grid ──
  Widget _buildTimePicker() {
    // FIX: tampilkan loading saat fetch slot dari Firestore
    if (_isLoadingSlots) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(height: 8),
            Text('Mengecek ketersediaan slot...',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.6,
      ),
      itemCount: _closeHour - _openHour,
      itemBuilder: (_, i) {
        final hour = _openHour + i;
        final booked = _isBooked(hour);
        final blockedByAdmin = _isBlockedByAdmin(hour);
        final selected = _selectedHour == hour;
        final allBooked = widget.venue.isAllCourtsBooked(
            _selectedDate, hour);
        final availCount = _availableCourtsAt(hour);

        Color bgColor;
        Color textColor;
        Color borderColor;

        if (selected && booked) {
          bgColor = Colors.red.shade50;
          textColor = Colors.red;
          borderColor = Colors.red;
        } else if (selected) {
          bgColor = _primaryColor;
          textColor = Colors.white;
          borderColor = _primaryColor;
        } else if (blockedByAdmin) {
          // FIX: slot diblok admin — tampil merah gelap
          bgColor = Colors.red.shade50;
          textColor = Colors.red.shade300;
          borderColor = Colors.red.shade200;
        } else if (allBooked) {
          bgColor = Colors.grey.shade100;
          textColor = Colors.grey.shade400;
          borderColor = Colors.grey.shade200;
        } else if (booked && _selectedCourt != null) {
          bgColor = Colors.orange.shade50;
          textColor = Colors.orange.shade700;
          borderColor = Colors.orange.shade200;
        } else {
          bgColor = Colors.white;
          textColor = const Color(0xFF1A1A2E);
          borderColor = Colors.grey.shade200;
        }

        return GestureDetector(
          onTap: () => _onSelectHour(hour),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
              boxShadow: selected
                  ? [
                      BoxShadow(
                          color: _primaryColor.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2))
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${hour.toString().padLeft(2, '0')}:00',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: textColor),
                ),
                if (_selectedCourt == null && !allBooked)
                  Text(
                    '$availCount tersedia',
                    style: TextStyle(
                        fontSize: 8,
                        color: Colors.grey.shade400),
                  )
                else if (allBooked)
                  Text('Penuh',
                      style: TextStyle(
                          fontSize: 8,
                          color: Colors.grey.shade400))
                else if (blockedByAdmin)
                  Text('Ditutup',
                      style: TextStyle(
                          fontSize: 8,
                          color: Colors.red.shade300))
                else if (booked && _selectedCourt != null)
                  Text('Dipakai',
                      style: TextStyle(
                          fontSize: 8,
                          color: Colors.orange.shade600))
                else
                  Text('Bebas',
                      style: TextStyle(
                          fontSize: 8,
                          color: Colors.green.shade400)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        _legendItem(Colors.white, Colors.grey.shade200, 'Tersedia'),
        _legendItem(_primaryColor, _primaryColor, 'Dipilih'),
        _legendItem(
            Colors.orange.shade50, Colors.orange.shade200, 'Lap. ini penuh'),
        _legendItem(
            Colors.grey.shade100, Colors.grey.shade200, 'Semua penuh'),
        _legendItem(
            Colors.red.shade50, Colors.red.shade200, 'Ditutup admin'),
      ],
    );
  }

  Widget _legendItem(Color fill, Color border, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: fill,
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 10, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildAvailabilityMessage() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            _isAvailable ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: _isAvailable
                ? Colors.green.shade200
                : Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(
            _isAvailable ? Icons.check_circle : Icons.cancel,
            color: _isAvailable ? Colors.green : Colors.red,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _availabilityMessage,
              style: TextStyle(
                color: _isAvailable
                    ? Colors.green.shade800
                    : Colors.red.shade800,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}