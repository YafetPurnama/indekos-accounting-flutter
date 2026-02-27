import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/tagihan_model.dart';
import '../../models/pembayaran_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';

/// CRUD Tagihan per Penyewa
class TagihanScreen extends StatefulWidget {
  final String penyewaId;
  final String? namaUser;
  final String? nomorKamar;
  final double? hargaKamar;
  final bool readOnly;

  const TagihanScreen({
    super.key,
    required this.penyewaId,
    this.namaUser,
    this.nomorKamar,
    this.hargaKamar,
    this.readOnly = false,
  });

  @override
  State<TagihanScreen> createState() => _TagihanScreenState();
}

class _TagihanScreenState extends State<TagihanScreen> {
  List<Tagihan> _list = [];
  bool _isLoading = false;
  double _defaultHargaKamar = 0;

  String get _currentUserId =>
      Provider.of<AuthProvider>(context, listen: false).user?.uid ?? '';

  final _currFmt =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final _dateFmt = DateFormat('MMMM yyyy', 'id_ID');
  final _dayFmt = DateFormat('dd MMM yyyy', 'id_ID');

  @override
  void initState() {
    super.initState();
    _defaultHargaKamar = widget.hargaKamar ?? 0;
    _loadData();
    _fetchHargaKamar();
  }

  Future<void> _fetchHargaKamar() async {
    if (widget.hargaKamar != null) return;
    try {
      final listPenyewa = await SupabaseService.fetchPenyewaList();
      final p = listPenyewa.firstWhere((e) => e.id == widget.penyewaId);
      if (p.kamarId != null) {
        final k = await SupabaseService.fetchKamarById(p.kamarId!);
        if (k != null && mounted) {
          setState(() {
            _defaultHargaKamar = k.hargaPerBulan;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final list =
        await SupabaseService.fetchTagihanListByPenyewaId(widget.penyewaId);
    if (mounted) {
      setState(() {
        _list = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _list.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: _list.length,
                    itemBuilder: (_, i) => _buildCard(_list[i]),
                  ),
      ),
      floatingActionButton: widget.readOnly
          ? null
          : FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: () => _showFormSheet(context),
              child:
                  const Icon(Icons.receipt_long_rounded, color: Colors.white),
            ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Center(
          child: Column(
            children: [
              Icon(Icons.receipt_long_outlined,
                  size: 64, color: AppColors.textHint),
              const SizedBox(height: 12),
              Text('Belum ada tagihan',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary)),
              if (!widget.readOnly) ...[
                const SizedBox(height: 4),
                Text('Tap + untuk buat tagihan baru',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textHint, fontSize: 12)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Card ────────────────────────────────────────────────────

  Widget _buildCard(Tagihan t) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (t.statusLunas) {
      statusColor = AppColors.statusLunas;
      statusText = 'Lunas';
      statusIcon = Icons.check_circle_rounded;
    } else if (t.isMenunggak) {
      statusColor = AppColors.statusMenunggak;
      statusText = 'Menunggak';
      statusIcon = Icons.warning_rounded;
    } else {
      statusColor = AppColors.statusPending;
      statusText = 'Pending';
      statusIcon = Icons.schedule_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 8,
              offset: Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.readOnly ? null : () => _showDetailSheet(t),
          onLongPress: widget.readOnly
              ? null
              : () => _showFormSheet(context, tagihan: t),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Status icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 24),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_dateFmt.format(t.bulanTagihan),
                          style:
                              AppTextStyles.labelLarge.copyWith(fontSize: 15)),
                      const SizedBox(height: 3),
                      Text(_currFmt.format(t.totalBerjalan),
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.event_rounded,
                              size: 11, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          Text('Jatuh tempo: ${_dayFmt.format(t.jatuhTempo)}',
                              style: AppTextStyles.bodySmall.copyWith(
                                  fontSize: 11, color: AppColors.textHint)),
                        ],
                      ),
                      if (t.dendaPerHari > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                            'Denda (${_currFmt.format(t.dendaPerHari)}/hr): ${_currFmt.format(t.totalAkumulasiDenda)}',
                            style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 11,
                                color: AppColors.statusMenunggak)),
                      ],
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Detail Sheet (review pembayaran) ──────────────────────

  void _showDetailSheet(Tagihan t) async {
    // Fetch pembayaran terkait tagihan ini
    final pembayaranList =
        await SupabaseService.fetchPembayaranByTagihanId(t.id);

    // Cari pembayaran terbaru yang bukan ditolak
    Pembayaran? latestPembayaran;
    for (final p in pembayaranList) {
      if (p.statusValidasi != 'ditolak') {
        latestPembayaran = p;
        break;
      }
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
        ),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
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
              const SizedBox(height: 16),

              // ── Header ──
              Row(
                children: [
                  Expanded(
                    child: Text('Detail Tagihan', style: AppTextStyles.h3),
                  ),
                  // Edit button
                  IconButton(
                    icon: Icon(Icons.edit_rounded,
                        color: AppColors.primary, size: 22),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showFormSheet(context, tagihan: t);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Info Tagihan ──
              _detailRow('Bulan', _dateFmt.format(t.bulanTagihan)),
              _detailRow('Nominal', _currFmt.format(t.nominalKamar)),
              if (t.dendaPerHari > 0)
                _detailRow('Denda (${_currFmt.format(t.dendaPerHari)}/hr)',
                    _currFmt.format(t.totalAkumulasiDenda)),
              _detailRow('Total', _currFmt.format(t.totalBerjalan)),
              _detailRow('Jatuh Tempo', _dayFmt.format(t.jatuhTempo)),
              _detailRow(
                'Status',
                t.statusLunas
                    ? 'Lunas ✅'
                    : t.isMenunggak
                        ? 'Menunggak ⚠️'
                        : 'Pending',
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),

              // ── Bukti Pembayaran ──
              Text('Bukti Pembayaran',
                  style: AppTextStyles.labelLarge.copyWith(fontSize: 15)),
              const SizedBox(height: 12),

              if (latestPembayaran == null) ...[
                // Belum ada bukti bayar
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.scaffoldBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 40, color: AppColors.textHint),
                      const SizedBox(height: 8),
                      Text('Belum ada bukti bayar dari penyewa',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textHint)),
                    ],
                  ),
                ),
              ] else ...[
                // ── Info pembayaran ──
                if (latestPembayaran.metodePembayaran != null)
                  _detailRow('Metode', latestPembayaran.metodePembayaran!),
                _detailRow('Nominal Dibayar',
                    _currFmt.format(latestPembayaran.nominalDibayar)),
                if (latestPembayaran.tanggalBayar != null)
                  _detailRow('Tanggal Bayar',
                      _dayFmt.format(latestPembayaran.tanggalBayar!)),
                _detailRow('Status Validasi',
                    latestPembayaran.statusValidasi.toUpperCase()),
                const SizedBox(height: 12),

                // ── Gambar bukti ──
                if (latestPembayaran.buktiFotoUrl != null &&
                    latestPembayaran.buktiFotoUrl!.isNotEmpty)
                  GestureDetector(
                    onTap: () =>
                        _showImageViewer(latestPembayaran!.buktiFotoUrl!),
                    child: Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          latestPembayaran.buktiFotoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image,
                                    color: AppColors.textHint),
                                const SizedBox(height: 4),
                                Text('Gagal memuat gambar',
                                    style: AppTextStyles.bodySmall
                                        .copyWith(color: AppColors.textHint)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                if (latestPembayaran.buktiFotoUrl != null)
                  Text('Tap gambar untuk memperbesar',
                      style: AppTextStyles.bodySmall
                          .copyWith(fontSize: 10, color: AppColors.textHint)),
                const SizedBox(height: 16),

                // ── Approve / Reject buttons ──
                if (latestPembayaran.statusValidasi == 'pending') ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: const Text('Tolak'),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await _handleValidation(
                                latestPembayaran!, t, 'ditolak');
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.statusMenunggak,
                            side: const BorderSide(
                                color: AppColors.statusMenunggak),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Setujui & Lunas'),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await _handleValidation(
                                latestPembayaran!, t, 'valid');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.statusLunas,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (latestPembayaran.statusValidasi == 'valid') ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.statusLunas.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_rounded,
                            color: AppColors.statusLunas, size: 20),
                        const SizedBox(width: 8),
                        Text('Pembayaran sudah diverifikasi',
                            style: TextStyle(
                                color: AppColors.statusLunas,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.statusMenunggak.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cancel_rounded,
                            color: AppColors.statusMenunggak, size: 20),
                        const SizedBox(width: 8),
                        Text('Bukti bayar ditolak',
                            style: TextStyle(
                                color: AppColors.statusMenunggak,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: AppTextStyles.bodySmall
                    .copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleValidation(
      Pembayaran p, Tagihan t, String newStatus) async {
    try {
      await SupabaseService.updatePembayaran(
          p.id, {'status_validasi': newStatus});

      // Jika valid → auto update tagihan ke lunas dan beku/simpan totalAkhir
      if (newStatus == 'valid') {
        await SupabaseService.updateTagihan(
          t.id,
          {
            'status_lunas': true,
            'total_tagihan': t.totalBerjalan,
          },
          userId: _currentUserId,
        );
      }

      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus == 'valid'
                ? 'Pembayaran disetujui — tagihan LUNAS ✅'
                : 'Bukti bayar ditolak. Penyewa bisa upload ulang.'),
            backgroundColor: newStatus == 'valid'
                ? AppColors.statusLunas
                : AppColors.statusMenunggak,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal: $e'),
              backgroundColor: AppColors.statusMenunggak),
        );
      }
    }
  }

  void _showImageViewer(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: InteractiveViewer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(url, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  // ── Form ───────────────────────────────────────────────────

  void _showFormSheet(BuildContext context, {Tagihan? tagihan}) {
    final isEdit = tagihan != null;
    DateTime selectedMonth = tagihan?.bulanTagihan ??
        DateTime(DateTime.now().year, DateTime.now().month, 1);
    DateTime selectedJatuhTempo = tagihan?.jatuhTempo ??
        DateTime(DateTime.now().year, DateTime.now().month, 10);

    // Gunakan harga kamar dari penyewa jika baru buat tagihan,
    // Jika edit, gunakan nominal yang sudah ada di tagihan.
    final double defaultNominal =
        isEdit ? tagihan.nominalKamar : _defaultHargaKamar;

    final dendaCtrl = TextEditingController(
      text: tagihan != null && tagihan.dendaPerHari > 0
          ? _ThousandFmt.format(tagihan.dendaPerHari.toStringAsFixed(0))
          : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final nominal = defaultNominal;
          final denda = double.tryParse(
                  dendaCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
              0;
          final total = nominal + denda;

          return Container(
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
                  Text(isEdit ? 'Edit Tagihan' : 'Buat Tagihan',
                      style: AppTextStyles.h3),
                  const SizedBox(height: 20),

                  // ── Bulan ──
                  Text('Bulan Tagihan *',
                      style: AppTextStyles.bodySmall
                          .copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedMonth,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setSheetState(() => selectedMonth =
                            DateTime(picked.year, picked.month, 1));
                      }
                    },
                    child: _dateBox(_dateFmt.format(selectedMonth)),
                  ),
                  const SizedBox(height: 14),

                  // ── Nominal ──
                  Text('Nominal Kamar',
                      style: AppTextStyles.bodySmall
                          .copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.scaffoldBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(_currFmt.format(defaultNominal),
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(height: 14),

                  // ── Denda ──
                  _buildAmountField('Denda per Hari', dendaCtrl, setSheetState),
                  const SizedBox(height: 10),

                  // ── Total ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Tagihan',
                            style: AppTextStyles.bodySmall
                                .copyWith(fontWeight: FontWeight.w600)),
                        Text(_currFmt.format(total),
                            style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.primary, fontSize: 16)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Jatuh Tempo ──
                  Text('Jatuh Tempo *',
                      style: AppTextStyles.bodySmall
                          .copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedJatuhTempo,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setSheetState(() => selectedJatuhTempo = picked);
                      }
                    },
                    child: _dateBox(_dayFmt.format(selectedJatuhTempo)),
                  ),
                  const SizedBox(height: 24),

                  // ── Buttons ──
                  Row(
                    children: [
                      if (isEdit)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _confirmDelete(tagihan);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.statusMenunggak,
                              side: const BorderSide(
                                  color: AppColors.statusMenunggak),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Hapus'),
                          ),
                        ),
                      if (isEdit) const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () => _saveTagihan(
                            ctx,
                            selectedMonth,
                            defaultNominal,
                            dendaCtrl.text,
                            selectedJatuhTempo,
                            editId: tagihan?.id,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(isEdit ? 'Simpan' : 'Buat Tagihan'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _dateBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_rounded,
              size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildAmountField(
      String label, TextEditingController ctrl, StateSetter setSheetState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 14),
          inputFormatters: [_ThousandInputFormatter()],
          onChanged: (_) => setSheetState(() {}),
          decoration: InputDecoration(
            hintText: '0',
            prefixText: 'Rp ',
            hintStyle: TextStyle(color: AppColors.textHint, fontSize: 13),
            filled: true,
            fillColor: AppColors.scaffoldBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }

  // ── Save ────────────────────────────────────────────────────

  Future<void> _saveTagihan(BuildContext ctx, DateTime bulan, double nominal,
      String dendaStr, DateTime jatuhTempo,
      {String? editId}) async {
    if (nominal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Kamar penyewa ini belum memiliki harga sewa.'),
            backgroundColor: AppColors.statusMenunggak),
      );
      return;
    }

    Navigator.pop(ctx);
    final denda =
        double.tryParse(dendaStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    final data = <String, dynamic>{
      'penyewa_id': widget.penyewaId,
      'bulan_tagihan': bulan.toIso8601String().split('T')[0],
      'nominal_kamar': nominal,
      'denda_keterlambatan': denda,
      'total_tagihan': nominal + denda,
      'jatuh_tempo': jatuhTempo.toIso8601String().split('T')[0],
    };

    try {
      if (editId != null) {
        await SupabaseService.updateTagihan(editId, data,
            userId: _currentUserId);
      } else {
        await SupabaseService.addTagihan(data, userId: _currentUserId);
      }
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(editId != null ? 'Tagihan diperbarui' : 'Tagihan dibuat'),
            backgroundColor: AppColors.statusLunas,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal: $e'),
              backgroundColor: AppColors.statusMenunggak),
        );
      }
    }
  }

  // ── Delete ──────────────────────────────────────────────────

  void _confirmDelete(Tagihan t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Tagihan'),
        content: Text(
            'Yakin hapus tagihan bulan ${_dateFmt.format(t.bulanTagihan)}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await SupabaseService.deleteTagihan(t.id,
                    userId: _currentUserId);
                _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Tagihan dihapus'),
                        backgroundColor: AppColors.statusPending),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Gagal: $e'),
                        backgroundColor: AppColors.statusMenunggak),
                  );
                }
              }
            },
            child: const Text('Hapus',
                style: TextStyle(color: AppColors.statusMenunggak)),
          ),
        ],
      ),
    );
  }
}

// ── Thousand separator helpers ──────────────────────────────

class _ThousandFmt {
  static String format(String val) {
    final n = val.replaceAll(RegExp(r'[^0-9]'), '');
    if (n.isEmpty) return '';
    final f =
        NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0);
    return f.format(int.parse(n)).trim();
  }
}

class _ThousandInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue newVal) {
    final text = _ThousandFmt.format(newVal.text);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
