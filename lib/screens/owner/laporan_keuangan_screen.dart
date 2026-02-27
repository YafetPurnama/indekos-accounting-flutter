import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/fasilitas_model.dart';
import '../../models/branch_model.dart';
import '../../services/supabase_service.dart';

/// Screen Laporan Keuangan — Laba Rugi & Arus Kas
class LaporanKeuanganScreen extends StatefulWidget {
  const LaporanKeuanganScreen({super.key});

  @override
  State<LaporanKeuanganScreen> createState() => _LaporanKeuanganScreenState();
}

class _LaporanKeuanganScreenState extends State<LaporanKeuanganScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  // Filter
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  String? _selectedBranchId;
  List<Branch> _branches = [];

  // Laba Rugi data
  double _pendapatanSewa = 0;
  double _pendapatanDenda = 0;
  Map<String, double> _biayaPerKategori = {};
  double _totalDepresiasi = 0;
  List<Fasilitas> _fasilitasList = [];

  // Arus Kas data
  double _depositMasuk = 0;

  final _fmt =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final branches = await SupabaseService.fetchAllBranches();
      final startDate = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      final endDate =
          DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);

      // Fetch parallel
      final results = await Future.wait([
        SupabaseService.fetchPendapatanByPeriode(startDate, endDate),
        SupabaseService.fetchBiayaByPeriode(startDate, endDate,
            branchId: _selectedBranchId),
        SupabaseService.fetchAllFasilitas(),
        SupabaseService.fetchDepositMasukByPeriode(startDate, endDate),
      ]);

      final pendapatan = results[0] as Map<String, double>;
      final biaya = results[1] as Map<String, double>;
      final fasilitas = results[2] as List<Fasilitas>;
      final deposit = results[3] as double;

      // Hitung depresiasi bulanan dari aset yang sudah dibeli sebelum akhir periode
      double totalDep = 0;
      for (final f in fasilitas) {
        if (f.tanggalPembelian != null &&
            f.tanggalPembelian!.isBefore(endDate) &&
            f.hargaUnit > 0 &&
            f.qtyUnit > 0) {
          totalDep += f.depresiasiPerBulan;
        }
      }

      if (mounted) {
        setState(() {
          _branches = branches;
          _pendapatanSewa = pendapatan['pendapatanSewa'] ?? 0;
          _pendapatanDenda = pendapatan['pendapatanDenda'] ?? 0;
          _biayaPerKategori = biaya;
          _fasilitasList = fasilitas;
          _totalDepresiasi = totalDep;
          _depositMasuk = deposit;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('🔥 Error loading laporan: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Computed Values ─────────────────────────────────────────
  double get _totalPendapatan => _pendapatanSewa + _pendapatanDenda;
  double get _totalBiayaOps =>
      _biayaPerKategori.values.fold(0.0, (s, v) => s + v);
  double get _totalBeban => _totalBiayaOps + _totalDepresiasi;
  double get _labaBersih => _totalPendapatan - _totalBeban;

  double get _totalArusKasMasuk =>
      _pendapatanSewa + _pendapatanDenda + _depositMasuk;
  double get _totalArusKasKeluar => _totalBiayaOps;
  double get _arusKasBersih => _totalArusKasMasuk - _totalArusKasKeluar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Keuangan'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Laba Rugi'),
            Tab(text: 'Arus Kas'),
          ],
        ),
      ),
      backgroundColor: AppColors.scaffoldBackground,
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLabaRugiTab(),
                      _buildArusKasTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          // Month picker
          Expanded(
            child: InkWell(
              onTap: _pickMonth,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.scaffoldBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_month,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        DateFormat('MMMM yyyy', 'id').format(_selectedMonth),
                        style: AppTextStyles.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Branch filter
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.scaffoldBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: _selectedBranchId,
                  isExpanded: true,
                  hint: const Text('Semua', style: TextStyle(fontSize: 13)),
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textPrimary),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('Semua Cabang')),
                    ..._branches.map((b) => DropdownMenuItem(
                          value: b.id,
                          child: Text(b.namaBranch,
                              overflow: TextOverflow.ellipsis),
                        )),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedBranchId = val);
                    _loadData();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // ── TAB 1: LABA RUGI ────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════

  Widget _buildLabaRugiTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header card
          _buildHeaderCard(
            title: 'Laba Bersih',
            value: _labaBersih,
            icon: Icons.trending_up_rounded,
            isPositive: _labaBersih >= 0,
          ),
          const SizedBox(height: 16),

          // Pendapatan section
          _buildSectionCard(
            title: 'PENDAPATAN',
            color: AppColors.statusLunas,
            items: [
              _ReportLineItem('Pendapatan Sewa Kamar', _pendapatanSewa),
              _ReportLineItem('Pendapatan Denda', _pendapatanDenda),
            ],
            total: _totalPendapatan,
            totalLabel: 'Total Pendapatan',
          ),
          const SizedBox(height: 12),

          // Beban section
          _buildSectionCard(
            title: 'BEBAN / BIAYA',
            color: AppColors.statusMenunggak,
            items: [
              ..._biayaPerKategori.entries
                  .map((e) => _ReportLineItem('Biaya ${e.key}', e.value)),
              _ReportLineItem('Penyusutan Aset', _totalDepresiasi),
            ],
            total: _totalBeban,
            totalLabel: 'Total Beban',
          ),
          const SizedBox(height: 12),

          // Bottom line — Laba Bersih
          _buildResultCard(
            label: 'LABA BERSIH',
            value: _labaBersih,
          ),

          // Depresiasi detail
          if (_fasilitasList.any((f) =>
              f.tanggalPembelian != null && f.hargaUnit > 0 && f.qtyUnit > 0))
            _buildDepresiasiDetail(),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // ── TAB 2: ARUS KAS ─────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════

  Widget _buildArusKasTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildHeaderCard(
            title: 'Arus Kas Bersih',
            value: _arusKasBersih,
            icon: Icons.account_balance_wallet_rounded,
            isPositive: _arusKasBersih >= 0,
          ),
          const SizedBox(height: 16),

          // Kas Masuk
          _buildSectionCard(
            title: 'ARUS KAS MASUK',
            color: AppColors.statusLunas,
            items: [
              _ReportLineItem('Penerimaan Sewa', _pendapatanSewa),
              _ReportLineItem('Penerimaan Denda', _pendapatanDenda),
              _ReportLineItem('Deposit Masuk', _depositMasuk),
            ],
            total: _totalArusKasMasuk,
            totalLabel: 'Total Kas Masuk',
          ),
          const SizedBox(height: 12),

          // Kas Keluar
          _buildSectionCard(
            title: 'ARUS KAS KELUAR',
            color: AppColors.statusMenunggak,
            items: [
              ..._biayaPerKategori.entries
                  .map((e) => _ReportLineItem('Biaya ${e.key}', e.value)),
            ],
            total: _totalArusKasKeluar,
            totalLabel: 'Total Kas Keluar',
          ),
          const SizedBox(height: 12),

          _buildResultCard(
            label: 'ARUS KAS BERSIH',
            value: _arusKasBersih,
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // ── SHARED WIDGETS ──────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════

  Widget _buildHeaderCard({
    required String title,
    required double value,
    required IconData icon,
    required bool isPositive,
  }) {
    final color = isPositive ? AppColors.statusLunas : AppColors.statusMenunggak;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPositive
              ? [const Color(0xFF10B981), const Color(0xFF059669)]
              : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _fmt.format(value),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              DateFormat('MMM yyyy', 'id').format(_selectedMonth),
              style: const TextStyle(
                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Color color,
    required List<_ReportLineItem> items,
    required double total,
    required String totalLabel,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(title,
                    style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5)),
              ],
            ),
          ),
          ...items
              .where((item) => item.value != 0)
              .map((item) => _buildLineItem(item.label, item.value)),
          if (items.every((item) => item.value == 0))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text('Tidak ada data',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textHint, fontSize: 12)),
            ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(totalLabel,
                    style: AppTextStyles.labelLarge.copyWith(fontSize: 13)),
                Text(_fmt.format(total),
                    style: AppTextStyles.labelLarge
                        .copyWith(fontSize: 14, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineItem(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary, fontSize: 13)),
          ),
          Text(_fmt.format(value),
              style: AppTextStyles.bodyMedium.copyWith(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildResultCard({
    required String label,
    required double value,
  }) {
    final isPositive = value >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPositive
              ? AppColors.statusLunas.withOpacity(0.3)
              : AppColors.statusMenunggak.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 8,
              offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isPositive
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                color: isPositive
                    ? AppColors.statusLunas
                    : AppColors.statusMenunggak,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(label,
                  style: AppTextStyles.labelLarge
                      .copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          Text(
            _fmt.format(value),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isPositive
                  ? AppColors.statusLunas
                  : AppColors.statusMenunggak,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepresiasiDetail() {
    final endDate =
        DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final activeAssets = _fasilitasList
        .where((f) =>
            f.tanggalPembelian != null &&
            f.tanggalPembelian!.isBefore(endDate) &&
            f.hargaUnit > 0 &&
            f.qtyUnit > 0)
        .toList();

    if (activeAssets.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: AppColors.statusInfo),
            const SizedBox(width: 6),
            Text('Detail Penyusutan Aset',
                style: AppTextStyles.labelLarge.copyWith(
                    fontSize: 13, color: AppColors.statusInfo)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 6,
                  offset: Offset(0, 2)),
            ],
          ),
          child: Column(
            children: [
              // Table header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.scaffoldBackground,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: const Row(
                  children: [
                    Expanded(
                        flex: 3,
                        child: Text('Aset',
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w600))),
                    Expanded(
                        flex: 2,
                        child: Text('Perolehan',
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.right)),
                    Expanded(
                        flex: 1,
                        child: Text('UE',
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center)),
                    Expanded(
                        flex: 2,
                        child: Text('/Bulan',
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.right)),
                  ],
                ),
              ),
              ...activeAssets.map((f) => Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text('${f.namaFasilitas} (×${f.qtyUnit})',
                              style: const TextStyle(fontSize: 11)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            _fmt.format(f.totalHargaPerolehan),
                            style: const TextStyle(fontSize: 11),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            '${f.umurEkonomisTahun}th',
                            style: const TextStyle(fontSize: 11),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            _fmt.format(f.depresiasiPerBulan),
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  )),
              const Divider(height: 1, indent: 12, endIndent: 12),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Penyusutan/Bulan',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700)),
                    Text(_fmt.format(_totalDepresiasi),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Metode: Garis Lurus (Straight Line) — SAK EMKM',
          style: AppTextStyles.bodySmall
              .copyWith(color: AppColors.textHint, fontSize: 10),
        ),
      ],
    );
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1, 12),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (selected != null) {
      setState(
          () => _selectedMonth = DateTime(selected.year, selected.month));
      _loadData();
    }
  }
}

/// Helper class for report line items
class _ReportLineItem {
  final String label;
  final double value;
  const _ReportLineItem(this.label, this.value);
}
