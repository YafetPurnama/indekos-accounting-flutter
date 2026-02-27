import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/penyewa_model.dart';
import '../../models/potongan_deposit_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';

/// Halaman detail & management deposit per penyewa.
class DepositManagementScreen extends StatefulWidget {
  final Penyewa penyewa;
  const DepositManagementScreen({super.key, required this.penyewa});

  @override
  State<DepositManagementScreen> createState() =>
      _DepositManagementScreenState();
}

class _DepositManagementScreenState extends State<DepositManagementScreen> {
  List<PotonganDeposit> _deductions = [];
  bool _isLoading = false;
  double _totalDeduction = 0;

  final _formatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final _dateFormatter = DateFormat('dd MMM yyyy', 'id_ID');

  String get _currentUserId =>
      Provider.of<AuthProvider>(context, listen: false).user?.uid ?? '';

  double get _depositAwal => widget.penyewa.deposit;
  double get _depositSisa => _depositAwal - _totalDeduction;

  String get _statusLabel {
    if (_totalDeduction <= 0) return 'Refund (Utuh)';
    if (_depositSisa > 0) return 'Deducted (Sebagian)';
    return 'Forfeited (Hangus)';
  }

  Color get _statusColor {
    if (_totalDeduction <= 0) return AppColors.statusLunas;
    if (_depositSisa > 0) return AppColors.statusPending;
    return AppColors.statusMenunggak;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final deductions =
          await SupabaseService.fetchPotonganDeposit(widget.penyewa.id);
      final total =
          await SupabaseService.fetchTotalPotongan(widget.penyewa.id);
      if (mounted) {
        setState(() {
          _deductions = deductions;
          _totalDeduction = total;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Management Deposit'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      backgroundColor: AppColors.scaffoldBackground,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildPenyewaInfo(),
                  const SizedBox(height: 16),
                  _buildDepositSummary(),
                  const SizedBox(height: 20),
                  _buildDeductionHeader(),
                  const SizedBox(height: 10),
                  if (_deductions.isEmpty)
                    _buildEmptyDeduction()
                  else
                    ..._deductions.map(_buildDeductionCard),
                  const SizedBox(height: 80),
                ],
              ),
      ),
      floatingActionButton: _depositSisa > 0
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.statusMenunggak,
              icon: const Icon(Icons.remove_circle_outline, color: Colors.white),
              label: const Text('Potong Deposit',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              onPressed: () => _showAddDeductionSheet(context),
            )
          : null,
    );
  }

  // ── Penyewa Info ────────────────────────────────────────────

  Widget _buildPenyewaInfo() {
    final p = widget.penyewa;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              (p.namaUser ?? 'P')[0].toUpperCase(),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.namaUser ?? 'Penyewa',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                if (p.nomorKamar != null)
                  Text(
                    'Kamar ${p.nomorKamar}${p.namaBranch != null ? ' · ${p.namaBranch}' : ''}',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8), fontSize: 12),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _statusColor.withOpacity(0.5)),
            ),
            child: Text(
              _statusLabel,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ── Deposit Summary Card ───────────────────────────────────

  Widget _buildDepositSummary() {
    final progress =
        _depositAwal > 0 ? (_depositSisa / _depositAwal).clamp(0.0, 1.0) : 1.0;

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ringkasan Deposit',
              style: AppTextStyles.labelLarge.copyWith(fontSize: 15)),
          const SizedBox(height: 16),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: AppColors.statusMenunggak.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(
                _depositSisa > 0
                    ? (_depositSisa == _depositAwal
                        ? AppColors.statusLunas
                        : AppColors.statusPending)
                    : AppColors.statusMenunggak,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Amounts
          Row(
            children: [
              _summaryItem('Deposit Awal', _depositAwal, AppColors.primary),
              _summaryItem(
                  'Total Potongan', _totalDeduction, AppColors.statusMenunggak),
              _summaryItem('Sisa Deposit', _depositSisa, _statusColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, double amount, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: AppTextStyles.bodySmall
                  .copyWith(fontSize: 10, color: AppColors.textHint),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(
            _formatter.format(amount),
            style: TextStyle(
                color: color, fontSize: 13, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Deduction List Header ──────────────────────────────────

  Widget _buildDeductionHeader() {
    return Row(
      children: [
        Icon(Icons.receipt_long_rounded, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text('Riwayat Pemotongan',
            style: AppTextStyles.labelLarge.copyWith(fontSize: 14)),
        const Spacer(),
        Text('${_deductions.length} record',
            style: AppTextStyles.bodySmall
                .copyWith(fontSize: 11, color: AppColors.textHint)),
      ],
    );
  }

  Widget _buildEmptyDeduction() {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.check_circle_outline_rounded,
              size: 48, color: AppColors.statusLunas.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text('Tidak ada pemotongan',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text('Deposit penyewa masih utuh',
              style: AppTextStyles.bodySmall
                  .copyWith(fontSize: 11, color: AppColors.textHint)),
        ],
      ),
    );
  }

  // ── Deduction Card ─────────────────────────────────────────

  Widget _buildDeductionCard(PotonganDeposit d) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.statusMenunggak.withOpacity(0.15)),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 4,
              offset: Offset(0, 1)),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.statusMenunggak.withOpacity(0.1),
          child: const Icon(Icons.remove_circle_rounded,
              color: AppColors.statusMenunggak, size: 20),
        ),
        title: Text(
          '- ${_formatter.format(d.nominal)}',
          style: const TextStyle(
              color: AppColors.statusMenunggak,
              fontWeight: FontWeight.w700,
              fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(d.alasan,
                style: AppTextStyles.bodySmall.copyWith(fontSize: 12)),
            const SizedBox(height: 2),
            Text(_dateFormatter.format(d.tanggalDeduction),
                style: AppTextStyles.caption.copyWith(fontSize: 10)),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline_rounded,
              color: AppColors.textHint, size: 20),
          onPressed: () => _confirmDeleteDeduction(d),
        ),
      ),
    );
  }

  // ── Add Deduction Bottom Sheet ─────────────────────────────

  void _showAddDeductionSheet(BuildContext context) {
    final nominalCtrl = TextEditingController();
    final alasanCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

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
                Text('Tambah Pemotongan Deposit',
                    style: AppTextStyles.h3.copyWith(fontSize: 18)),
                const SizedBox(height: 4),
                Text(
                  'Sisa deposit: ${_formatter.format(_depositSisa)}',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.statusPending,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),

                // Nominal
                Text('Nominal Pemotongan *',
                    style: AppTextStyles.bodySmall
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: nominalCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 14),
                  inputFormatters: [_ThousandInputFormatter()],
                  decoration: InputDecoration(
                    hintText: '0',
                    prefixText: 'Rp ',
                    hintStyle:
                        TextStyle(color: AppColors.textHint, fontSize: 13),
                    filled: true,
                    fillColor: AppColors.scaffoldBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                  ),
                ),
                const SizedBox(height: 14),

                // Alasan
                Text('Alasan Pemotongan *',
                    style: AppTextStyles.bodySmall
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: alasanCtrl,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText:
                        'Contoh: Kerusakan pintu kamar, AC bocor, dll.',
                    hintStyle:
                        TextStyle(color: AppColors.textHint, fontSize: 12),
                    filled: true,
                    fillColor: AppColors.scaffoldBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                  ),
                ),
                const SizedBox(height: 14),

                // Tanggal
                Text('Tanggal Pemotongan',
                    style: AppTextStyles.bodySmall
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setSheetState(() => selectedDate = picked);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.scaffoldBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 10),
                        Text(
                          DateFormat('dd MMMM yyyy', 'id_ID')
                              .format(selectedDate),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Button Simpan
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _saveDeduction(
                      ctx,
                      nominalCtrl.text,
                      alasanCtrl.text,
                      selectedDate,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.statusMenunggak,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Simpan Pemotongan',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Save Deduction ─────────────────────────────────────────

  Future<void> _saveDeduction(
    BuildContext ctx,
    String nominalStr,
    String alasan,
    DateTime tanggal,
  ) async {
    final nominal =
        double.tryParse(nominalStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    if (nominal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Nominal pemotongan harus > 0'),
            backgroundColor: AppColors.statusMenunggak),
      );
      return;
    }

    if (nominal > _depositSisa) {
      if (alasan.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Alasan pemotongan wajib diisi'),
              backgroundColor: AppColors.statusMenunggak),
        );
        return;
      }

      final excess = nominal - _depositSisa;
      final confirm = await showDialog<bool>(
        context: ctx,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Pemotongan Melebihi Deposit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: Text(
            'Bahwa "${widget.penyewa.namaUser ?? 'Penyewa'}" telah menyebabkan kerusakan "$alasan" melebihi total deposit, sehingga sisa ${_formatter.format(excess)} akan dibebankan di bulan berikutnya beserta uang bulanan sewa kos.',
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusMenunggak,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: const Text('Lanjutkan'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      if (!mounted) return;
      Navigator.pop(ctx);
      
      setState(() => _isLoading = true);
      try {
        if (_depositSisa > 0) {
          await SupabaseService.addPotonganDeposit({
            'id_penyewa': widget.penyewa.id,
            'nominal': _depositSisa,
            'alasan': '${alasan.trim()} (Sisa ${_formatter.format(excess)} dibebankan ke tagihan berikutnya)',
            'tanggal_deduction': tanggal.toIso8601String().split('T')[0],
          }, userId: _currentUserId);
        }

        final now = DateTime.now();
        final nextMonthStr = DateTime(now.year, now.month + 1, 1).toIso8601String().split('T')[0];
        
        final listTagihan = await SupabaseService.fetchTagihanListByPenyewaId(widget.penyewa.id);
        final tagihanNext = listTagihan.where((t) => t.bulanTagihan.toIso8601String().startsWith(nextMonthStr)).firstOrNull;

        if (tagihanNext != null) {
          final newNominal = tagihanNext.nominalKamar + excess;
          final newTotal = tagihanNext.totalTagihan + excess;
          await SupabaseService.updateTagihan(tagihanNext.id, {
            'nominal_kamar': newNominal,
            'total_tagihan': newTotal,
          }, userId: _currentUserId);
        } else {
          double hargaKamar = 0;
          if (widget.penyewa.kamarId != null) {
            final k = await SupabaseService.fetchKamarById(widget.penyewa.kamarId!);
            if (k != null) hargaKamar = k.hargaPerBulan;
          }
          final totalBayar = hargaKamar + excess;
          // default jatuh tempo tgl 10
          final jt = DateTime(now.year, now.month + 1, 10).toIso8601String().split('T')[0];

          await SupabaseService.addTagihan({
            'penyewa_id': widget.penyewa.id,
            'bulan_tagihan': nextMonthStr,
            'nominal_kamar': totalBayar,
            'denda_keterlambatan': 0,
            'total_tagihan': totalBayar,
            'status_lunas': false,
            'jatuh_tempo': jt,
          }, userId: _currentUserId);
        }

        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kekurangan deposit berhasil dimasukkan ke tagihan bulan depan!'), backgroundColor: AppColors.statusLunas),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal: $e'), backgroundColor: AppColors.statusMenunggak),
          );
          setState(() => _isLoading = false);
        }
      }
      return;
    }

    if (alasan.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Alasan pemotongan wajib diisi'),
            backgroundColor: AppColors.statusMenunggak),
      );
      return;
    }

    Navigator.pop(ctx);

    try {
      await SupabaseService.addPotonganDeposit({
        'id_penyewa': widget.penyewa.id,
        'nominal': nominal,
        'alasan': alasan.trim(),
        'tanggal_deduction': tanggal.toIso8601String().split('T')[0],
      }, userId: _currentUserId);

      _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Pemotongan deposit berhasil disimpan'),
              backgroundColor: AppColors.statusLunas),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal menyimpan: $e'),
              backgroundColor: AppColors.statusMenunggak),
        );
      }
    }
  }

  // ── Delete Deduction ───────────────────────────────────────

  void _confirmDeleteDeduction(PotonganDeposit d) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pemotongan'),
        content: Text(
            'Yakin hapus pemotongan ${_formatter.format(d.nominal)}?\nDeposit penyewa akan dikembalikan sebesar ini.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await SupabaseService.deletePotonganDeposit(d.id);
                _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Pemotongan dihapus'),
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
