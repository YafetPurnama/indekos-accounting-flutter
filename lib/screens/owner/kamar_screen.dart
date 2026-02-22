import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/kamar_model.dart';
import '../../models/branch_model.dart';
import '../../services/supabase_service.dart';

/// CRUD Manajemen Kamar
/// [readOnly] — admin view-only
/// [branchId] — filter kamar by branch (dari BranchScreen)
/// [branchName] — nama cabang untuk display
class KamarScreen extends StatefulWidget {
  final bool readOnly;
  final String? branchId;
  final String? branchName;
  const KamarScreen(
      {super.key, this.readOnly = false, this.branchId, this.branchName});

  @override
  State<KamarScreen> createState() => _KamarScreenState();
}

class _KamarScreenState extends State<KamarScreen> {
  List<Kamar> _kamarList = [];
  List<Branch> _branches = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    final list = await SupabaseService.fetchAllBranches();
    if (mounted) setState(() => _branches = list);
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final list =
        await SupabaseService.fetchKamarList(branchId: widget.branchId);
    if (mounted)
      setState(() {
        _kamarList = list;
        _isLoading = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _kamarList.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: _kamarList.length,
                    itemBuilder: (context, index) =>
                        _buildKamarCard(_kamarList[index]),
                  ),
      ),
      floatingActionButton: widget.readOnly
          ? null
          : FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: () => _showFormSheet(context),
              child: const Icon(Icons.add, color: Colors.white),
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
              Icon(Icons.meeting_room_outlined,
                  size: 64, color: AppColors.textHint),
              const SizedBox(height: 16),
              Text('Belum ada data kamar',
                  style: AppTextStyles.labelLarge
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Text(
                  widget.readOnly
                      ? 'Data kamar kosong'
                      : 'Tap + untuk menambah kamar',
                  style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKamarCard(Kamar kamar) {
    final statusColor = kamar.status == 'terisi'
        ? AppColors.statusLunas
        : kamar.status == 'perbaikan'
            ? AppColors.statusPending
            : AppColors.statusInfo;
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

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
          onTap: widget.readOnly
              ? null
              : () => _showFormSheet(context, kamar: kamar),
          onLongPress: widget.readOnly ? null : () => _confirmDelete(kamar),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.meeting_room_rounded,
                      color: statusColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Kamar ${kamar.nomorKamar}',
                          style:
                              AppTextStyles.labelLarge.copyWith(fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(formatter.format(kamar.hargaPerBulan),
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                      if (kamar.fasilitas != null &&
                          kamar.fasilitas!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(kamar.fasilitas!,
                            style:
                                AppTextStyles.bodySmall.copyWith(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                      if (kamar.branchName != null &&
                          kamar.branchName!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.store_outlined,
                                size: 12, color: AppColors.textHint),
                            const SizedBox(width: 3),
                            Text(kamar.branchName!,
                                style: AppTextStyles.bodySmall.copyWith(
                                    fontSize: 11,
                                    color: AppColors.textHint)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    kamar.status[0].toUpperCase() + kamar.status.substring(1),
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

  // ── Form Bottom Sheet ─────────────────────────────────────

  void _showFormSheet(BuildContext context, {Kamar? kamar}) {
    final isEdit = kamar != null;
    final nomorCtrl = TextEditingController(text: kamar?.nomorKamar ?? '');
    final fasilitasCtrl = TextEditingController(text: kamar?.fasilitas ?? '');
    // Separator tanda pemisah nominal
    final hargaCtrl = TextEditingController(
      text: kamar != null
          ? _ThousandSeparatorFormatter.format(
              kamar.hargaPerBulan.toStringAsFixed(0))
          : '',
    );
    String selectedStatus = kamar?.status ?? 'kosong';
    String? selectedBranchId = kamar?.branchId ?? widget.branchId;

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
                Text(isEdit ? 'Edit Kamar' : 'Tambah Kamar',
                    style: AppTextStyles.h3),
                const SizedBox(height: 20),
                // ── Dropdown Pilih Cabang (wajib) ──
                Text('Cabang *',
                    style: AppTextStyles.bodySmall
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedBranchId,
                  isExpanded: true,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Pilih cabang',
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
                  items: _branches
                      .map((b) => DropdownMenuItem<String>(
                            value: b.id,
                            child: Text(b.namaBranch),
                          ))
                      .toList(),
                  onChanged: (v) {
                    setSheetState(() => selectedBranchId = v);
                  },
                ),
                const SizedBox(height: 14),
                _sheetField('Nomor Kamar', nomorCtrl, 'Contoh: A1'),
                const SizedBox(height: 14),
                // Harga field dengan separator ribuan
                _buildHargaField(hargaCtrl),
                const SizedBox(height: 14),
                _sheetField(
                    'Fasilitas', fasilitasCtrl, 'AC, Kamar Mandi Dalam'),
                const SizedBox(height: 14),
                Text('Status',
                    style: AppTextStyles.bodySmall
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: ['kosong', 'terisi', 'perbaikan'].map((s) {
                    final selected = selectedStatus == s;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: ChoiceChip(
                          label: Text(s[0].toUpperCase() + s.substring(1),
                              style: TextStyle(
                                  fontSize: 12,
                                  color: selected
                                      ? Colors.white
                                      : AppColors.textSecondary)),
                          selected: selected,
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.scaffoldBackground,
                          onSelected: (_) {
                            setSheetState(() => selectedStatus = s);
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    if (isEdit)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _confirmDelete(kamar);
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
                        onPressed: () => _saveKamar(ctx, nomorCtrl.text,
                            hargaCtrl.text, fasilitasCtrl.text, selectedStatus,
                            editId: kamar?.id, branchId: selectedBranchId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(isEdit ? 'Simpan' : 'Tambah'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Field harga dengan separator ribuan (contoh: 5.000.000)
  Widget _buildHargaField(TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Harga / Bulan',
            style:
                AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _ThousandSeparatorFormatter(),
          ],
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Contoh: 1.500.000',
            prefixText: 'Rp ',
            prefixStyle:
                TextStyle(fontSize: 14, color: AppColors.textSecondary),
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

  Widget _sheetField(String label, TextEditingController ctrl, String hint,
      {TextInputType keyboard = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboard,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
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

  Future<void> _saveKamar(BuildContext ctx, String nomor, String hargaStr,
      String fasilitas, String status,
      {String? editId, String? branchId}) async {
    if (nomor.trim().isEmpty || hargaStr.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Nomor dan harga wajib diisi'),
            backgroundColor: AppColors.statusMenunggak),
      );
      return;
    }
    if (branchId == null && editId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Pilih cabang terlebih dahulu'),
            backgroundColor: AppColors.statusMenunggak),
      );
      return;
    }
    final harga = double.tryParse(hargaStr.replaceAll(RegExp(r'[^0-9]'), ''));
    if (harga == null) return;

    Navigator.pop(ctx);

    final data = {
      'nomor_kamar': nomor.trim(),
      'harga_per_bulan': harga,
      'fasilitas': fasilitas.trim().isEmpty ? null : fasilitas.trim(),
      'status': status,
      if (branchId != null) 'branch_id': branchId,
    };

    try {
      if (editId != null) {
        await SupabaseService.updateKamar(editId, data);
      } else {
        await SupabaseService.addKamar(data);
      }
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(editId != null ? 'Kamar diperbarui' : 'Kamar ditambahkan'),
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

  void _confirmDelete(Kamar kamar) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kamar'),
        content: Text('Yakin hapus Kamar ${kamar.nomorKamar}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await SupabaseService.deleteKamar(kamar.id);
                _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Kamar dihapus'),
                        backgroundColor: AppColors.statusLunas),
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

/// TextInputFormatter untuk separator ribuan (titik)
/// Input: 5000000 → Display: 5.000.000
class _ThousandSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;

    final digits = newValue.text.replaceAll('.', '');
    final formatted = format(digits);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  /// Format angka string dengan separator titik ribuan
  static String format(String digits) {
    if (digits.isEmpty) return '';
    final buffer = StringBuffer();
    final len = digits.length;
    for (int i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
