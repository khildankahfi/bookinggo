import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Login ──
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user!;

      // FIX SPEED: pakai displayName langsung dari Firebase Auth
      // Tidak perlu Firestore call — displayName sudah di-set saat register
      // Hemat ~1-2 detik round-trip ke Firestore
      final name = user.displayName ?? 'Pengguna';

      return {
        'success': true,
        'user': {'uid': user.uid, 'email': user.email, 'name': name},
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _authErrorMessage(e.code)};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // ── Register ──
  static Future<Map<String, dynamic>> register(
      String name, String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user!;

      // Set displayName dulu agar login berikutnya tidak perlu hit Firestore
      await user.updateDisplayName(name);

      // Simpan ke Firestore untuk data tambahan (phone, dll) — fire and forget
      _db.collection('users').doc(user.uid).set({
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'user': {'uid': user.uid, 'email': email, 'name': name},
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _authErrorMessage(e.code)};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // ── Logout ──
  static Future<void> logout() async {
    await _auth.signOut();
  }

  // ── Update Profil ──
  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    String? phone,
    String? oldPassword,
    String? newPassword,
  }) async {
    try {
      final user = _auth.currentUser!;

      // Update Firestore dan Firebase Auth secara paralel — lebih cepat
      await Future.wait([
        _db.collection('users').doc(user.uid).update({
          'name': name,
          'email': email,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
        }),
        user.updateDisplayName(name),
      ]);

      // Update password hanya jika diminta
      if (oldPassword != null && newPassword != null) {
        final cred = EmailAuthProvider.credential(
          email: user.email!,
          password: oldPassword,
        );
        await user.reauthenticateWithCredential(cred);
        await user.updatePassword(newPassword);
      }

      return {
        'success': true,
        'user': {'name': name, 'email': email},
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _authErrorMessage(e.code)};
    } catch (e) {
      return {'success': false, 'message': 'Gagal update profil: $e'};
    }
  }

  // ── Cek apakah sudah login ──
  // FIX SPEED: synchronous check — tidak perlu async/await
  static Future<bool> isLoggedIn() async {
    return _auth.currentUser != null;
  }

  // ── Ambil data user saat ini ──
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    // FIX SPEED: ambil dari Firebase Auth cache dulu, skip Firestore call
    // Firestore hanya diperlukan kalau displayName belum ada
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return {
        'uid': user.uid,
        'email': user.email,
        'name': user.displayName!,
      };
    }

    // Fallback: ambil dari Firestore kalau displayName kosong
    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      final name = doc.data()?['name'] ?? 'Pengguna';

      // Sync balik ke displayName agar tidak Firestore lagi next time
      await user.updateDisplayName(name);

      return {'uid': user.uid, 'email': user.email, 'name': name};
    } catch (_) {
      return {'uid': user.uid, 'email': user.email, 'name': 'Pengguna'};
    }
  }

  // ── Pesan error yang ramah ──
  static String _authErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Email tidak terdaftar';
      case 'wrong-password':
        return 'Password salah';
      case 'invalid-credential':
        return 'Email atau password salah';
      case 'email-already-in-use':
        return 'Email sudah digunakan';
      case 'weak-password':
        return 'Password terlalu lemah (minimal 6 karakter)';
      case 'invalid-email':
        return 'Format email tidak valid';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti';
      default:
        return 'Terjadi kesalahan ($code)';
    }
  }
}