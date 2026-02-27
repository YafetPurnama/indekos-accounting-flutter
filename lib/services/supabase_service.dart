import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/kamar_model.dart';
import '../models/branch_model.dart';
import '../models/fasilitas_model.dart';
import '../models/penyewa_model.dart';
import '../models/tagihan_model.dart';
import '../models/pembayaran_model.dart';
import '../models/laporan_model.dart';
import '../models/biaya_operasional_model.dart';
import '../models/potongan_deposit_model.dart';

/// Service utama untuk operasi CRUD
class SupabaseService {
  SupabaseService._();

  static SupabaseClient get _client => Supabase.instance.client;

  // ══════════════════════════════════════════════════════════════
  // ── USERS — Sinkronisasi Firebase X Supabase ─────────────────
  // ══════════════════════════════════════════════════════════════

  static Future<void> syncUser({
    required String firebaseUid,
    required String email,
    required String nama,
    required String role,
  }) async {
    try {
      // Cek apakah sudah ada user dengan email ini (pre-registered by owner)
      final existing = await findUserByEmail(email);

      if (existing != null && existing['id_user'] != firebaseUid) {
        // User sudah di-register oleh owner → update id_user ke Firebase UID
        final oldId = existing['id_user'] as String;

        // Update FK references dulu (penyewa.user_id)
        await _client
            .from('penyewa')
            .update({'user_id': firebaseUid}).eq('user_id', oldId);

        // Baru update users.id_user + nama dari Google profile
        await _client.from('users').update({
          'id_user': firebaseUid,
          'nama': nama,
        }).eq('id_user', oldId);

        debugPrint('✅ Pre-registered user linked to Firebase UID: $email');
        return;
      }

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

  static Future<void> addUser(Map<String, dynamic> data) async {
    try {
      data.putIfAbsent('status', () => 'aktif');
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
      const select = '*, branch(nama_branch), kamar_fasilitas(fasilitas(*))';
      var query = _client
          .from('kamar')
          .select(select)
          .order('nomor_kamar', ascending: true);

      if (branchId != null) {
        query = _client
            .from('kamar')
            .select(select)
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

  /// Tambah kamar baru dan return id_kamar
  static Future<String?> addKamarReturning(Map<String, dynamic> data) async {
    try {
      final response =
          await _client.from('kamar').insert(data).select('id_kamar').single();
      return response['id_kamar'] as String?;
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (addKamarReturning): $e');
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

  /// Cek apakah kamar memiliki penyewa aktif
  static Future<bool> CekPenyewaAktif(String kamarId) async {
    try {
      final response = await _client
          .from('penyewa')
          .select('id_penyewa')
          .eq('kamar_id', kamarId)
          .eq('status_aktif', true)
          .isFilter('deleted_at', null);
      return response.isNotEmpty;
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (CekPenyewaAktif): $e');
      return false;
    }
  }

  /// Hitung jumlah kamar yang terkait branch
  static Future<int> HitungKamarByCabang(String branchId) async {
    try {
      final response = await _client
          .from('kamar')
          .select('id_kamar')
          .eq('branch_id', branchId);
      return response.length;
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (HitungKamarByCabang): $e');
      return 0;
    }
  }

  /// Ambil statistik dashboard, opsional filter per branch
  /// Returns: {totalKamar, kamarTerisi, penyewaAktif, tagihanPending, tagihanMenunggak}
  static Future<Map<String, int>> fetchDashboardStatsByBranch(
      {String? branchId}) async {
    try {
      // 1. Kamar stats
      var kamarQuery = _client.from('kamar').select('id_kamar, status');
      if (branchId != null) kamarQuery = kamarQuery.eq('branch_id', branchId);
      final kamarData = await kamarQuery;

      final totalKamar = kamarData.length;
      final kamarTerisi =
          kamarData.where((k) => k['status'] == 'terisi').length;

      // Kumpulkan id_kamar untuk filter penyewa
      final kamarIds = kamarData.map((k) => k['id_kamar'] as String).toList();

      // 2. Penyewa aktif (filter by kamar_ids jika per branch)
      int penyewaAktif = 0;
      List<String> penyewaIds = [];
      if (kamarIds.isNotEmpty) {
        var penyewaQuery = _client
            .from('penyewa')
            .select('id_penyewa, kamar_id')
            .eq('status_aktif', true)
            .isFilter('deleted_at', null);
        if (branchId != null) {
          penyewaQuery = penyewaQuery.inFilter('kamar_id', kamarIds);
        }
        final penyewaData = await penyewaQuery;
        penyewaAktif = penyewaData.length;
        penyewaIds = penyewaData.map((p) => p['id_penyewa'] as String).toList();
      } else if (branchId == null) {
        // Global: ambil semua penyewa aktif
        final penyewaData = await _client
            .from('penyewa')
            .select('id_penyewa')
            .eq('status_aktif', true)
            .isFilter('deleted_at', null);
        penyewaAktif = penyewaData.length;
        penyewaIds = penyewaData.map((p) => p['id_penyewa'] as String).toList();
      }

      // 3. Tagihan pending & menunggak
      int tagihanPending = 0;
      int tagihanMenunggak = 0;
      final now = DateTime.now().toIso8601String().split('T')[0];

      if (penyewaIds.isNotEmpty) {
        var tagihanQuery = _client
            .from('tagihan')
            .select('id_tagihan, jatuh_tempo')
            .eq('status_lunas', false);
        if (branchId != null) {
          tagihanQuery = tagihanQuery.inFilter('penyewa_id', penyewaIds);
        }
        final tagihanData = await tagihanQuery;
        tagihanPending = tagihanData.length;
        tagihanMenunggak = tagihanData
            .where((t) =>
                t['jatuh_tempo'] != null && t['jatuh_tempo'].compareTo(now) < 0)
            .length;
      } else if (branchId == null) {
        // Global fallback
        final pendingData = await _client
            .from('tagihan')
            .select('id_tagihan, jatuh_tempo')
            .eq('status_lunas', false);
        tagihanPending = pendingData.length;
        tagihanMenunggak = pendingData
            .where((t) =>
                t['jatuh_tempo'] != null && t['jatuh_tempo'].compareTo(now) < 0)
            .length;
      }

      return {
        'totalKamar': totalKamar,
        'kamarTerisi': kamarTerisi,
        'penyewaAktif': penyewaAktif,
        'tagihanPending': tagihanPending,
        'tagihanMenunggak': tagihanMenunggak,
      };
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (fetchDashboardStatsByBranch): $e');
      return {
        'totalKamar': 0,
        'kamarTerisi': 0,
        'penyewaAktif': 0,
        'tagihanPending': 0,
        'tagihanMenunggak': 0,
      };
    }
  }

  // ══════════════════════════════════════════════════════════════
  // ── FASILITAS — Master Data Fasilitas ─────────────────────────
  // ══════════════════════════════════════════════════════════════

  /// Ambil semua fasilitas (tanpa soft-deleted)
  static Future<List<Fasilitas>> fetchAllFasilitas() async {
    try {
      final response = await _client
          .from('fasilitas')
          .select()
          .isFilter('deleted_at', null)
          .order('nama_fasilitas', ascending: true);
      return response.map((json) => Fasilitas.fromJson(json)).toList();
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (fetchAllFasilitas): $e');
      return [];
    }
  }

  /// Ambil kamar yang menggunakan fasilitas tertentu
  static Future<List<Kamar>> fetchKamarByFasilitas(String fasilitasId) async {
    try {
      final response = await _client
          .from('kamar')
          .select('*, branch(nama_branch), kamar_fasilitas!inner(fasilitas_id)')
          .eq('kamar_fasilitas.fasilitas_id', fasilitasId)
          .order('nomor_kamar', ascending: true);
      return response.map((json) => Kamar.fromJson(json)).toList();
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (fetchKamarByFasilitas): $e');
      return [];
    }
  }

  /// Hitung penggunaan semua fasilitas (berapa kali setiap fasilitas_id dipakai di kamar_fasilitas)
  static Future<Map<String, int>> getFasilitasUsageCounts() async {
    try {
      final response =
          await _client.from('kamar_fasilitas').select('fasilitas_id');
      final Map<String, int> counts = {};
      for (var row in response) {
        final fId = row['fasilitas_id'] as String;
        counts[fId] = (counts[fId] ?? 0) + 1;
      }
      return counts;
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (getFasilitasUsageCounts): $e');
      return {};
    }
  }

  /// Tambah fasilitas baru
  static Future<void> addFasilitas(Map<String, dynamic> data,
      {String? userId}) async {
    try {
      if (userId != null) data['created_by'] = userId;
      await _client.from('fasilitas').insert(data);
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (addFasilitas): $e');
      rethrow;
    }
  }

  /// Update fasilitas
  static Future<void> updateFasilitas(String id, Map<String, dynamic> data,
      {String? userId}) async {
    try {
      data['updated_at'] = DateTime.now().toUtc().toIso8601String();
      if (userId != null) data['updated_by'] = userId;
      await _client.from('fasilitas').update(data).eq('id_fasilitas', id);
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (updateFasilitas): $e');
      rethrow;
    }
  }

  static Future<void> deleteFasilitas(String id, {String? userId}) async {
    try {
      final data = <String, dynamic>{
        'deleted_at': DateTime.now().toUtc().toIso8601String(),
      };
      if (userId != null) data['updated_by'] = userId;
      await _client.from('fasilitas').update(data).eq('id_fasilitas', id);
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (deleteFasilitas): $e');
      rethrow;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // ── KAMAR–FASILITAS — Junction Sync ───────────────────────────
  // ══════════════════════════════════════════════════════════════

  static Future<void> syncKamarFasilitas(
      String kamarId, List<String> fasilitasIds) async {
    try {
      await _client.from('kamar_fasilitas').delete().eq('kamar_id', kamarId);

      // Insert new
      if (fasilitasIds.isNotEmpty) {
        final rows = fasilitasIds
            .map((fId) => {'kamar_id': kamarId, 'fasilitas_id': fId})
            .toList();
        await _client.from('kamar_fasilitas').insert(rows);
      }
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (syncKamarFasilitas): $e');
      rethrow;
    }
  }

  static Future<List<String>> fetchKamarFasilitasIds(String kamarId) async {
    try {
      final response = await _client
          .from('kamar_fasilitas')
          .select('fasilitas_id')
          .eq('kamar_id', kamarId);
      return response.map((row) => row['fasilitas_id'] as String).toList();
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (fetchKamarFasilitasIds): $e');
      return [];
    }
  }

  // ══════════════════════════════════════════════════════════════
  // ── PENYEWA ───────────────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════

  /// Hitung jumlah penyewa aktif
  static Future<int> HitungPenyewaAktif() async {
    try {
      final response = await _client
          .from('penyewa')
          .select('id_penyewa')
          .eq('status_aktif', true);
      return response.length;
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (HitungPenyewaAktif): $e');
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
        final Map<String, dynamic> mutableResponse =
            Map<String, dynamic>.from(response);
        final totalPotongan =
            await fetchTotalPotongan(mutableResponse['id_penyewa'] as String);
        mutableResponse['total_deduction'] = totalPotongan;
        return Penyewa.fromJson(mutableResponse);
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
          .select('*, branch(nama_branch), kamar_fasilitas(fasilitas(*))')
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

  static Future<String?> uploadBuktiBayar(File file, String tagihanId) async {
    try {
      final ext = file.path.split('.').last.toLowerCase();

      // Tentukan content-type berdasarkan ekstensi
      String contentType;
      switch (ext) {
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'png':
          contentType = 'image/png';
          break;
        case 'webp':
          contentType = 'image/webp';
          break;
        case 'heic':
        case 'heif':
          contentType = 'image/heic';
          break;
        default:
          contentType = 'image/jpeg';
      }

      final path = '$tagihanId/${DateTime.now().millisecondsSinceEpoch}.$ext';

      final bytes = await file.readAsBytes();
      debugPrint(
          '📤 Uploading bukti bayar: path=$path, size=${bytes.length} bytes, contentType=$contentType');

      await _client.storage.from('bukti-bayar').uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: true,
            ),
          );

      final publicUrl = _client.storage.from('bukti-bayar').getPublicUrl(path);
      debugPrint('✅ Upload berhasil: $publicUrl');
      return publicUrl;
    } catch (e, stackTrace) {
      debugPrint('🔥 ERROR Supabase (uploadBuktiBayar): $e');
      debugPrint('🔥 StackTrace: $stackTrace');
      return null;
    }
  }

  /// Insert pembayaran baru
  static Future<void> addPembayaran(Map<String, dynamic> data) async {
    try {
      await _client.from('pembayaran').insert(data);
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (addPembayaran): $e');
      rethrow;
    }
  }

  /// Update pembayaran (status_validasi, dll)
  static Future<void> updatePembayaran(
      String id, Map<String, dynamic> data) async {
    try {
      await _client.from('pembayaran').update(data).eq('id_pembayaran', id);
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (updatePembayaran): $e');
      rethrow;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // ── PENYEWA CRUD (Owner) ─────────────────────────────────────
  // ══════════════════════════════════════════════════════════════

  /// Ambil semua penyewa aktif + join info user & kamar + total deduction
  static Future<List<Penyewa>> fetchPenyewaList() async {
    try {
      final response = await _client
          .from('penyewa')
          .select(
              '*, users!penyewa_user_id_fkey(nama, email), kamar!penyewa_kamar_id_fkey(nomor_kamar, branch_id, branch(nama_branch))')
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);

      // Ambil total deduction per penyewa
      final deductionResponse =
          await _client.from('potongan_deposit').select('id_penyewa, nominal');
      final Map<String, double> deductionMap = {};
      for (var row in deductionResponse) {
        final pid = row['id_penyewa'] as String;
        deductionMap[pid] = (deductionMap[pid] ?? 0) +
            ((row['nominal'] as num?)?.toDouble() ?? 0);
      }

      return response.map((json) {
        final pId = json['id_penyewa'] as String;
        json['total_deduction'] = deductionMap[pId] ?? 0;
        return Penyewa.fromJson(json);
      }).toList();
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (fetchPenyewaList): $e');
      return [];
    }
  }

  /// Tambah penyewa baru + otomatis update kamar → terisi
  static Future<void> addPenyewa(Map<String, dynamic> data,
      {String? userId}) async {
    try {
      if (userId != null) {
        data['created_by'] = userId;
      }
      await _client.from('penyewa').insert(data);

      // Auto-update kamar status → terisi
      if (data['kamar_id'] != null) {
        await updateKamarStatus(data['kamar_id'], 'terisi');
      }
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (addPenyewa): $e');
      rethrow;
    }
  }

  /// Update data penyewa
  static Future<void> updatePenyewa(String id, Map<String, dynamic> data,
      {String? userId, String? oldKamarId}) async {
    try {
      data['updated_at'] = DateTime.now().toUtc().toIso8601String();
      if (userId != null) data['updated_by'] = userId;
      await _client.from('penyewa').update(data).eq('id_penyewa', id);

      final newKamarId = data['kamar_id'] as String?;
      if (oldKamarId != null &&
          newKamarId != null &&
          oldKamarId != newKamarId) {
        await updateKamarStatus(oldKamarId, 'kosong');
        await updateKamarStatus(newKamarId, 'terisi');
      }
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (updatePenyewa): $e');
      rethrow;
    }
  }

  /// Nonaktifkan penyewa (soft-delete) + kamar → kosong
  static Future<void> deletePenyewa(String id,
      {String? userId, String? kamarId}) async {
    try {
      await _client.from('penyewa').update({
        'status_aktif': false,
        'deleted_at': DateTime.now().toUtc().toIso8601String(),
        if (userId != null) 'updated_by': userId,
      }).eq('id_penyewa', id);

      // Kamar kembali kosong
      if (kamarId != null) {
        await updateKamarStatus(kamarId, 'kosong');
      }
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (deletePenyewa): $e');
      rethrow;
    }
  }

  /// Ambil user_id yang sudah di-assign sebagai penyewa aktif
  static Future<Set<String>> fetchAssignedUserIds() async {
    try {
      final response = await _client
          .from('penyewa')
          .select('user_id')
          .eq('status_aktif', true)
          .isFilter('deleted_at', null);
      return response.map((row) => row['user_id'] as String).toSet();
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (fetchAssignedUserIds): $e');
      return {};
    }
  }

  /// Ambil user dengan role tertentu + status aktif (untuk dropdown pilih penyewa)
  static Future<List<Map<String, dynamic>>> fetchUsersByRole(
      String role) async {
    try {
      return await _client
          .from('users')
          .select('id_user, nama, email')
          .eq('role', role)
          .eq('status', 'aktif')
          .isFilter('deleted_at', null)
          .order('nama', ascending: true);
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (fetchUsersByRole): $e');
      return [];
    }
  }

  /// Ambil kamar berstatus 'kosong' (untuk dropdown assign penyewa)
  static Future<List<Kamar>> fetchAvailableKamar() async {
    try {
      final response = await _client
          .from('kamar')
          .select('*, branch(nama_branch)')
          .eq('status', 'kosong')
          .isFilter('deleted_at', null)
          .order('nomor_kamar', ascending: true);
      return response.map((json) => Kamar.fromJson(json)).toList();
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (fetchAvailableKamar): $e');
      return [];
    }
  }

  /// Update status kamar
  static Future<void> updateKamarStatus(String kamarId, String status) async {
    try {
      await _client
          .from('kamar')
          .update({'status': status}).eq('id_kamar', kamarId);
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (updateKamarStatus): $e');
    }
  }

  // ══════════════════════════════════════════════════════════════
  // ── TAGIHAN CRUD (Owner) ─────────────────────────────────────
  // ══════════════════════════════════════════════════════════════

  /// Ambil daftar tagihan per penyewa (untuk owner)
  static Future<List<Tagihan>> fetchTagihanListByPenyewaId(
      String penyewaId) async {
    try {
      final response = await _client
          .from('tagihan')
          .select()
          .eq('penyewa_id', penyewaId)
          .isFilter('deleted_at', null)
          .order('bulan_tagihan', ascending: false);
      return response.map((json) => Tagihan.fromJson(json)).toList();
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (fetchTagihanListByPenyewaId): $e');
      return [];
    }
  }

  /// Tambah tagihan baru
  static Future<void> addTagihan(Map<String, dynamic> data,
      {String? userId}) async {
    try {
      if (userId != null) data['created_by'] = userId;
      await _client.from('tagihan').insert(data);
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (addTagihan): $e');
      rethrow;
    }
  }

  /// Update tagihan (misal: tandai lunas, edit nominal)
  static Future<void> updateTagihan(String id, Map<String, dynamic> data,
      {String? userId}) async {
    try {
      data['updated_at'] = DateTime.now().toUtc().toIso8601String();
      if (userId != null) data['updated_by'] = userId;
      await _client.from('tagihan').update(data).eq('id_tagihan', id);
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (updateTagihan): $e');
      rethrow;
    }
  }

  /// Soft-delete tagihan
  static Future<void> deleteTagihan(String id, {String? userId}) async {
    try {
      await _client.from('tagihan').update({
        'deleted_at': DateTime.now().toUtc().toIso8601String(),
        if (userId != null) 'updated_by': userId,
      }).eq('id_tagihan', id);
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (deleteTagihan): $e');
      rethrow;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // ── LAPORAN PENYEWA ───────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════

  static Future<List<LaporanModel>> fetchLaporanByPenyewaId(
      String penyewaId) async {
    try {
      final response = await _client
          .from('laporan_penyewa')
          .select('*, kamar(nomor_kamar)')
          .eq('penyewa_id', penyewaId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);
      return response.map((json) => LaporanModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (fetchLaporanByPenyewaId): $e');
      return [];
    }
  }

  static Future<List<LaporanModel>> fetchSemuaLaporan() async {
    try {
      final response = await _client
          .from('laporan_penyewa')
          .select('*, penyewa!inner(users(nama)), kamar(nomor_kamar)')
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);
      return response.map((json) => LaporanModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (fetchSemuaLaporan): $e');
      return [];
    }
  }

  static Future<void> addLaporan(Map<String, dynamic> data,
      {String? userId}) async {
    try {
      if (userId != null) data['created_by'] = userId;
      await _client.from('laporan_penyewa').insert(data);
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (addLaporan): $e');
      rethrow;
    }
  }

  static Future<void> updateLaporanStatus(String id, String status,
      {String? userId}) async {
    try {
      final data = {
        'status': status,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      if (userId != null) data['updated_by'] = userId;
      await _client.from('laporan_penyewa').update(data).eq('id_laporan', id);
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (updateLaporanStatus): $e');
      rethrow;
    }
  }

  static Future<String?> uploadFotoLaporan(File file, String pathPrefix) async {
    try {
      final ext = file.path.split('.').last.toLowerCase();
      String contentType = 'image/jpeg';
      if (ext == 'png')
        contentType = 'image/png';
      else if (ext == 'webp')
        contentType = 'image/webp';
      else if (ext == 'heic' || ext == 'heif') contentType = 'image/heic';

      final path =
          'laporan/$pathPrefix/${DateTime.now().millisecondsSinceEpoch}.$ext';
      final bytes = await file.readAsBytes();

      await _client.storage.from('bukti-bayar').uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );

      return _client.storage.from('bukti-bayar').getPublicUrl(path);
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (uploadFotoLaporan): $e');
      return null;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // ── BIAYA OPERASIONAL ───────────────────────────────────────
  // ══════════════════════════════════════════════════════════════

  /// Ambil biaya operasional per periode, opsional filter branch
  static Future<List<BiayaOperasional>> fetchBiayaOperasional({
    DateTime? startDate,
    DateTime? endDate,
    String? branchId,
  }) async {
    try {
      var query = _client
          .from('biaya_operasional')
          .select('*, branch(nama_branch)')
          .isFilter('deleted_at', null);

      if (startDate != null) {
        query = query.gte(
            'tanggal_transaksi', startDate.toIso8601String().split('T')[0]);
      }
      if (endDate != null) {
        query = query.lte(
            'tanggal_transaksi', endDate.toIso8601String().split('T')[0]);
      }
      if (branchId != null) {
        query = query.eq('branch_id', branchId);
      }

      final response = await query.order('tanggal_transaksi', ascending: false);
      return response.map((json) => BiayaOperasional.fromJson(json)).toList();
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (fetchBiayaOperasional): $e');
      return [];
    }
  }

  static Future<void> TambahBiayaOperasionalBaru(Map<String, dynamic> data,
      {String? userId}) async {
    try {
      if (userId != null) data['created_by'] = userId;
      await _client.from('biaya_operasional').insert(data);
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (TambahBiayaOperasionalBaru): $e');
      rethrow;
    }
  }

  /// Update biaya operasional
  static Future<void> updateBiayaOperasional(
      String id, Map<String, dynamic> data,
      {String? userId}) async {
    try {
      data['updated_at'] = DateTime.now().toUtc().toIso8601String();
      if (userId != null) data['updated_by'] = userId;
      await _client.from('biaya_operasional').update(data).eq('id_biaya', id);
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (updateBiayaOperasional): $e');
      rethrow;
    }
  }

  /// Soft-delete biaya operasional
  static Future<void> deleteBiayaOperasional(String id,
      {String? userId}) async {
    try {
      final data = <String, dynamic>{
        'deleted_at': DateTime.now().toUtc().toIso8601String(),
      };
      if (userId != null) data['updated_by'] = userId;
      await _client.from('biaya_operasional').update(data).eq('id_biaya', id);
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (deleteBiayaOperasional): $e');
      rethrow;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // ── LAPORAN KEUANGAN — Aggregate Queries ───────────────────
  // ══════════════════════════════════════════════════════════════

  /// Ambil pembayaran yang sudah valid di periode tertentu
  static Future<List<Pembayaran>> fetchPembayaranValidByPeriode(
      DateTime startDate, DateTime endDate) async {
    try {
      final start = startDate.toIso8601String();
      final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59)
          .toIso8601String();
      final response = await _client
          .from('pembayaran')
          .select(
              '*, tagihan!inner(nominal_kamar, total_tagihan, status_lunas, penyewa_id)')
          .eq('status_validasi', 'valid')
          .gte('tanggal_bayar', start)
          .lte('tanggal_bayar', end)
          .isFilter('deleted_at', null);
      return response.map((json) => Pembayaran.fromJson(json)).toList();
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (fetchPembayaranValidByPeriode): $e');
      return [];
    }
  }

  /// Ambil semua tagihan yang lunas di periode (berdasarkan updated_at)
  static Future<List<Tagihan>> fetchTagihanLunasByPeriode(
      DateTime startDate, DateTime endDate) async {
    try {
      final start = startDate.toIso8601String();
      final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59)
          .toIso8601String();
      final response = await _client
          .from('tagihan')
          .select()
          .eq('status_lunas', true)
          .gte('updated_at', start)
          .lte('updated_at', end);
      return response.map((json) => Tagihan.fromJson(json)).toList();
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (fetchTagihanLunasByPeriode): $e');
      return [];
    }
  }

  /// Ambil total pendapatan sewa dan denda di periode
  /// Returns: {pendapatanSewa, pendapatanDenda}
  static Future<Map<String, double>> fetchPendapatanByPeriode(
      DateTime startDate, DateTime endDate) async {
    try {
      // Ambil tagihan yang bulan_tagihan-nya berada di periode
      final startStr = startDate.toIso8601String().split('T')[0];
      final endStr = endDate.toIso8601String().split('T')[0];

      final response = await _client
          .from('tagihan')
          .select(
              'nominal_kamar, total_tagihan, denda_keterlambatan, status_lunas')
          .gte('bulan_tagihan', startStr)
          .lte('bulan_tagihan', endStr);

      double pendapatanSewa = 0;
      double pendapatanDenda = 0;

      for (var row in response) {
        pendapatanSewa += (row['nominal_kamar'] as num).toDouble();
        // Denda = total_tagihan - nominal_kamar (jika positif)
        final denda = (row['total_tagihan'] as num).toDouble() -
            (row['nominal_kamar'] as num).toDouble();
        if (denda > 0) pendapatanDenda += denda;
      }

      return {
        'pendapatanSewa': pendapatanSewa,
        'pendapatanDenda': pendapatanDenda,
      };
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (fetchPendapatanByPeriode): $e');
      return {'pendapatanSewa': 0, 'pendapatanDenda': 0};
    }
  }

  /// Ambil total biaya operasional per kategori di periode
  static Future<Map<String, double>> fetchBiayaByPeriode(
      DateTime startDate, DateTime endDate,
      {String? branchId}) async {
    try {
      final startStr = startDate.toIso8601String().split('T')[0];
      final endStr = endDate.toIso8601String().split('T')[0];

      var query = _client
          .from('biaya_operasional')
          .select('kategori, nominal')
          .isFilter('deleted_at', null)
          .gte('tanggal_transaksi', startStr)
          .lte('tanggal_transaksi', endStr);

      if (branchId != null) {
        query = query.eq('branch_id', branchId);
      }

      final response = await query;
      final Map<String, double> biayaPerKategori = {};

      for (var row in response) {
        final kat = row['kategori'] as String;
        final nom = (row['nominal'] as num).toDouble();
        biayaPerKategori[kat] = (biayaPerKategori[kat] ?? 0) + nom;
      }

      return biayaPerKategori;
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (fetchBiayaByPeriode): $e');
      return {};
    }
  }

  /// Ambil deposit masuk di periode (dari penyewa baru yang created_at di periode)
  static Future<double> fetchDepositMasukByPeriode(
      DateTime startDate, DateTime endDate) async {
    try {
      final start = startDate.toIso8601String();
      final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59)
          .toIso8601String();

      final response = await _client
          .from('penyewa')
          .select('deposit')
          .gte('created_at', start)
          .lte('created_at', end);

      double total = 0;
      for (var row in response) {
        total += (row['deposit'] as num?)?.toDouble() ?? 0;
      }
      return total;
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (fetchDepositMasukByPeriode): $e');
      return 0;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // ── POTONGAN DEPOSIT — Pemotongan Deposit ────────────────────
  // ══════════════════════════════════════════════════════════════

  /// Ambil riwayat pemotongan deposit per penyewa
  static Future<List<PotonganDeposit>> fetchPotonganDeposit(
      String penyewaId) async {
    try {
      final response = await _client
          .from('potongan_deposit')
          .select()
          .eq('id_penyewa', penyewaId)
          .order('tanggal_deduction', ascending: false);
      return response.map((json) => PotonganDeposit.fromJson(json)).toList();
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (fetchPotonganDeposit): $e');
      return [];
    }
  }

  /// Hitung total pemotongan deposit per penyewa
  static Future<double> fetchTotalPotongan(String penyewaId) async {
    try {
      final response = await _client
          .from('potongan_deposit')
          .select('nominal')
          .eq('id_penyewa', penyewaId);
      double total = 0;
      for (var row in response) {
        total += (row['nominal'] as num?)?.toDouble() ?? 0;
      }
      return total;
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (fetchTotalDeduction): $e');
      return 0;
    }
  }

  /// Tambah pemotongan deposit baru
  static Future<void> addPotonganDeposit(Map<String, dynamic> data,
      {String? userId}) async {
    try {
      if (userId != null) data['created_by'] = userId;
      await _client.from('potongan_deposit').insert(data);
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (addPotonganDeposit): $e');
      rethrow;
    }
  }

  /// Hapus pemotongan deposit
  static Future<void> deletePotonganDeposit(String id) async {
    try {
      await _client
          .from('potongan_deposit')
          .delete()
          .eq('id_potongan_deposit', id);
    } catch (e) {
      debugPrint('🔥 ERROR Supabase (deletePotonganDeposit): $e');
      rethrow;
    }
  }
}
