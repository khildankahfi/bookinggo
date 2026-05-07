import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart'; // FIX: tambah import AuthService

class EditProfilScreen extends StatefulWidget {
  final String userName;
  final String userEmail;

  const EditProfilScreen({
    super.key,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<EditProfilScreen> createState() => _EditProfilScreenState();
}

class _EditProfilScreenState extends State<EditProfilScreen> {
  static const Color _primaryColor = Color(0xFF5E5CE6);

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _oldPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _changePassword = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userName);
    _emailController = TextEditingController(text: widget.userEmail);
    _phoneController = TextEditingController(text: '');
    _oldPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    // Load nomor HP dari Firestore
    _loadPhoneFromFirestore();
  }

  // Ambil nomor HP dari Firestore
  Future<void> _loadPhoneFromFirestore() async {
    try {
      final uid = AuthService.getCurrentUid();
      if (uid == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists && mounted) {
        final phone = doc.data()?['phone'] as String? ?? '';
        if (phone.isNotEmpty) {
          setState(() => _phoneController.text = phone);
        }
      }
    } catch (e) {
      // Gagal load - biarkan kosong
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // FIX BUG 5: Benar-benar memanggil AuthService.updateProfile()
  // sebelumnya hanya Future.delayed() simulasi — data tidak tersimpan ke Firebase
  Future<void> _simpanPerubahan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await AuthService.updateProfile(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      // Hanya kirim password jika user aktifkan toggle ubah password
      oldPassword: _changePassword ? _oldPasswordController.text : null,
      newPassword: _changePassword ? _newPasswordController.text : null,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Profil berhasil diperbarui!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Kembalikan nama terbaru ke HomeScreen
      Navigator.pop(context, _nameController.text.trim());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gagal memperbarui profil'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Edit Profil',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildPhotoHeader(),
              const SizedBox(height: 16),

              _buildSection(
                title: 'Informasi Pribadi',
                icon: Icons.person_outline,
                child: Column(
                  children: [
                    _buildField(
                      controller: _nameController,
                      label: 'Nama Lengkap',
                      icon: Icons.person_outline,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Nama wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Email wajib diisi';
                        if (!val.contains('@')) return 'Format email tidak valid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      controller: _phoneController,
                      label: 'Nomor HP',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      hint: 'Contoh: 08123456789',
                      validator: (val) {
                        if (val != null && val.isNotEmpty && val.length < 10) {
                          return 'Nomor HP tidak valid';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              _buildSection(
                title: 'Ubah Password',
                icon: Icons.lock_outline,
                trailing: Switch(
                  value: _changePassword,
                  activeColor: _primaryColor,
                  onChanged: (val) {
                    setState(() {
                      _changePassword = val;
                      if (!val) {
                        _oldPasswordController.clear();
                        _newPasswordController.clear();
                        _confirmPasswordController.clear();
                      }
                    });
                  },
                ),
                child: _changePassword
                    ? Column(
                        children: [
                          const SizedBox(height: 4),
                          _buildPasswordField(
                            controller: _oldPasswordController,
                            label: 'Password Lama',
                            obscure: _obscureOld,
                            onToggle: () =>
                                setState(() => _obscureOld = !_obscureOld),
                            validator: (val) {
                              if (_changePassword &&
                                  (val == null || val.isEmpty)) {
                                return 'Password lama wajib diisi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          _buildPasswordField(
                            controller: _newPasswordController,
                            label: 'Password Baru',
                            obscure: _obscureNew,
                            onToggle: () =>
                                setState(() => _obscureNew = !_obscureNew),
                            validator: (val) {
                              if (_changePassword) {
                                if (val == null || val.isEmpty) {
                                  return 'Password baru wajib diisi';
                                }
                                if (val.length < 6) {
                                  return 'Password minimal 6 karakter';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          _buildPasswordField(
                            controller: _confirmPasswordController,
                            label: 'Konfirmasi Password Baru',
                            obscure: _obscureConfirm,
                            onToggle: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                            validator: (val) {
                              if (_changePassword &&
                                  val != _newPasswordController.text) {
                                return 'Password tidak sama';
                              }
                              return null;
                            },
                          ),
                        ],
                      )
                    : Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Aktifkan untuk mengubah password',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 13),
                        ),
                      ),
              ),
              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _simpanPerubahan,
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text('Simpan Perubahan',
                            style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoHeader() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 52,
                backgroundColor: _primaryColor.withOpacity(0.15),
                child: Text(
                  _nameController.text.isNotEmpty
                      ? _nameController.text[0].toUpperCase()
                      : 'P',
                  style: const TextStyle(
                    color: _primaryColor,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fitur upload foto akan segera hadir'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _nameController.text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _emailController.text,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              if (trailing != null) ...[
                const Spacer(),
                trailing,
              ],
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey, size: 20),
        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        floatingLabelStyle: const TextStyle(color: _primaryColor, fontSize: 13),
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon:
            const Icon(Icons.lock_outline, color: Colors.grey, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.grey,
            size: 20,
          ),
          onPressed: onToggle,
        ),
        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        floatingLabelStyle: const TextStyle(color: _primaryColor, fontSize: 13),
      ),
      validator: validator,
    );
  }
}