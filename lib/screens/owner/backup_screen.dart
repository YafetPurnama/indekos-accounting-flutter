import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

/// Fitur Backup Data
class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _isBackingUp = false;
  String _lastBackup = 'Belum pernah';
  String _selectedInterval = '7 hari';

  final List<String> _intervals = [
    '1 hari',
    '3 hari',
    '7 hari',
    '14 hari',
    '30 hari',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Card ──────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1565C0).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.cloud_upload_rounded,
                        color: Colors.white, size: 30),
                  ),
                  const SizedBox(height: 16),
                  Text('Backup Data',
                      style: AppTextStyles.h3.copyWith(color: Colors.white)),
                  const SizedBox(height: 6),
                  Text(
                    'Data disimpan aman ke cloud\nFirebase sebagai cadangan',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Status Backup ────────────────────────────
            _buildInfoCard(
              icon: Icons.history_rounded,
              title: 'Backup Terakhir',
              value: _lastBackup,
              color: AppColors.statusInfo,
            ),

            const SizedBox(height: 12),

            _buildInfoCard(
              icon: Icons.storage_rounded,
              title: 'Database',
              value: 'Database Indekos',
              color: AppColors.statusLunas,
            ),

            const SizedBox(height: 12),

            _buildInfoCard(
              icon: Icons.cloud_done_rounded,
              title: 'Cloud Backup',
              value: 'Firebase Cloud',
              color: AppColors.secondary,
            ),

            const SizedBox(height: 24),

            // ── Interval Setting ─────────────────────────
            Text('Interval Backup Otomatis', style: AppTextStyles.h3),
            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
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
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _intervals.map((interval) {
                  final selected = _selectedInterval == interval;
                  return ChoiceChip(
                    label: Text(interval,
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              selected ? Colors.white : AppColors.textSecondary,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.normal,
                        )),
                    selected: selected,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.scaffoldBackground,
                    onSelected: (_) {
                      setState(() => _selectedInterval = interval);
                    },
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 28),

            // ── Tombol Backup Manual ─────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isBackingUp ? null : _handleBackup,
                icon: _isBackingUp
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.backup_rounded),
                label: Text(_isBackingUp ? 'Membackup...' : 'Backup Sekarang',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Note ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.statusPending.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.statusPending.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      size: 18, color: AppColors.statusPending),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Backup mencakup data kamar, penyewa, tagihan, dan pembayaran. Data otomatis terenkripsi saat dikirim ke cloud.',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 8,
              offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(value,
                    style: AppTextStyles.labelLarge.copyWith(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBackup() async {
    setState(() => _isBackingUp = true);

    // Simulasi proses backup
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      final now = DateTime.now();
      final formatted =
          '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
      setState(() {
        _isBackingUp = false;
        _lastBackup = formatted;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Backup berhasil!'),
          backgroundColor: AppColors.statusLunas,
        ),
      );
    }
  }
}
