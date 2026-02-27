import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/fasilitas_model.dart';
import '../../models/kamar_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';

/// CRUD Manajemen Fasilitas
/// [readOnly] — admin view-only
class FasilitasScreen extends StatefulWidget {
  final bool readOnly;
  const FasilitasScreen({super.key, this.readOnly = false});

  @override
  State<FasilitasScreen> createState() => _FasilitasScreenState();
}

class _FasilitasScreenState extends State<FasilitasScreen> {
  List<Fasilitas> _fasilitasList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final list = await SupabaseService.fetchAllFasilitas();
    if (mounted) {
      setState(() {
        _fasilitasList = list;
        _isLoading = false;
      });
    }
  }

  String? get _currentUserId {
    try {
      return Provider.of<AuthProvider>(context, listen: false).user?.uid;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _fasilitasList.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: _fasilitasList.length,
                    itemBuilder: (context, index) =>
                        _buildFasilitasCard(_fasilitasList[index], formatter),
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
              Icon(Icons.room_preferences_rounded,
                  size: 64, color: AppColors.textHint),
              // Icon(Icons.wifi_rounded, size: 64, color: AppColors.textHint), ICON WIFI
              const SizedBox(height: 16),
              Text('Belum ada data fasilitas',
                  style: AppTextStyles.labelLarge
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Text(
                  widget.readOnly
                      ? 'Data fasilitas kosong'
                      : 'Tap + untuk menambah fasilitas',
                  style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFasilitasCard(Fasilitas fasilitas, NumberFormat formatter) {
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
          onTap: () => _showDetailSheet(context, fasilitas),
          onLongPress: widget.readOnly ? null : () => _confirmDelete(fasilitas),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.room_preferences_rounded,
                      // child: const Icon(Icons.wifi_rounded,
                      color: AppColors.primary,
                      size: 24),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(fasilitas.namaFasilitas,
                                style: AppTextStyles.labelLarge
                                    .copyWith(fontSize: 15)),
                          ),
                          if (fasilitas.qtyUnit > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('${fasilitas.qtyUnit} Unit',
                                  style: AppTextStyles.bodySmall.copyWith(
                                      fontSize: 11,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600)),
                            ),
                        ],
                      ),
                      if (fasilitas.hargaUnit > 0) ...[
                        const SizedBox(height: 4),
                        Text(formatter.format(fasilitas.hargaUnit),
                            style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600)),
                      ],
                      if (fasilitas.keterangan != null &&
                          fasilitas.keterangan!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(fasilitas.keterangan!,
                            style:
                                AppTextStyles.bodySmall.copyWith(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                      if (fasilitas.tanggalPembelian != null) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                size: 12, color: AppColors.textHint),
                            const SizedBox(width: 3),
                            Text(
                                'Beli: ${DateFormat('dd MMM yyyy', 'id_ID').format(fasilitas.tanggalPembelian!)}',
                                style: AppTextStyles.bodySmall.copyWith(
                                    fontSize: 11, color: AppColors.textHint)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Edit indicator
                if (!widget.readOnly)
                  IconButton(
                    icon: Icon(Icons.edit_outlined,
                        size: 20, color: AppColors.textHint),
                    onPressed: () =>
                        _showFormSheet(context, fasilitas: fasilitas),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Detail & Form Bottom Sheet ──────────────────────────────

  void _showDetailSheet(BuildContext context, Fasilitas fasilitas) {
    bool isLoadingKamar = true;
    List<Kamar> kamarList = [];
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          if (isLoadingKamar) {
            SupabaseService.fetchKamarByFasilitas(fasilitas.id).then((list) {
              if (ctx.mounted) {
                setSheetState(() {
                  kamarList = list;
                  isLoadingKamar = false;
                });
              }
            });
          }

          final int usedQty = kamarList.length;
          final int remainingQty =
              fasilitas.qtyUnit > 0 ? (fasilitas.qtyUnit - usedQty) : 0;

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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child:
                            Text('Detail Fasilitas', style: AppTextStyles.h3),
                      ),
                      if (!widget.readOnly)
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showFormSheet(context, fasilitas: fasilitas);
                          },
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Edit'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(50, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Info Fasilitas
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.scaffoldBackground,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.room_preferences_rounded,
                              color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(fasilitas.namaFasilitas,
                                  style: AppTextStyles.labelLarge
                                      .copyWith(fontSize: 16)),
                              if (fasilitas.hargaUnit > 0) ...[
                                const SizedBox(height: 4),
                                Text(formatter.format(fasilitas.hargaUnit),
                                    style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600)),
                              ],
                              if (fasilitas.tanggalPembelian != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                    'Beli: ${DateFormat('dd MMMM yyyy', 'id_ID').format(fasilitas.tanggalPembelian!)}',
                                    style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: 12)),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Info Unit
                  if (fasilitas.qtyUnit > 0) ...[
                    Text('Status Penggunaan', style: AppTextStyles.labelLarge),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildStatBox(
                            'Total Unit', '${fasilitas.qtyUnit}', Colors.blue),
                        const SizedBox(width: 12),
                        _buildStatBox(
                            'Terpakai', '$usedQty', AppColors.primary),
                        const SizedBox(width: 12),
                        _buildStatBox(
                            'Tersedia',
                            '$remainingQty',
                            remainingQty > 0
                                ? AppColors.statusLunas
                                : AppColors.statusMenunggak),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  // List Kamar yang menggunakan
                  Text('Kamar yang Menggunakan (${usedQty})',
                      style: AppTextStyles.labelLarge),
                  const SizedBox(height: 12),
                  if (isLoadingKamar)
                    const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (kamarList.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.scaffoldBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Center(
                        child: Text(
                          'Belum ada kamar yang menggunakan fasilitas ini.',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: kamarList.length,
                      itemBuilder: (ctx, index) {
                        final kamar = kamarList[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.door_front_door_outlined,
                                  color: AppColors.textHint, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  kamar.nomorKamar,
                                  style: AppTextStyles.labelLarge
                                      .copyWith(fontSize: 14),
                                ),
                              ),
                              if (kamar.branchName != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.scaffoldBackground,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    kamar.branchName!,
                                    style: AppTextStyles.bodySmall
                                        .copyWith(fontSize: 11),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary, fontSize: 11)),
            const SizedBox(height: 4),
            Text(value,
                style: AppTextStyles.h3.copyWith(color: color, fontSize: 18)),
          ],
        ),
      ),
    );
  }

  void _showFormSheet(BuildContext context, {Fasilitas? fasilitas}) {
    final isEdit = fasilitas != null;
    final namaCtrl =
        TextEditingController(text: fasilitas?.namaFasilitas ?? '');
    final hargaCtrl = TextEditingController(
      text: fasilitas != null && fasilitas.hargaUnit > 0
          ? _ThousandSeparatorFormatter.format(
              fasilitas.hargaUnit.toStringAsFixed(0))
          : '',
    );
    final qtyCtrl =
        TextEditingController(text: fasilitas?.qtyUnit.toString() ?? '');
    final keteranganCtrl =
        TextEditingController(text: fasilitas?.keterangan ?? '');
    DateTime? selectedTanggal = fasilitas?.tanggalPembelian;

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
                Text(isEdit ? 'Edit Fasilitas' : 'Tambah Fasilitas',
                    style: AppTextStyles.h3),
                const SizedBox(height: 20),
                _sheetField(
                    'Nama Fasilitas *', namaCtrl, 'Contoh: AC, WiFi, dll'),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _buildHargaField(hargaCtrl)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQtyField(qtyCtrl),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // ── Tanggal Pembelian ──
                Text('Tanggal Pembelian',
                    style: AppTextStyles.bodySmall
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedTanggal ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setSheetState(() => selectedTanggal = picked);
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
                        Expanded(
                          child: Text(
                            selectedTanggal != null
                                ? DateFormat('dd MMMM yyyy', 'id_ID')
                                    .format(selectedTanggal!)
                                : 'Pilih tanggal pembelian Unit',
                            style: TextStyle(
                              fontSize: 14,
                              color: selectedTanggal != null
                                  ? Colors.black87
                                  : AppColors.textHint,
                            ),
                          ),
                        ),
                        if (selectedTanggal != null)
                          GestureDetector(
                            onTap: () {
                              setSheetState(() => selectedTanggal = null);
                            },
                            child: Icon(Icons.close,
                                size: 18, color: AppColors.textHint),
                          )
                        else
                          Icon(Icons.calendar_today_outlined,
                              size: 18, color: AppColors.textHint),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _sheetField('Keterangan', keteranganCtrl, 'Catatan tambahan'),
                const SizedBox(height: 24),
                Row(
                  children: [
                    if (isEdit)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _confirmDelete(fasilitas);
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
                        onPressed: () => _saveFasilitas(
                            ctx,
                            namaCtrl.text,
                            hargaCtrl.text,
                            qtyCtrl.text,
                            keteranganCtrl.text,
                            selectedTanggal,
                            editId: fasilitas?.id),
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

  /// Field harga dengan separator ribuan
  Widget _buildHargaField(TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Harga Unit',
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
            hintText: 'Opsional, misal: 50.000',
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

  /// Field quantity
  Widget _buildQtyField(TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Qty (Opsional)',
            style:
                AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Misal: 2',
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

  Widget _sheetField(String label, TextEditingController ctrl, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
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

  Future<void> _saveFasilitas(BuildContext ctx, String nama, String hargaStr,
      String qtyStr, String keterangan, DateTime? tanggalPembelian,
      {String? editId}) async {
    if (nama.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Nama fasilitas wajib diisi'),
            backgroundColor: AppColors.statusMenunggak),
      );
      return;
    }
    final harga =
        double.tryParse(hargaStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final qty = int.tryParse(qtyStr.trim()) ?? 0;

    Navigator.pop(ctx);

    final data = <String, dynamic>{
      'nama_fasilitas': nama.trim(),
      'harga_unit': harga,
      'qty_unit': qty,
      'keterangan_fasilitas':
          keterangan.trim().isEmpty ? null : keterangan.trim(),
      'tanggal_pembelian': tanggalPembelian != null
          ? tanggalPembelian.toIso8601String().split('T')[0]
          : null,
    };

    try {
      if (editId != null) {
        await SupabaseService.updateFasilitas(editId, data,
            userId: _currentUserId);
      } else {
        await SupabaseService.addFasilitas(data, userId: _currentUserId);
      }
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(editId != null
                ? 'Fasilitas diperbarui'
                : 'Fasilitas ditambahkan'),
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

  void _confirmDelete(Fasilitas fasilitas) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Fasilitas'),
        content: Text('Yakin hapus "${fasilitas.namaFasilitas}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await SupabaseService.deleteFasilitas(fasilitas.id,
                    userId: _currentUserId);
                _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Fasilitas dihapus'),
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
