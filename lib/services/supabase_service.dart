import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/kamar_model.dart';
import '../models/branch_model.dart';
import '../models/penyewa_model.dart';
import '../models/tagihan_model.dart';
import '../models/pembayaran_model.dart';

/// Service utama untuk operasi CRUD ke Supabase (PostgreSQL).
class SupabaseService {
  SupabaseService._();

  /// Singleton client dari Supabase
  static SupabaseClient get _client => Supabase.instance.client;

  // ══════════════════════════════════════════════════════════════
  // ── USERS — Sinkronisasi Firebase ↔ Supabase ─────────────────
  // ══════════════════════════════════════════════════════════════

  /// Sinkronisasi data user dari Firebase ke tabel `users` di Supabase.
  static Future<void> syncUser({
    required String firebaseUid,
    required String email,
    required String nama,
    required String role,
  }) async {
    try {
      await _client.from('users').upsert({
        'id_user': firebaseUid,
        'email': email,
        'nama': nama,
        'role': role,
      });
      debugPrint('✅ User synced to Supabase: $email');
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (syncUser): $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> findUserByEmail(String email) async {
    try {
      final response =
          await _client.from('users').select().eq('email', email).maybeSingle();
      return response;
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (findUserByEmail): $e');
      return null;
    }
  }

  /// Login manual
  static Future<Map<String, dynamic>?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('email', email)
          .eq('password', password)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (signInWithEmail): $e');
      return null;
    }
  }

  /// Ambil semua users
  static Future<List<Map<String, dynamic>>> fetchUserList() async {
    try {
      final response = await _client
          .from('users')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (fetchUserList): $e');
      return [];
    }
  }

  /// Tambah user baru
  static Future<void> addUser(Map<String, dynamic> data) async {
    try {
      await _client.from('users').insert(data);
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (addUser): $e');
      rethrow;
    }
  }

  /// Update user
  static Future<void> updateUser(String id, Map<String, dynamic> data) async {
    try {
      await _client.from('users').update(data).eq('id_user', id);
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (updateUser): $e');
      rethrow;
    }
  }

  /// Hapus user
  static Future<void> deleteUser(String id) async {
    try {
      await _client.from('users').delete().eq('id_user', id);
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (deleteUser): $e');
      rethrow;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // ── BRANCH — Cabang / Lokasi Indekos ──────────────────────────
  // ══════════════════════════════════════════════════════════════

  /// Ambil daftar branch dengan search & pagination.
  /// [search] filter nama_branch (ilike). [page] mulai dari 0.
  static Future<List<Branch>> fetchBranchList({
    String? search,
    int page = 0,
    int perPage = 10,
  }) async {
    try {
      var query = _client
          .from('branch')
          .select()
          .isFilter('deleted_at', null)
          .order('nama_branch', ascending: true)
          .range(page * perPage, (page + 1) * perPage - 1);

      if (search != null && search.trim().isNotEmpty) {
        query = _client
            .from('branch')
            .select()
            .isFilter('deleted_at', null)
            .ilike('nama_branch', '%${search.trim()}%')
            .order('nama_branch', ascending: true)
            .range(page * perPage, (page + 1) * perPage - 1);
      }

      final response = await query;
      return response.map((json) => Branch.fromJson(json)).toList();
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (fetchBranchList): $e');
      return [];
    }
  }

  /// Ambil semua branch (tanpa pagination, untuk dropdown)
  static Future<List<Branch>> fetchAllBranches() async {
    try {
      final response = await _client
          .from('branch')
          .select()
          .isFilter('deleted_at', null)
          .order('nama_branch', ascending: true);
      return response.map((json) => Branch.fromJson(json)).toList();
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (fetchAllBranches): $e');
      return [];
    }
  }

  /// Tambah branch baru
  static Future<void> addBranch(Map<String, dynamic> data,
      {String? userId}) async {
    try {
      if (userId != null) data['created_by'] = userId;
      await _client.from('branch').insert(data);
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (addBranch): $e');
      rethrow;
    }
  }

  /// Update branch
  static Future<void> updateBranch(String id, Map<String, dynamic> data,
      {String? userId}) async {
    try {
      data['updated_at'] = DateTime.now().toUtc().toIso8601String();
      if (userId != null) data['updated_by'] = userId;
      await _client.from('branch').update(data).eq('id_branch', id);
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (updateBranch): $e');
      rethrow;
    }
  }

  /// Soft-delete branch
  static Future<void> deleteBranch(String id, {String? userId}) async {
    try {
      final data = <String, dynamic>{
        'deleted_at': DateTime.now().toUtc().toIso8601String(),
      };
      if (userId != null) data['updated_by'] = userId;
      await _client.from('branch').update(data).eq('id_branch', id);
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (deleteBranch): $e');
      rethrow;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // ── KAMAR — Master Data Properti ──────────────────────────────
  // ══════════════════════════════════════════════════════════════

  /// Ambil data kamar, opsional filter by branchId
  static Future<List<Kamar>> fetchKamarList({String? branchId}) async {
    try {
      var query = _client
          .from('kamar')
          .select('*, branch(nama_branch)')
          .order('nomor_kamar', ascending: true);

      if (branchId != null) {
        query = _client
            .from('kamar')
            .select('*, branch(nama_branch)')
            .eq('branch_id', branchId)
            .order('nomor_kamar', ascending: true);
      }

      final response = await query;
      return response.map((json) => Kamar.fromJson(json)).toList();
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (fetchKamarList): $e');
      return [];
    }
  }

  /// Tambah kamar baru
  static Future<void> addKamar(Map<String, dynamic> data) async {
    try {
      await _client.from('kamar').insert(data);
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (addKamar): $e');
      rethrow;
    }
  }

  /// Update kamar
  static Future<void> updateKamar(String id, Map<String, dynamic> data) async {
    try {
      await _client.from('kamar').update(data).eq('id_kamar', id);
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (updateKamar): $e');
      rethrow;
    }
  }

  /// Hapus kamar
  static Future<void> deleteKamar(String id) async {
    try {
      await _client.from('kamar').delete().eq('id_kamar', id);
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (deleteKamar): $e');
      rethrow;
    }
  }

  /// Hitung total kamar
  static Future<int> countTotalKamar() async {
    try {
      final response = await _client.from('kamar').select('id_kamar');
      return response.length;
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (countTotalKamar): $e');
      return 0;
    }
  }

  /// Hitung kamar yang terisi
  static Future<int> countKamarTerisi() async {
    try {
      final response =
          await _client.from('kamar').select('id_kamar').eq('status', 'terisi');
      return response.length;
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (countKamarTerisi): $e');
      return 0;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // ── PENYEWA ───────────────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════

  /// Hitung jumlah penyewa aktif
  static Future<int> countPenyewaAktif() async {
    try {
      final response = await _client
          .from('penyewa')
          .select('id_penyewa')
          .eq('status_aktif', true);
      return response.length;
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (countPenyewaAktif): $e');
      return 0;
    }
  }

  /// Ambil data penyewa berdasarkan user_id
  static Future<Penyewa?> fetchPenyewaByUserId(String userId) async {
    try {
      final response = await _client
          .from('penyewa')
          .select()
          .eq('user_id', userId)
          .eq('status_aktif', true)
          .maybeSingle();
      if (response != null) {
        return Penyewa.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (fetchPenyewaByUserId): $e');
      return null;
    }
  }

  /// Ambil data kamar berdasarkan kamar_id
  static Future<Kamar?> fetchKamarById(String kamarId) async {
    try {
      final response = await _client
          .from('kamar')
          .select()
          .eq('id_kamar', kamarId)
          .maybeSingle();
      if (response != null) {
        return Kamar.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (fetchKamarById): $e');
      return null;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // ── TAGIHAN — Core Akuntansi ──────────────────────────────────
  // ══════════════════════════════════════════════════════════════

  /// Hitung jumlah tagihan yang belum lunas (pending)
  static Future<int> countTagihanPending() async {
    try {
      final response = await _client
          .from('tagihan')
          .select('id_tagihan')
          .eq('status_lunas', false);
      return response.length;
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (countTagihanPending): $e');
      return 0;
    }
  }

  /// Hitung jumlah tagihan menunggak (belum lunas DAN lewat jatuh tempo)
  static Future<int> countTagihanMenunggak() async {
    try {
      final now = DateTime.now().toIso8601String().split('T')[0];
      final response = await _client
          .from('tagihan')
          .select('id_tagihan')
          .eq('status_lunas', false)
          .lt('jatuh_tempo', now);
      return response.length;
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (countTagihanMenunggak): $e');
      return 0;
    }
  }

  /// Ambil tagihan berdasarkan penyewa_id (untuk dashboard tenant)
  static Future<List<Tagihan>> fetchTagihanByPenyewaId(String penyewaId) async {
    try {
      final response = await _client
          .from('tagihan')
          .select()
          .eq('penyewa_id', penyewaId)
          .order('bulan_tagihan', ascending: false);
      return response.map((json) => Tagihan.fromJson(json)).toList();
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (fetchTagihanByPenyewaId): $e');
      return [];
    }
  }

  /// Ambil tagihan terbaru yang belum lunas (untuk tenant)
  static Future<Tagihan?> fetchTagihanAktifByPenyewaId(String penyewaId) async {
    try {
      final response = await _client
          .from('tagihan')
          .select()
          .eq('penyewa_id', penyewaId)
          .eq('status_lunas', false)
          .order('jatuh_tempo', ascending: true)
          .limit(1)
          .maybeSingle();
      if (response != null) {
        return Tagihan.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (fetchTagihanAktifByPenyewaId): $e');
      return null;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // ── PEMBAYARAN ────────────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════

  /// Ambil daftar pembayaran berdasarkan tagihan_id
  static Future<List<Pembayaran>> fetchPembayaranByTagihanId(
      String tagihanId) async {
    try {
      final response = await _client
          .from('pembayaran')
          .select()
          .eq('tagihan_id', tagihanId)
          .order('tanggal_bayar', ascending: false);
      return response.map((json) => Pembayaran.fromJson(json)).toList();
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (fetchPembayaranByTagihanId): $e');
      return [];
    }
  }
}
