import 'package:flutter/material.dart';
import '../models/kamar_model.dart';
import '../services/supabase_service.dart';

/// Provider untuk mengelola state data kamar & statistik dashboard.
/// Digunakan oleh Owner Dashboard untuk menampilkan ringkasan.
class KamarProvider extends ChangeNotifier {
  List<Kamar> _kamarList = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Statistik dashboard
  int _totalKamar = 0;
  int _penyewaAktif = 0;
  int _tagihanPending = 0;
  int _tagihanMenunggak = 0;

  // ── Getters ────────────────────────────────────────────────
  List<Kamar> get kamarList => _kamarList;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalKamar => _totalKamar;
  int get penyewaAktif => _penyewaAktif;
  int get tagihanPending => _tagihanPending;
  int get tagihanMenunggak => _tagihanMenunggak;

  // ── Fetch Daftar Kamar ────────────────────────────────────
  /// Ambil semua data kamar dari Supabase
  Future<void> fetchKamarList() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _kamarList = await SupabaseService.fetchKamarList();
    } catch (e) {
      _errorMessage = 'Gagal memuat data kamar.';
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Fetch Statistik Dashboard ─────────────────────────────
  /// Ambil semua angka statistik untuk dashboard Owner.
  /// Memanggil beberapa query secara paralel untuk kecepatan.
  Future<void> fetchDashboardStats() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        SupabaseService.countTotalKamar(),
        SupabaseService.HitungPenyewaAktif(),
        SupabaseService.countTagihanPending(),
        SupabaseService.countTagihanMenunggak(),
      ]);

      _totalKamar = results[0];
      _penyewaAktif = results[1];
      _tagihanPending = results[2];
      _tagihanMenunggak = results[3];
    } catch (e) {
      _errorMessage = 'Gagal memuat statistik.';
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
