import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../models/kamar_model.dart';
import '../../models/penyewa_model.dart';
import '../../models/tagihan_model.dart';
import '../../models/pembayaran_model.dart';
import 'package:image_picker/image_picker.dart';
import '../tenant/laporan_screen.dart';
import '../../services/notification_service.dart';

/// Dashboard Penyewa
class TenantDashboardScreen extends StatefulWidget {
  const TenantDashboardScreen({super.key});

  @override
  State<TenantDashboardScreen> createState() => _TenantDashboardScreenState();
}

class _TenantDashboardScreenState extends State<TenantDashboardScreen> {
  Penyewa? _penyewa;
  Kamar? _kamar;
  Tagihan? _tagihanAktif;
  bool _isLoadingData = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      auth.addListener(_onAuthChanged);

      _loadTenantData();
    });
  }

  void _onAuthChanged() {
    if (!mounted) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (auth.user == null) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      return;
    }

    //Perubahan penyewa → pemilik/admin
    if (auth.user!.role == 'pemilik' || auth.user!.role == 'admin') {
      Navigator.pushReplacementNamed(context, '/owner-dashboard');
    } else if (auth.user!.role == null || auth.user!.role!.isEmpty) {
      Navigator.pushReplacementNamed(context, '/role-select');
    }
  }

  @override
  void dispose() {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      auth.removeListener(_onAuthChanged);
    } catch (_) {}
    super.dispose();
  }

  /// Load data tenant
  Future<void> _loadTenantData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user == null) return;

    setState(() => _isLoadingData = true);

    try {
      _penyewa = await SupabaseService.fetchPenyewaByUserId(auth.user!.uid);

      if (_penyewa != null) {
        final results = await Future.wait([
          _penyewa!.kamarId != null
              ? SupabaseService.fetchKamarById(_penyewa!.kamarId!)
              : Future.value(null),
          SupabaseService.fetchTagihanAktifByPenyewaId(_penyewa!.id),
        ]);
        _kamar = results[0] as Kamar?;
        _tagihanAktif = results[1] as Tagihan?;

        // Jadwalkan notifikasi jika ada tagihan aktif
        if (_tagihanAktif != null && !_tagihanAktif!.statusLunas) {
          _scheduleReminders(_tagihanAktif!.jatuhTempo);
        }
      }
    } catch (e) {
      debugPrint('🔥 Error loading tenant data: $e');
    }

    if (mounted) setState(() => _isLoadingData = false);
  }

  /// Menjadwalkan reminder H-14 dan H-1
  Future<void> _scheduleReminders(DateTime jatuhTempo) async {
    final h14 = jatuhTempo.subtract(const Duration(days: 14));
    final h1 = jatuhTempo.subtract(const Duration(days: 1));
    final now = DateTime.now();

    if (h14.isAfter(now)) {
      await NotificationService().scheduleReminder(
        id: 114,
        title: 'Reminder Tagihan Kos',
        body: 'Tagihan Anda akan jatuh tempo dalam 14 hari.',
        scheduledDate: h14,
      );
    }

    if (h1.isAfter(now)) {
      await NotificationService().scheduleReminder(
        id: 101,
        title: 'Besok Jatuh Tempo!',
        body: 'Jangan lupa bayar tagihan kos Anda agar terhindar dari denda.',
        scheduledDate: h1,
      );
    }
  }

  /// Handle pull-to-refresh
  Future<void> _handleRefresh() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.refreshUserData();
    await _loadTenantData();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Penyewa'),
        backgroundColor: AppColors.secondary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppColors.secondary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Welcome Card ─────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.secondaryLight,
                      AppColors.secondary,
                      AppColors.secondaryDark,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          backgroundImage: auth.user?.photoUrl != null
                              ? NetworkImage(auth.user!.photoUrl!)
                              : null,
                          child: auth.user?.photoUrl == null
                              ? const Icon(Icons.person, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selamat Datang! 👋',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                auth.user?.displayName ?? 'Penyewa',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '🔑 Role: ${auth.user?.role == 'penyewa' ? 'Penyewa' : auth.user?.role ?? 'Belum dipilih'}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Quick Info (Placeholder) ─────────────────
              Text('Info Kamar Anda', style: AppTextStyles.h3),
              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadowLight,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.meeting_room_rounded,
                      label: 'Nomor Kamar',
                      value: _isLoadingData
                          ? '...'
                          : _kamar?.nomorKamar ?? 'Belum ada',
                    ),
                    const Divider(height: 24),
                    _InfoRow(
                      icon: Icons.calendar_month_rounded,
                      label: 'Jatuh Tempo',
                      value: _isLoadingData
                          ? '...'
                          : _tagihanAktif != null
                              ? DateFormat('dd MMM yyyy')
                                  .format(_tagihanAktif!.jatuhTempo)
                              : 'Tidak ada',
                    ),
                    const Divider(height: 24),
                    _InfoRow(
                      icon: Icons.payments_rounded,
                      label: 'Status Pembayaran',
                      value: _isLoadingData
                          ? '...'
                          : _tagihanAktif != null
                              ? (_tagihanAktif!.statusLunas
                                  ? 'Lunas \u2705'
                                  : (_tagihanAktif!.isMenunggak
                                      ? 'Menunggak \u26a0\ufe0f'
                                      : 'Belum Lunas'))
                              : 'Tidak ada tagihan',
                    ),
                    // ── Rincian Tagihan + Denda ──
                    if (!_isLoadingData &&
                        _tagihanAktif != null &&
                        !_tagihanAktif!.statusLunas) ...[
                      const Divider(height: 24),
                      _InfoRow(
                        icon: Icons.receipt_long_rounded,
                        label: 'Total Tagihan',
                        value: NumberFormat.currency(
                                locale: 'id_ID',
                                symbol: 'Rp ',
                                decimalDigits: 0)
                            .format(_tagihanAktif!.totalBerjalan),
                      ),
                      if (_tagihanAktif!.dendaPerHari > 0 &&
                          _tagihanAktif!.overdueDays > 0) ...[
                        const Divider(height: 24),
                        _InfoRow(
                          icon: Icons.warning_amber_rounded,
                          label: 'Denda',
                          value: NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(_tagihanAktif!.totalAkumulasiDenda),
                          subtitle: '${_tagihanAktif!.overdueDays} hr × ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(_tagihanAktif!.dendaPerHari)}',
                        ),
                      ],
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Upload Bukti Bayar ──────────────────────────
              if (_tagihanAktif != null && !_tagihanAktif!.statusLunas) ...[
                _buildUploadSection(),
                const SizedBox(height: 12),
              ],

              const SizedBox(height: 12),

              // ── Sync Info ──────────────────────────────────
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.secondary.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.sync_rounded,
                      size: 18,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Data sinkron otomatis • Tarik ke bawah untuk refresh',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.secondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Info Deposit & Harga Sewa ──────────────────
              Text('Info Keuangan', style: AppTextStyles.h3),
              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadowLight,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.payments_rounded,
                      label: 'Harga Sewa',
                      value: _isLoadingData
                          ? '...'
                          : _kamar != null
                              ? NumberFormat.currency(
                                      locale: 'id_ID',
                                      symbol: 'Rp ',
                                      decimalDigits: 0)
                                  .format(_kamar!.hargaPerBulan)
                              : 'Belum ada',
                    ),
                    const Divider(height: 24),
                    _InfoRow(
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'Deposit',
                      value: _isLoadingData
                          ? '...'
                          : _penyewa != null && _penyewa!.deposit > 0
                              ? NumberFormat.currency(
                                      locale: 'id_ID',
                                      symbol: 'Rp ',
                                      decimalDigits: 0)
                                  .format(_penyewa!.depositSisa)
                              : 'Tidak ada',
                      subtitle: (_penyewa != null && _penyewa!.hasDeduction)
                          ? 'Lihat riwayat pemotongan'
                          : null,
                      onTap: (_penyewa != null && _penyewa!.hasDeduction)
                          ? () => _showDepositHistorySheet(_penyewa!)
                          : null,
                    ),
                    const Divider(height: 24),
                    _InfoRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'Tanggal Masuk',
                      value: _isLoadingData
                          ? '...'
                          : _penyewa != null
                              ? DateFormat('dd MMM yyyy', 'id_ID')
                                  .format(_penyewa!.tanggalMasuk)
                              : 'Belum ada',
                    ),
                    if (_penyewa?.nomorWhatsapp != null &&
                        _penyewa!.nomorWhatsapp!.isNotEmpty) ...[
                      const Divider(height: 24),
                      _InfoRow(
                        icon: Icons.phone_rounded,
                        label: 'WhatsApp',
                        value: _penyewa!.nomorWhatsapp!,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LaporanScreen()),
                    );
                  },
                  icon: const Icon(Icons.report_problem_rounded),
                  label: const Text('Buat Laporan / Keluhan'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signOut();
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  // ── Upload Bukti Bayar Section ────────────────────────

  Widget _buildUploadSection() {
    return FutureBuilder<List<Pembayaran>>(
      future: _tagihanAktif != null
          ? SupabaseService.fetchPembayaranByTagihanId(_tagihanAktif!.id)
          : Future.value([]),
      builder: (context, snapshot) {
        final pembayaranList = snapshot.data ?? [];
        Pembayaran? latest;
        for (final p in pembayaranList) {
          if (p.statusValidasi != 'ditolak') {
            latest = p;
            break;
          }
        }

        if (latest != null && latest.statusValidasi == 'pending') {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.hourglass_top_rounded,
                    size: 20, color: Colors.orange[700]),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Bukti bayar terkirim. Menunggu verifikasi pemilik.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.orange[800],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (latest != null && latest.statusValidasi == 'valid') {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (latest != null && latest.statusValidasi == 'ditolak')
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.statusMenunggak.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.statusMenunggak.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 18, color: AppColors.statusMenunggak),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bukti bayar sebelumnya ditolak. Silakan upload ulang.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.statusMenunggak,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.upload_file_rounded, size: 20),
                label: const Text('Upload Bukti Bayar'),
                onPressed: () => _showUploadSheet(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showUploadSheet() {
    File? selectedFile;
    String selectedMetode = 'Transfer Bank';
    final metodeList = ['Transfer Bank', 'E-Wallet', 'QRIS', 'Tunai'];
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Upload Bukti Bayar', style: AppTextStyles.h3),
                const SizedBox(height: 20),

                // ── Nominal (auto) ──
                Text('Nominal',
                    style: AppTextStyles.bodySmall
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.scaffoldBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    NumberFormat.currency(
                            locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
                        .format(_tagihanAktif!.totalBerjalan),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 14),

                // ── Metode ──
                Text('Metode Pembayaran',
                    style: AppTextStyles.bodySmall
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.scaffoldBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedMetode,
                      isExpanded: true,
                      items: metodeList
                          .map(
                              (m) => DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setSheetState(() => selectedMetode = val);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ── Upload Foto ──
                Text('Foto Bukti Bayar *',
                    style: AppTextStyles.bodySmall
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 1200,
                      imageQuality: 80,
                    );
                    if (picked != null) {
                      setSheetState(() => selectedFile = File(picked.path));
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: selectedFile != null ? 200 : 120,
                    decoration: BoxDecoration(
                      color: AppColors.scaffoldBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.border, style: BorderStyle.solid),
                    ),
                    child: selectedFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(selectedFile!, fit: BoxFit.cover),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_upload_outlined,
                                  size: 36, color: AppColors.textHint),
                              const SizedBox(height: 8),
                              Text('Tap untuk pilih gambar',
                                  style: AppTextStyles.bodySmall
                                      .copyWith(color: AppColors.textHint)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Submit ──
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isUploading
                        ? null
                        : () async {
                            if (selectedFile == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Pilih foto bukti bayar terlebih dahulu'),
                                  backgroundColor: AppColors.statusMenunggak,
                                ),
                              );
                              return;
                            }
                            setSheetState(() => isUploading = true);
                            await _submitPembayaran(
                                selectedFile!, selectedMetode);
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isUploading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Kirim Bukti Bayar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitPembayaran(File file, String metode) async {
    try {
      final url =
          await SupabaseService.uploadBuktiBayar(file, _tagihanAktif!.id);
      if (url == null) throw Exception('Upload gagal');

      await SupabaseService.addPembayaran({
        'tagihan_id': _tagihanAktif!.id,
        'tanggal_bayar': DateTime.now().toIso8601String().split('T')[0],
        'nominal_dibayar': _tagihanAktif!.totalBerjalan,
        'metode_pembayaran': metode,
        'bukti_foto_url': url,
        'status_validasi': 'pending',
      });

      await _loadTenantData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bukti bayar terkirim! Menunggu verifikasi pemilik.'),
            backgroundColor: AppColors.statusLunas,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal upload: $e'),
            backgroundColor: AppColors.statusMenunggak,
          ),
        );
      }
    }
  }

  void _showDepositHistorySheet(Penyewa penyewa) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DepositHistorySheet(penyewa: penyewa),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final VoidCallback? onTap;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Row(
      crossAxisAlignment: subtitle != null || label.length > 15
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        BoxedIcon(icon: icon),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: EdgeInsets.only(top: subtitle != null ? 0 : 0),
                      child: Text(label, style: AppTextStyles.bodyMedium),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Text(
                      value,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.labelLarge
                          .copyWith(fontSize: 15, height: 1.3),
                    ),
                  ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: onTap != null ? AppColors.statusPending : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: onTap != null ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (onTap != null) ...[
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 20),
        ],
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
          child: content,
        ),
      );
    }
    
    return content;
  }
}

class BoxedIcon extends StatelessWidget {
  final IconData icon;
  const BoxedIcon({super.key, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 20, color: AppColors.secondary),
    );
  }
}

class _DepositHistorySheet extends StatefulWidget {
  final Penyewa penyewa;
  const _DepositHistorySheet({required this.penyewa});

  @override
  State<_DepositHistorySheet> createState() => _DepositHistorySheetState();
}

class _DepositHistorySheetState extends State<_DepositHistorySheet> {
  bool _isLoading = true;
  List<dynamic> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final data = await SupabaseService.fetchPotonganDeposit(widget.penyewa.id);
      if (mounted) {
        setState(() {
          _history = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFmt = DateFormat('dd MMM yyyy', 'id_ID');

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Riwayat Pemotongan Deposit', style: AppTextStyles.h3),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
          else if (_history.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text('Tidak ada riwayat pemotongan.', style: AppTextStyles.bodyMedium),
              ),
            )
          else ...[
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _history.length,
                itemBuilder: (context, index) {
                  final item = _history[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.statusMenunggak.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.statusMenunggak.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              dateFmt.format(item.tanggalDeduction),
                              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                            ),
                            Text(
                              '- ${fmt.format(item.nominal)}',
                              style: const TextStyle(
                                  color: AppColors.statusMenunggak,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(item.alasan, style: AppTextStyles.bodySmall.copyWith(fontSize: 13, height: 1.4)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

//   final IconData icon;
//   final String label;
//   final String value;

//   const _InfoRow({
//     required this.icon,
//     required this.label,
//     required this.value,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Container(
//           width: 40,
//           height: 40,
//           decoration: BoxDecoration(
//             color: AppColors.secondary.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: Icon(icon, size: 20, color: AppColors.secondary),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: Text(label, style: AppTextStyles.bodyMedium),
//         ),
//         Text(
//           value,
//           style: AppTextStyles.labelLarge.copyWith(fontSize: 15),
//         ),
//       ],
//     );
//   }
// }
