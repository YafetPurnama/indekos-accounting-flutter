import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import 'backup_screen.dart';

/// Menu overflow "Lainnya" — menampung fitur tambahan
class LainnyaScreen extends StatelessWidget {
  final bool readOnly;
  const LainnyaScreen({super.key, this.readOnly = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _MenuTile(
            icon: Icons.cloud_upload_rounded,
            color: const Color(0xFF5B7FFF),
            title: 'Backup Data',
            subtitle: 'Cadangkan data ke cloud',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: const Text('Backup Data')),
                  body: const BackupScreen(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _MenuTile(
            icon: Icons.bar_chart_rounded,
            color: const Color(0xFF34D399),
            title: 'Laporan Keuangan',
            subtitle: 'Cash Flow & Laba Rugi',
            comingSoon: true,
            onTap: () => _showComingSoon(context, 'Laporan Keuangan'),
          ),
          const SizedBox(height: 12),
          _MenuTile(
            icon: Icons.build_rounded,
            color: const Color(0xFFF59E0B),
            title: 'Biaya Operasional',
            subtitle: 'Listrik, air, servis AC',
            comingSoon: true,
            onTap: () => _showComingSoon(context, 'Biaya Operasional'),
          ),
          const SizedBox(height: 12),
          _MenuTile(
            icon: Icons.account_balance_wallet_rounded,
            color: const Color(0xFFEC4899),
            title: 'Manajemen Deposit',
            subtitle: 'Refund, potong, hangus',
            comingSoon: true,
            onTap: () => _showComingSoon(context, 'Manajemen Deposit'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature — segera hadir! 🚧'),
        backgroundColor: AppColors.statusPending,
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool comingSoon;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.comingSoon = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: AppTextStyles.labelLarge
                              .copyWith(fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                if (comingSoon)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.statusPending.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('Segera',
                        style: TextStyle(
                            color: AppColors.statusPending,
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                  )
                else
                  Icon(Icons.chevron_right_rounded,
                      color: AppColors.textHint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
