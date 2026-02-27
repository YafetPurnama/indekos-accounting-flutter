import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/penyewa_model.dart';
import '../../services/supabase_service.dart';
import 'deposit_management_screen.dart';

/// Screen ini dipanggil dari menu Lainnya untuk melihat semua daftar deposit penyewa
class ManajemenDepositListScreen extends StatefulWidget {
  const ManajemenDepositListScreen({super.key});

  @override
  State<ManajemenDepositListScreen> createState() =>
      _ManajemenDepositListScreenState();
}

class _ManajemenDepositListScreenState
    extends State<ManajemenDepositListScreen> {
  List<Penyewa> _penyewaList = [];
  bool _isLoading = false;
  final _formatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final list = await SupabaseService.fetchPenyewaList();
      // Hanya tampilkan penyewa yang memiliki deposit awal > 0
      final filteredList = list.where((p) => p.deposit > 0).toList();
      if (mounted) {
        setState(() {
          _penyewaList = filteredList;
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
        title: const Text('Manajemen Deposit'),
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
            : _penyewaList.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _penyewaList.length,
                    itemBuilder: (context, index) {
                      final p = _penyewaList[index];
                      return _buildPenyewaDepositCard(p);
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 100),
        Icon(Icons.account_balance_wallet_rounded,
            size: 64, color: AppColors.textHint.withOpacity(0.5)),
        const SizedBox(height: 16),
        Text(
          'Belum Ada Data Deposit',
          style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Tidak ada penyewa aktif yang memiliki deposit jaminan.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPenyewaDepositCard(Penyewa p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DepositManagementScreen(penyewa: p),
              ),
            ).then((_) => _loadData());
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    (p.namaUser ?? 'P')[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.namaUser ?? 'Penyewa',
                        style: AppTextStyles.labelLarge.copyWith(fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p.nomorKamar != null
                            ? 'Kamar ${p.nomorKamar}${p.namaBranch != null ? ' · ${p.namaBranch}' : ''}'
                            : 'Belum assign kamar',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            p.hasDeduction
                                ? Icons.warning_amber_rounded
                                : Icons.check_circle_outline_rounded,
                            size: 14,
                            color: p.depositStatus == 'utuh'
                                ? AppColors.statusLunas
                                : p.depositStatus == 'sebagian'
                                    ? AppColors.statusPending
                                    : AppColors.statusMenunggak,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            p.hasDeduction
                                ? 'Sisa: ${_formatter.format(p.depositSisa)} (Total: ${_formatter.format(p.deposit)})'
                                : 'Deposit utuh: ${_formatter.format(p.deposit)}',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: p.depositStatus == 'utuh'
                                  ? AppColors.statusLunas
                                  : p.depositStatus == 'sebagian'
                                      ? AppColors.statusPending
                                      : AppColors.statusMenunggak,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
