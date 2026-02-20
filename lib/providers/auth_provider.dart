import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

/// Global navigator key — digunakan untuk navigasi dari Provider
/// tanpa perlu BuildContext (misalnya saat force logout).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// For mengelola state autentikasi di seluruh aplikasi
/// Menggunakan ChangeNotifier agar widget bisa reactive terhadap perubahan state.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AppUser? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDisposed = false;

  /// Stream subscriptions untuk real-time sync
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
        // User masih login, ambil data dari Firestore
        _user = await _authService.getUserData(firebaseUser.uid);

        if (_user != null) {
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

  // ── Login dengan Google ────────────────────────────────────
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final appUser = await _authService.signInWithGoogle();

      if (appUser == null) {
        // User membatalkan login
        _setLoading(false);
        return false;
      }

      _user = appUser;

      // Mulai real-time listeners setelah login berhasil
      _startUserDataStream(appUser.uid);
      _startAuthStateListener();

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Login gagal. Periksa koneksi internet Anda.';
      _setLoading(false);
      return false;
    }
  }

  // ── Simpan Role ────────────────────────────────────────────
  /// Dipanggil setelah user memilih role (Pemilik / Penyewa)
  Future<void> setRole(String role) async {
    if (_user == null) return;

    _setLoading(true);
    _errorMessage = null;

    try {
      await _authService.saveUserRole(_user!.uid, role);
      _user = _user!.copyWith(role: role);
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
