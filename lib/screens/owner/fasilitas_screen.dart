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
  List<Fasilitas> _filtered = [];
  bool _isLoading = false;
  bool _isGridView = false;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final list = await SupabaseService.fetchAllFasilitas();
    if (mounted) {
      setState(() {
        _fasilitasList = list;
        _applySearch();
        _isLoading = false;
      });
    }
  }

  void _applySearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    _filtered = q.isEmpty
        ? List.from(_fasilitasList)
        : _fasilitasList
            .where((f) => f.namaFasilitas.toLowerCase().contains(q))
            .toList();
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
      body: Column(
        children: [
          // ── Search + Toggle ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(_applySearch),
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Cari fasilitas...',
                      hintStyle:
                          TextStyle(color: AppColors.textHint, fontSize: 13),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: AppColors.textHint, size: 20),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(_applySearch);
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.scaffoldBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildViewToggle(),
              ],
            ),
          ),
          // ── List / Grid ──
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.primary,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filtered.isEmpty
                      ? _buildEmptyState()
                      : _isGridView
                          ? _buildGridView(formatter)
                          : _buildListView(formatter),
            ),
          ),
        ],
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

  // ── View Toggle ────────────────────────────────────
  Widget _buildViewToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleBtn(Icons.view_list_rounded, !_isGridView),
          _toggleBtn(Icons.grid_view_rounded, _isGridView),
        ],
      ),
    );
  }

  Widget _toggleBtn(IconData icon, bool active) {
    return GestureDetector(
      onTap: () =>
          setState(() => _isGridView = icon == Icons.grid_view_rounded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            size: 20, color: active ? Colors.white : AppColors.textHint),
      ),
    );
  }

  // ── List View ────────────────────────────────────
  Widget _buildListView(NumberFormat formatter) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      itemCount: _filtered.length,
      itemBuilder: (context, index) =>
          _buildFasilitasCard(_filtered[index], formatter),
    );
  }

  // ── Grid View ────────────────────────────────────
  Widget _buildGridView(NumberFormat formatter) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: _filtered.length,
      itemBuilder: (context, index) =>
          _buildFasilitasGridTile(_filtered[index], formatter),
    );
  }

  Widget _buildFasilitasGridTile(Fasilitas fasilitas, NumberFormat formatter) {
    final df = DateFormat('dd MMM yyyy', 'id');
    return GestureDetector(
      onTap: () => _showDetailSheet(context, fasilitas),
      onLongPress: widget.readOnly ? null : () => _confirmDelete(fasilitas),
      child: Container(
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.room_preferences_rounded,
                      color: AppColors.primary, size: 26),
                ),
                if (fasilitas.qtyUnit > 0)
                  Positioned(
                    top: -2,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${fasilitas.qtyUnit}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                fasilitas.namaFasilitas,
                style: AppTextStyles.labelLarge.copyWith(fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (fasilitas.hargaUnit > 0) ...[
              const SizedBox(height: 3),
              Text(
                formatter.format(fasilitas.hargaUnit),
                style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 10,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600),
              ),
            ],
            if (fasilitas.tanggalPembelian != null) ...[
              const SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 9, color: AppColors.textHint),
                  const SizedBox(width: 2),
                  Text(
                    'Beli: ${df.format(fasilitas.tanggalPembelian!)}',
                    style: AppTextStyles.bodySmall
                        .copyWith(fontSize: 9, color: AppColors.textHint),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
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
    final ueCtrl = TextEditingController(
        text: fasilitas?.umurEkonomisTahun.toString() ?? '5');
    DateTime? selectedTanggal = fasilitas?.tanggalPembelian;
    String selectedGolongan = 'Kustom (Isi Manual)';

    // Pre-fill dropdown jenis aset
    if (fasilitas != null) {
      if (fasilitas.umurEkonomisTahun == 4) {
        selectedGolongan = 'Elektronik & Perabotan Ringan (4 Tahun)';
      } else if (fasilitas.umurEkonomisTahun == 8) {
        selectedGolongan = 'Perabotan Berat & Mesin (8 Tahun)';
      }
    }

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

                // ── Golongan Aset (Card-based Selector) ──
                Text('Pilih Pengelompokan Aset',
                    style: AppTextStyles.bodySmall
                        .copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                  'Bedasarkan Aturan "Golongan Aset (Ref. PMK 72/2023)"',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w400,
                    // color: AppColors.textHint,
                    color: AppColors.textHint.withOpacity(0.8),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                ...[
                  _GolonganOption(
                    key: 'Elektronik & Perabotan Ringan (4 Tahun)',
                    icon: Icons.devices_rounded,
                    title: 'Kelompok 1 — 4 Tahun',
                    subtitle: 'Kursi, Lampu, Kipas, Router WiFi, Setrika',
                    color: AppColors.statusInfo,
                  ),
                  _GolonganOption(
                    key: 'Perabotan Berat & Mesin (8 Tahun)',
                    icon: Icons.kitchen_rounded,
                    title: 'Kelompok 2 — 8 Tahun',
                    subtitle: 'AC, TV, Lemari, Kulkas, Mesin Cuci, Dispenser',
                    color: AppColors.secondary,
                  ),
                  _GolonganOption(
                    key: 'Kustom (Isi Manual)',
                    icon: Icons.edit_note_rounded,
                    title: 'Kustom',
                    subtitle: 'Isi umur ekonomis secara manual',
                    color: AppColors.textSecondary,
                  ),
                ].map((opt) {
                  final isSelected = selectedGolongan == opt.key;
                  return GestureDetector(
                    onTap: () {
                      setSheetState(() {
                        selectedGolongan = opt.key;
                        if (opt.key ==
                            'Elektronik & Perabotan Ringan (4 Tahun)') {
                          ueCtrl.text = '4';
                        } else if (opt.key ==
                            'Perabotan Berat & Mesin (8 Tahun)') {
                          ueCtrl.text = '8';
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? opt.color.withOpacity(0.08)
                            : AppColors.scaffoldBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? opt.color : AppColors.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? opt.color.withOpacity(0.15)
                                  : AppColors.border.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(opt.icon,
                                size: 20,
                                color: isSelected
                                    ? opt.color
                                    : AppColors.textHint),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(opt.title,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: isSelected
                                          ? opt.color
                                          : AppColors.textPrimary,
                                    )),
                                const SizedBox(height: 2),
                                Text(opt.subtitle,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      fontSize: 11,
                                      color: AppColors.textHint,
                                    )),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle_rounded,
                                size: 20, color: opt.color),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 6),

                // ── Umur Ekonomis (Manual) ──
                Text('Umur Ekonomis (Tahun) *',
                    style: AppTextStyles.bodySmall
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: ueCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Misal: 5',
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
                            ueCtrl.text,
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

  Future<void> _saveFasilitas(
      BuildContext ctx,
      String nama,
      String hargaStr,
      String qtyStr,
      String ueStr,
      String keterangan,
      DateTime? tanggalPembelian,
      {String? editId}) async {
    if (nama.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Nama fasilitas wajib diisi'),
            backgroundColor: AppColors.statusMenunggak),
      );
      return;
    }

    final int ue = int.tryParse(ueStr.trim()) ?? 0;
    if (ue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Umur Ekonomis harus lebih dari 0'),
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
      'umur_ekonomis_tahun': ue,
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

/// Data model for selectable Golongan Aset option cards
class _GolonganOption {
  final String key;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _GolonganOption({
    required this.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}
