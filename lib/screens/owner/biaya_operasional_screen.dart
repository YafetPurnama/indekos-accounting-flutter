import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/biaya_operasional_model.dart';
import '../../models/branch_model.dart';
import '../../services/supabase_service.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

/// Screen CRUD untuk input & kelola biaya operasional (listrik, air, dll)
class BiayaOperasionalScreen extends StatefulWidget {
  const BiayaOperasionalScreen({super.key});

  @override
  State<BiayaOperasionalScreen> createState() => _BiayaOperasionalScreenState();
}

class _BiayaOperasionalScreenState extends State<BiayaOperasionalScreen> {
  List<BiayaOperasional> _biayaList = [];
  List<Branch> _branches = [];
  bool _isLoading = true;

  // Filter
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  String? _selectedBranchId;

  final _currencyFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final branches = await SupabaseService.fetchAllBranches();
      final startDate = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      final endDate =
          DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
      final biaya = await SupabaseService.fetchBiayaOperasional(
        startDate: startDate,
        endDate: endDate,
        branchId: _selectedBranchId,
      );
      if (mounted) {
        setState(() {
          _branches = branches;
          _biayaList = biaya;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _totalBiaya => _biayaList.fold(0.0, (sum, b) => sum + b.nominal);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biaya Operasional'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppColors.scaffoldBackground,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          _buildSummaryCard(),
          Expanded(child: _buildList()),
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
                    Text(
                      DateFormat('MMMM yyyy', 'id').format(_selectedMonth),
                      style: AppTextStyles.bodyMedium,
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
                  hint: const Text('Semua Cabang',
                      style: TextStyle(fontSize: 13)),
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

  Widget _buildSummaryCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFF59E0B).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.receipt_long, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Biaya Bulan Ini',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currencyFormat.format(_totalBiaya),
                  style: AppTextStyles.h2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_biayaList.length} item',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_biayaList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text('Belum ada biaya operasional',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text('Tap + untuk menambah',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textHint, fontSize: 12)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _biayaList.length,
        itemBuilder: (ctx, i) => _buildBiayaCard(_biayaList[i]),
      ),
    );
  }

  Widget _buildBiayaCard(BiayaOperasional biaya) {
    final iconMap = {
      'Listrik': Icons.bolt,
      'Air': Icons.water_drop,
      'Internet': Icons.wifi,
      'Kebersihan': Icons.cleaning_services,
      'Keamanan': Icons.security,
      'Perbaikan': Icons.build,
      'Lainnya': Icons.more_horiz,
    };
    final colorMap = {
      'Listrik': const Color(0xFFF59E0B),
      'Air': const Color(0xFF3B82F6),
      'Internet': const Color(0xFF8B5CF6),
      'Kebersihan': const Color(0xFF10B981),
      'Keamanan': const Color(0xFFEF4444),
      'Perbaikan': const Color(0xFFEC4899),
      'Lainnya': const Color(0xFF6B7280),
    };

    final icon = iconMap[biaya.kategori] ?? Icons.more_horiz;
    final color = colorMap[biaya.kategori] ?? AppColors.textSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 6,
              offset: Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showFormDialog(context, biaya: biaya),
          onLongPress: () => _confirmDelete(biaya),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(biaya.kategori,
                          style:
                              AppTextStyles.labelLarge.copyWith(fontSize: 14)),
                      if (biaya.deskripsi != null &&
                          biaya.deskripsi!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(biaya.deskripsi!,
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 11, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('d MMM yyyy', 'id')
                                .format(biaya.tanggalTransaksi),
                            style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textHint, fontSize: 11),
                          ),
                          if (biaya.namaBranch != null) ...[
                            const SizedBox(width: 10),
                            Icon(Icons.location_on,
                                size: 11, color: AppColors.textHint),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                biaya.namaBranch!,
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textHint, fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _currencyFormat.format(biaya.nominal),
                  style: AppTextStyles.labelLarge.copyWith(
                    color: const Color(0xFFEF4444),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
      setState(() => _selectedMonth = DateTime(selected.year, selected.month));
      _loadData();
    }
  }

  void _showFormDialog(BuildContext context, {BiayaOperasional? biaya}) {
    final isEdit = biaya != null;
    final formKey = GlobalKey<FormState>();
    String selectedKategori = biaya?.kategori ?? 'Listrik';
    String? selectedBranch = biaya?.branchId;
    final nominalCtrl = TextEditingController(
        text: isEdit ? biaya.nominal.toStringAsFixed(0) : '');
    final deskripsiCtrl =
        TextEditingController(text: isEdit ? biaya.deskripsi ?? '' : '');
    DateTime tanggal = biaya?.tanggalTransaksi ?? DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: Form(
                key: formKey,
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
                      Text(
                        isEdit
                            ? 'Edit Biaya Operasional'
                            : 'Tambah Biaya Operasional',
                        style: AppTextStyles.h2.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 20),

                      // Kategori
                      DropdownButtonFormField<String>(
                        value: selectedKategori,
                        decoration: InputDecoration(
                          labelText: 'Kategori',
                          prefixIcon: const Icon(Icons.category),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        items: BiayaOperasional.kategoriList
                            .map((k) =>
                                DropdownMenuItem(value: k, child: Text(k)))
                            .toList(),
                        onChanged: (val) =>
                            setModalState(() => selectedKategori = val!),
                      ),
                      const SizedBox(height: 14),

                      // Nominal
                      TextFormField(
                        controller: nominalCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Nominal (Rp)',
                          prefixIcon: const Icon(Icons.attach_money),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 14),

                      // Tanggal
                      InkWell(
                        onTap: () async {
                          final d = await showDatePicker(
                            context: ctx,
                            initialDate: tanggal,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (d != null) setModalState(() => tanggal = d);
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Tanggal Transaksi',
                            prefixIcon: const Icon(Icons.calendar_today),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            DateFormat('d MMMM yyyy', 'id').format(tanggal),
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Branch
                      DropdownButtonFormField<String?>(
                        value: selectedBranch,
                        decoration: InputDecoration(
                          labelText: 'Cabang (opsional)',
                          prefixIcon: const Icon(Icons.location_on),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('— Tidak spesifik —')),
                          ..._branches.map((b) => DropdownMenuItem(
                                value: b.id,
                                child: Text(b.namaBranch),
                              )),
                        ],
                        onChanged: (val) =>
                            setModalState(() => selectedBranch = val),
                      ),
                      const SizedBox(height: 14),

                      // Deskripsi
                      TextFormField(
                        controller: deskripsiCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Deskripsi (opsional)',
                          prefixIcon: const Icon(Icons.notes),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _saveBiaya(ctx, formKey, isEdit, biaya?.id, {
                            'kategori': selectedKategori,
                            'nominal': double.tryParse(nominalCtrl.text) ?? 0,
                            'tanggal_transaksi':
                                tanggal.toIso8601String().split('T')[0],
                            'branch_id': selectedBranch,
                            'deskripsi': deskripsiCtrl.text.isEmpty
                                ? null
                                : deskripsiCtrl.text,
                          }),
                          icon: Icon(isEdit ? Icons.check : Icons.add),
                          label: Text(isEdit ? 'Simpan Perubahan' : 'Tambah'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveBiaya(
    BuildContext ctx,
    GlobalKey<FormState> formKey,
    bool isEdit,
    String? id,
    Map<String, dynamic> data,
  ) async {
    if (!formKey.currentState!.validate()) return;
    try {
      final userId = context.read<AuthProvider>().user?.uid;
      if (isEdit && id != null) {
        await SupabaseService.updateBiayaOperasional(id, data, userId: userId);
      } else {
        await SupabaseService.TambahBiayaOperasionalBaru(data, userId: userId);
      }
      if (ctx.mounted) Navigator.pop(ctx);
      _loadData();
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
      }
    }
  }

  void _confirmDelete(BiayaOperasional biaya) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Biaya?'),
        content: Text(
            'Hapus "${biaya.kategori}" ${_currencyFormat.format(biaya.nominal)}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final userId = context.read<AuthProvider>().user?.uid;
                await SupabaseService.deleteBiayaOperasional(biaya.id,
                    userId: userId);
                _loadData();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal hapus: $e')),
                  );
                }
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
