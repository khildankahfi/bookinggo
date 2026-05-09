import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey                  = GlobalKey<FormState>();
  final _nameController           = TextEditingController();
  final _emailController          = TextEditingController();
  final _phoneController          = TextEditingController();
  final _passwordController       = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword        = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading              = false;
  bool _agreeTerms             = false;

  static const Color _primaryColor = Color(0xFF5E5CE6);

  // Domain email yang diterima — harus email aktif
  static const List<String> _validDomains = [
    'gmail.com', 'yahoo.com', 'yahoo.co.id',
    'outlook.com', 'hotmail.com', 'live.com',
    'icloud.com', 'me.com',
    'student.ac.id', 'ac.id', 'sch.id',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ── Validasi email (opsional) ──
  // Kalau diisi → harus dari domain resmi (Gmail, Yahoo, dll)
  // Fungsi: untuk reset password kalau lupa
  String? _validateEmail(String? val) {
    if (val == null || val.trim().isEmpty) return null; // opsional

    final email = val.trim().toLowerCase();
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) return 'Format email tidak valid';

    final domain = email.split('@').last;
    final isValidDomain = _validDomains.any((d) =>
        domain == d || domain.endsWith('.$d'));
    if (!isValidDomain) {
      return 'Gunakan email aktif (Gmail, Yahoo, Outlook, iCloud, dll)';
    }
    return null;
  }

  // ── Validasi nomor WA (opsional) ──
  // Kalau diisi → harus format nomor HP Indonesia
  // Fungsi: admin WA user untuk info booking
  String? _validatePhone(String? val) {
    if (val == null || val.trim().isEmpty) return null; // opsional

    final phone = val.trim().replaceAll(RegExp(r'\s|-'), '');
    if (!phone.startsWith('08') && !phone.startsWith('+62') &&
        !phone.startsWith('628')) {
      return 'Nomor harus diawali 08 atau +62';
    }

    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10 || digits.length > 15) {
      return 'Nomor WA tidak valid (10-15 digit)';
    }
    return null;
  }

  // ── Format nomor ke format WA internasional ──
  String _formatPhoneWA(String phone) {
    phone = phone.trim().replaceAll(RegExp(r'\s|-'), '');
    if (phone.startsWith('08')) {
      return '62${phone.substring(1)}';
    } else if (phone.startsWith('+62')) {
      return phone.substring(1);
    }
    return phone;
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Setujui syarat & ketentuan terlebih dahulu'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final phoneWA = _formatPhoneWA(_phoneController.text);

    final result = await AuthService.register(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
      phone: phoneWA, // kirim nomor WA yang sudah diformat
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Registrasi berhasil! Silakan login.'),
          ]),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Registrasi gagal'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _infoRow(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                horizontal: 32, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),

                  // Logo
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: _primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.sports_soccer,
                        color: _primaryColor, size: 36),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'DAFTAR AKUN',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Buat akun untuk mulai booking lapangan',
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 28),

                  // ── Nama ──
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'Nama Lengkap',
                      prefixIcon: Icon(Icons.person_outline,
                          color: Colors.grey, size: 20),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Nama wajib diisi';
                      }
                      if (val.trim().length < 2) {
                        return 'Nama minimal 2 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // ── Email ──
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'Email aktif (untuk lupa password)',
                      prefixIcon: Icon(Icons.email_outlined,
                          color: Colors.grey, size: 20),
                    ),
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 6),
                  _infoRow(
                    Icons.lock_reset,
                    'Opsional — digunakan untuk reset password jika lupa',
                    Colors.blue.shade400,
                  ),
                  const SizedBox(height: 14),

                  // ── Nomor WhatsApp ──
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9+\-\s]')),
                    ],
                    decoration: const InputDecoration(
                      hintText: 'Nomor WhatsApp (untuk konfirmasi booking)',
                      prefixIcon: Icon(Icons.phone_outlined,
                          color: Colors.grey, size: 20),
                    ),
                    validator: _validatePhone,
                  ),
                  const SizedBox(height: 6),
                  _infoRow(
                    Icons.notifications_active_outlined,
                    'Opsional — admin akan WA kamu untuk konfirmasi booking',
                    Colors.green.shade400,
                  ),
                  const SizedBox(height: 14),

                  // ── Password ──
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Password (min. 6 karakter)',
                      prefixIcon: const Icon(Icons.lock_outline,
                          color: Colors.grey, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey, size: 20,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Password wajib diisi';
                      }
                      if (val.length < 6) {
                        return 'Password minimal 6 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // ── Konfirmasi Password ──
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      hintText: 'Konfirmasi Password',
                      prefixIcon: const Icon(Icons.lock_outline,
                          color: Colors.grey, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey, size: 20,
                        ),
                        onPressed: () => setState(() =>
                            _obscureConfirmPassword =
                                !_obscureConfirmPassword),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Konfirmasi password wajib diisi';
                      }
                      if (val != _passwordController.text) {
                        return 'Password tidak sama';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── Syarat & Ketentuan ──
                  GestureDetector(
                    onTap: () =>
                        setState(() => _agreeTerms = !_agreeTerms),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24, height: 24,
                          child: Checkbox(
                            value: _agreeTerms,
                            onChanged: (val) =>
                                setState(() => _agreeTerms = val!),
                            activeColor: _primaryColor,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              text: 'Saya menyetujui ',
                              style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12),
                              children: const [
                                TextSpan(
                                  text: 'Syarat & Ketentuan',
                                  style: TextStyle(
                                    color: _primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(
                                    text:
                                        ' dan data saya digunakan untuk keperluan booking.'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Tombol Daftar ──
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      child: _isLoading
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text('Daftar Sekarang',
                              style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Link Login ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Sudah punya akun? ',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            color: _primaryColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}