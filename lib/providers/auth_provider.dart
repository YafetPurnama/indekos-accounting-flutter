import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';

/// Global navigator key — digunakan untuk navigasi dari Provider
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// state autentikasi di seluruh aplikasi
/// Menggunakan ChangeNotifier agar widget bisa reactive terhadap perubahan state.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AppUser? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDisposed = false;

  StreamSubscription<AppUser?>? _userDataSubscription;
  StreamSubscription<User?>? _authStateSubscription;

  // ── Getters ────────────────────────────────────────────────
  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  bool get hasRole => _user?.hasRole ?? false;
  String? get role => _user?.role;
  String? get errorMessage => _errorMessage;

  // ── Cek Status Autentikasi ─────────────────────────────────
  /// Dipanggil saat app pertama kali dibuka (di SplashScreen).
  /// Mengecek apakah ada user yang masih login, lalu mulai real-time listeners.
  Future<void> checkAuthStatus() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final firebaseUser = _authService.currentFirebaseUser;

      if (firebaseUser != null) {
        _user = await _authService.getUserData(firebaseUser.uid);

        if (_user != null) {
          final supabaseUser =
              await SupabaseService.findUserByEmail(_user!.email);
          if (supabaseUser != null && supabaseUser['status'] == 'tidak aktif') {
            await _forceLogout();
            _errorMessage = 'Akun Anda dinonaktifkan.';
            _setLoading(false);
            return;
          }

          // Mulai real-time listeners
          _startUserDataStream(firebaseUser.uid);
          _startAuthStateListener();
        }
      } else {
        _user = null;
      }
    } catch (e) {
      _user = null;
      _errorMessage = 'Gagal memeriksa status login.';
    }

    _setLoading(false);
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final appUser = await _authService.signInWithGoogle();

      if (appUser == null) {
        _setLoading(false);
        return false;
      }

      // Cek apakah user terdaftar di Supabase (db_indekos)
      final supabaseUser = await SupabaseService.findUserByEmail(appUser.email);

      if (supabaseUser == null) {
        await _authService.signOut();
        _user = null;
        _errorMessage =
            'Akun belum terdaftar. Hubungi pemilik indekos untuk didaftarkan.';
        _setLoading(false);
        return false;
      }

      if (supabaseUser['status'] == 'tidak aktif') {
        await _authService.signOut();
        _user = null;
        _errorMessage = 'Akun Anda dinonaktifkan. Hubungi admin.';
        _setLoading(false);
        return false;
      }

      // User terdaftar — gunakan role dari Supabase
      final supabaseRole = supabaseUser['role'] as String? ?? '';
      _user = appUser.copyWith(
          role: supabaseRole.isNotEmpty ? supabaseRole : appUser.role);

      // Sync role ke Firestore SEBELUM start listener,
      // agar real-time stream tidak overwrite role dengan null
      if (supabaseRole.isNotEmpty) {
        try {
          await _authService.saveUserRole(appUser.uid, supabaseRole);
        } catch (e) {
          debugPrint('⚠️ Firestore role sync gagal (non-blocking): $e');
        }
      }

      // Mulai real-time listeners (setelah Firestore sudah punya role)
      _startUserDataStream(appUser.uid);
      _startAuthStateListener();

      // Sync Firebase UID ke Supabase jika belum ada
      try {
        await SupabaseService.syncUser(
          firebaseUid: appUser.uid,
          email: appUser.email,
          nama: appUser.displayName,
          role: supabaseRole.isNotEmpty ? supabaseRole : (appUser.role ?? ''),
        );

        // Re-fetch data Supabase setelah sync (id_user mungkin sudah di-update)
        final updatedSupabaseUser =
            await SupabaseService.findUserByEmail(appUser.email);
        if (updatedSupabaseUser != null) {
          final supabaseName = updatedSupabaseUser['nama'] as String? ?? '';
          if (supabaseName.isNotEmpty) {
            _user = _user!.copyWith(displayName: supabaseName);
          }
        }
      } catch (e) {
        debugPrint('⚠️ Supabase sync gagal (non-blocking): $e');
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Login gagal. Periksa koneksi internet Anda.';
      _setLoading(false);
      return false;
    }
  }

  // ── Login Manual ───────────
  Future<bool> signInWithEmail(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final userData = await SupabaseService.signInWithEmail(
        email: email,
        password: password,
      );

      if (userData == null) {
        _errorMessage = 'Email atau password salah.';
        _setLoading(false);
        return false;
      }

      if (userData['status'] == 'tidak aktif') {
        _errorMessage = 'Akun Anda dinonaktifkan. Hubungi admin.';
        _setLoading(false);
        return false;
      }

      _user = AppUser(
        uid: userData['id_user'] as String,
        email: userData['email'] as String? ?? '',
        displayName: userData['nama'] as String? ?? '',
        photoUrl: null,
        role: userData['role'] as String?,
        createdAt: userData['created_at'] != null
            ? DateTime.parse(userData['created_at'] as String)
            : DateTime.now(),
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Login gagal. Periksa koneksi internet Anda.';
      _setLoading(false);
      return false;
    }
  }

  // ── Simpan Role ────────────────────────────────────────────
  Future<void> setRole(String role) async {
    if (_user == null) return;

    _setLoading(true);
    _errorMessage = null;

    try {
      await _authService.saveUserRole(_user!.uid, role);
      _user = _user!.copyWith(role: role);

      // Sinkronisasi role terbaru ke Supabase
      try {
        await SupabaseService.syncUser(
          firebaseUid: _user!.uid,
          email: _user!.email,
          nama: _user!.displayName,
          role: role,
        );
      } catch (e) {
        debugPrint('⚠️ Supabase role sync gagal (non-blocking): $e');
      }
    } catch (e) {
      _errorMessage = 'Gagal menyimpan role. Coba lagi.';
    }

    _setLoading(false);
  }

  // ══════════════════════════════════════════════════════════════
  // ── REAL-TIME SYNC — Firestore Listener ──────────────────────
  // ══════════════════════════════════════════════════════════════

  /// Listen ke Firestore user document secara real-time.
  /// Jika document diedit → UI langsung update.
  /// Jika document dihapus → force logout.
  void _startUserDataStream(String uid) {
    _userDataSubscription?.cancel();
    _userDataSubscription = _authService.streamUserData(uid).listen(
      (appUser) {
        if (_isDisposed) return;
        if (appUser == null) {
          // Document dihapus dari Firestore Console → force logout
          _forceLogout();
        } else {
          _user = appUser;
          notifyListeners();
        }
      },
      onError: (error) {
        debugPrint('🔥 Firestore stream error: $error');
        // Jangan force logout pada error jaringan biasa
      },
    );
  }

  // ══════════════════════════════════════════════════════════════
  // ── REAL-TIME SYNC — Firebase Auth State Listener ────────────
  // ══════════════════════════════════════════════════════════════

  /// Listen ke Firebase Auth state changes.
  /// Jika user dihapus/disabled dari Authentication Console,
  /// Firebase akan emit null → force logout.
  void _startAuthStateListener() {
    _authStateSubscription?.cancel();
    _authStateSubscription =
        _authService.authStateChanges.listen((firebaseUser) {
      if (_isDisposed) return;
      if (firebaseUser == null && _user != null) {
        // User di-delete/disable dari Firebase Auth Console
        _forceLogout();
      }
    });
  }

  // ══════════════════════════════════════════════════════════════
  // ── PULL-TO-REFRESH ──────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════

  /// Reload data user dari Firestore + verifikasi Firebase Auth token.
  /// Dipanggil saat user swipe down (pull-to-refresh) di dashboard.
  Future<void> refreshUserData() async {
    if (_user == null) return;
    _errorMessage = null;

    try {
      // 1. Verifikasi apakah user masih valid di Firebase Auth
      await _authService.verifyCurrentUser();

      // 2. Ambil ulang data dari Firestore
      final freshUser = await _authService.getUserData(_user!.uid);
      if (freshUser == null) {
        // Document sudah tidak ada di Firestore
        await _forceLogout();
      } else {
        // Periksa status keaktifan di Supabase
        final supabaseUser =
            await SupabaseService.findUserByEmail(freshUser.email);
        if (supabaseUser != null && supabaseUser['status'] == 'tidak aktif') {
          await _forceLogout();
          return;
        }

        _user = freshUser;
        notifyListeners();
      }
    } catch (e) {
      // User sudah dihapus/disabled → force logout
      debugPrint('🔥 Refresh failed, force logout: $e');
      await _forceLogout();
    }
  }

  // ══════════════════════════════════════════════════════════════
  // ── FORCE LOGOUT ─────────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════

  /// Dipanggil otomatis saat user dihapus dari Firebase Console.
  /// Membersihkan semua state dan navigasi ke halaman login.
  Future<void> _forceLogout() async {
    _userDataSubscription?.cancel();
    _authStateSubscription?.cancel();
    _userDataSubscription = null;
    _authStateSubscription = null;

    try {
      await _authService.signOut();
    } catch (_) {
      // Ignore sign out errors saat force logout
    }

    _user = null;

    if (!_isDisposed) {
      notifyListeners();
    }

    // Navigasi ke login menggunakan global navigator key
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }

  // ── Logout ─────────────────────────────────────────────────
  Future<void> signOut() async {
    _setLoading(true);

    // Stop semua real-time listeners
    _userDataSubscription?.cancel();
    _authStateSubscription?.cancel();
    _userDataSubscription = null;
    _authStateSubscription = null;

    try {
      await _authService.signOut();
      _user = null;
    } catch (e) {
      _errorMessage = 'Gagal logout.';
    }

    _setLoading(false);
  }

  // ── Helper ─────────────────────────────────────────────────
  void _setLoading(bool value) {
    if (_isDisposed) return;
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _userDataSubscription?.cancel();
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
