import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/penyewa_model.dart';
import '../../models/kamar_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import 'tagihan_screen.dart';

/// CRUD Penyewa — assign user ke kamar
class PenyewaScreen extends StatefulWidget {
  final bool readOnly;
  const PenyewaScreen({super.key, this.readOnly = false});

  @override
  State<PenyewaScreen> createState() => _PenyewaScreenState();
}

class _PenyewaScreenState extends State<PenyewaScreen> {
  List<Penyewa> _list = [];
  bool _isLoading = false;

  String get _currentUserId =>
      Provider.of<AuthProvider>(context, listen: false).user?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final list = await SupabaseService.fetchPenyewaList();
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
              child: const Icon(Icons.person_add_rounded, color: Colors.white),
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
              Icon(Icons.people_outline, size: 64, color: AppColors.textHint),
              const SizedBox(height: 12),
              Text('Belum ada penyewa',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Text('Tap + untuk assign penyewa ke kamar',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textHint, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Card ────────────────────────────────────────────────────

  Widget _buildCard(Penyewa p) {
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormatter = DateFormat('dd MMM yyyy', 'id_ID');

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
          onTap: () => _openTagihan(p),
          onLongPress: widget.readOnly
              ? null
              : () => _showFormSheet(context, penyewa: p),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    (p.namaUser ?? 'P')[0].toUpperCase(),
                    style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.namaUser ?? 'Penyewa',
                          style:
                              AppTextStyles.labelLarge.copyWith(fontSize: 15)),
                      const SizedBox(height: 3),
                      if (p.nomorKamar != null)
                        Row(
                          children: [
                            Icon(Icons.meeting_room_rounded,
                                size: 13, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text('Kamar ${p.nomorKamar}',
                                style: AppTextStyles.bodySmall.copyWith(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600)),
                            if (p.namaBranch != null) ...[
                              Text(' · ',
                                  style: TextStyle(
                                      color: AppColors.textHint, fontSize: 11)),
                              Text(p.namaBranch!,
                                  style: AppTextStyles.bodySmall.copyWith(
                                      fontSize: 11, color: AppColors.textHint)),
                            ],
                          ],
                        ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 11, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          Text('Masuk: ${dateFormatter.format(p.tanggalMasuk)}',
                              style: AppTextStyles.bodySmall.copyWith(
                                  fontSize: 11, color: AppColors.textHint)),
                        ],
                      ),
                      if (p.deposit > 0) ...[
                        const SizedBox(height: 2),
                        Text('Deposit: ${formatter.format(p.deposit)}',
                            style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 11, color: AppColors.statusLunas)),
                      ],
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (p.statusAktif
                            ? AppColors.statusLunas
                            : AppColors.textHint)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    p.statusAktif ? 'Aktif' : 'Nonaktif',
                    style: TextStyle(
                        color: p.statusAktif
                            ? AppColors.statusLunas
                            : AppColors.textHint,
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

  // ── Navigate ke Tagihan ────────────────────────────────────

  void _openTagihan(Penyewa p) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text('Tagihan — ${p.namaUser ?? 'Penyewa'}')),
          body: TagihanScreen(
            penyewaId: p.id,
            namaUser: p.namaUser,
            nomorKamar: p.nomorKamar,
            hargaKamar: null, // will be loaded in TagihanScreen
            readOnly: widget.readOnly,
          ),
        ),
      ),
    );
  }

  // ── Form Bottom Sheet ──────────────────────────────────────

  void _showFormSheet(BuildContext context, {Penyewa? penyewa}) async {
    final isEdit = penyewa != null;

    // Load dropdown data
    final allUsers = await SupabaseService.fetchUsersByRole('penyewa');
    final assignedIds = await SupabaseService.fetchAssignedUserIds();
    final kamarList = await SupabaseService.fetchAvailableKamar();

    // Filter: User ✅
    final users = allUsers.where((u) {
      final uid = u['id_user'] as String;
      if (isEdit && uid == penyewa.userId) return true; // keep current
      return !assignedIds.contains(uid);
    }).toList();
    List<Kamar> allKamar = [...kamarList];
    if (isEdit && penyewa.kamarId != null) {
      final hasExisting = allKamar.any((k) => k.id == penyewa.kamarId);
      if (!hasExisting) {
        final existing = await SupabaseService.fetchKamarById(penyewa.kamarId!);
        if (existing != null) allKamar.insert(0, existing);
      }
    }

    if (!mounted) return;

    String? selectedUserId = penyewa?.userId;
    String? selectedKamarId = penyewa?.kamarId;
    final waCtrl = TextEditingController(text: penyewa?.nomorWhatsapp ?? '');
    final depositCtrl = TextEditingController(
      text: penyewa != null && penyewa.deposit > 0
          ? _ThousandFmt.format(penyewa.deposit.toStringAsFixed(0))
          : '',
    );
    DateTime selectedDate = penyewa?.tanggalMasuk ?? DateTime.now();

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
                Text(isEdit ? 'Edit Penyewa' : 'Tambah Penyewa',
                    style: AppTextStyles.h3),
                const SizedBox(height: 20),

                // ── Dropdown User ──
                Text('Pengguna *',
                    style: AppTextStyles.bodySmall
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedUserId,
                  isExpanded: true,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  decoration: _dropdownDecoration('Pilih pengguna'),
                  items: users
                      .map((u) => DropdownMenuItem<String>(
                            value: u['id_user'] as String,
                            child: Text('${u['nama']} (${u['email']})'),
                          ))
                      .toList(),
                  onChanged: (v) => setSheetState(() => selectedUserId = v),
                ),
                const SizedBox(height: 14),

                // ── Dropdown Kamar ──
                Text('Kamar *',
                    style: AppTextStyles.bodySmall
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedKamarId,
                  isExpanded: true,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  decoration: _dropdownDecoration('Pilih kamar'),
                  items: allKamar
                      .map((k) => DropdownMenuItem<String>(
                            value: k.id,
                            child: Text(
                              '${k.nomorKamar}${k.branchName != null ? ' (${k.branchName})' : ''}',
                            ),
                          ))
                      .toList(),
                  onChanged: (v) => setSheetState(() => selectedKamarId = v),
                ),
                const SizedBox(height: 14),

                // ── Tanggal Masuk ──
                Text('Tanggal Masuk *',
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
                const SizedBox(height: 14),

                // ── No WhatsApp ──
                _sheetField('No. WhatsApp', waCtrl, '08xxxxxxxxxx',
                    keyboard: TextInputType.phone),
                const SizedBox(height: 14),

                // ── Deposit ──
                Text('Deposit',
                    style: AppTextStyles.bodySmall
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: depositCtrl,
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
                const SizedBox(height: 24),

                // ── Buttons ──
                Row(
                  children: [
                    if (isEdit)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _confirmDelete(penyewa);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.statusMenunggak,
                            side: const BorderSide(
                                color: AppColors.statusMenunggak),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Nonaktifkan'),
                        ),
                      ),
                    if (isEdit) const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => _savePenyewa(
                          ctx,
                          selectedUserId,
                          selectedKamarId,
                          selectedDate,
                          waCtrl.text,
                          depositCtrl.text,
                          editId: penyewa?.id,
                          oldKamarId: penyewa?.kamarId,
                        ),
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

  InputDecoration _dropdownDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textHint, fontSize: 13),
      filled: true,
      fillColor: AppColors.scaffoldBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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

  // ── Save ────────────────────────────────────────────────────

  Future<void> _savePenyewa(
    BuildContext ctx,
    String? userId,
    String? kamarId,
    DateTime tanggalMasuk,
    String wa,
    String depositStr, {
    String? editId,
    String? oldKamarId,
  }) async {
    if (userId == null || kamarId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Pengguna dan Kamar wajib dipilih'),
            backgroundColor: AppColors.statusMenunggak),
      );
      return;
    }

    Navigator.pop(ctx);

    final deposit =
        double.tryParse(depositStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    final data = <String, dynamic>{
      'user_id': userId,
      'kamar_id': kamarId,
      'tanggal_masuk': tanggalMasuk.toIso8601String().split('T')[0],
      'nomor_whatsapp': wa.trim().isEmpty ? null : wa.trim(),
      'deposit': deposit,
      'status_aktif': true,
    };

    try {
      if (editId != null) {
        await SupabaseService.updatePenyewa(editId, data,
            userId: _currentUserId, oldKamarId: oldKamarId);
      } else {
        await SupabaseService.addPenyewa(data, userId: _currentUserId);
      }
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                editId != null ? 'Penyewa diperbarui' : 'Penyewa ditambahkan'),
            backgroundColor: AppColors.statusLunas,
          ),
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

  // ── Delete ──────────────────────────────────────────────────

  void _confirmDelete(Penyewa p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nonaktifkan Penyewa'),
        content: Text(
            'Yakin nonaktifkan "${p.namaUser ?? 'Penyewa'}"? Kamar akan dikosongkan.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await SupabaseService.deletePenyewa(p.id,
                    userId: _currentUserId, kamarId: p.kamarId);
                _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Penyewa dinonaktifkan'),
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
            child: const Text('Nonaktifkan',
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
