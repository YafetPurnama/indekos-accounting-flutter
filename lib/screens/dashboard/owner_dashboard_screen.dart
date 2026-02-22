import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/kamar_provider.dart';
import '../owner/management_screen.dart';
import '../owner/user_screen.dart';
import '../owner/backup_screen.dart';

/// Dashboard Pemilik
class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  int _currentIndex = 0;

  final List<String> _titles = [
    // TODO: List Menu BottomAppBar / Bottom Navigation Bar mobile ku
    'Dashboard Pemilik',
    'Management',
    'Manajemen Pengguna',
    'Backup Data',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      auth.addListener(_onAuthChanged);

      Provider.of<KamarProvider>(context, listen: false).fetchDashboardStats();
    });
  }

  void _onAuthChanged() {
    if (!mounted) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (auth.user == null) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      return;
    }

    if (auth.user!.role == 'penyewa') {
      Navigator.pushReplacementNamed(context, '/tenant-dashboard');
    } else if (auth.user!.role == null || auth.user!.role!.isEmpty) {
      Navigator.pushReplacementNamed(context, '/role-select');
    }
  }

  @override
  void dispose() {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      auth.removeListener(_onAuthChanged);
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          final auth = Provider.of<AuthProvider>(context, listen: false);
          final isAdmin = auth.user?.role == 'admin';
          return IndexedStack(
            index: _currentIndex,
            children: [
              _DashboardTab(),
              ManagementScreen(readOnly: isAdmin),
              UserScreen(readOnly: isAdmin),
              const BackupScreen(),
            ],
          );
        },
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textHint,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.business_outlined),
              activeIcon: Icon(Icons.business_rounded),
              label: 'Management',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people_rounded),
              label: 'Pengguna',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.cloud_upload_outlined),
              activeIcon: Icon(Icons.cloud_upload_rounded),
              label: 'Backup',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signOut();
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }
}

// ══════════════════════════════════════════════════════════════
// ── Tab Dashboard (index 0) ─────────────────────────────────
// ══════════════════════════════════════════════════════════════

class _DashboardTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final kamarProvider = Provider.of<KamarProvider>(context);

    return RefreshIndicator(
      onRefresh: () async {
        final a = Provider.of<AuthProvider>(context, listen: false);
        final k = Provider.of<KamarProvider>(context, listen: false);
        await Future.wait([a.refreshUserData(), k.fetchDashboardStats()]);
      },
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Welcome Card ─────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        backgroundImage: auth.user?.photoUrl != null
                            ? NetworkImage(auth.user!.photoUrl!)
                            : null,
                        child: auth.user?.photoUrl == null
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Selamat Datang! 👋',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 13,
                                )),
                            const SizedBox(height: 2),
                            Text(auth.user?.displayName ?? 'Pemilik',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '🏠 Role: ${auth.user?.role == 'pemilik' ? 'Pemilik Indekos' : auth.user?.role ?? 'Belum dipilih'}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Quick Stats ──────────────────────────────
            Text('Ringkasan', style: AppTextStyles.h3),
            const SizedBox(height: 16),

            Row(children: [
              _StatCard(
                icon: Icons.meeting_room_rounded,
                label: 'Total Kamar',
                value: kamarProvider.isLoading
                    ? '...'
                    : '${kamarProvider.totalKamar}',
                color: AppColors.statusInfo,
              ),
              const SizedBox(width: 12),
              _StatCard(
                icon: Icons.people_rounded,
                label: 'Penyewa Aktif',
                value: kamarProvider.isLoading
                    ? '...'
                    : '${kamarProvider.penyewaAktif}',
                color: AppColors.statusLunas,
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _StatCard(
                icon: Icons.receipt_long_rounded,
                label: 'Tagihan Pending',
                value: kamarProvider.isLoading
                    ? '...'
                    : '${kamarProvider.tagihanPending}',
                color: AppColors.statusPending,
              ),
              const SizedBox(width: 12),
              _StatCard(
                icon: Icons.warning_amber_rounded,
                label: 'Menunggak',
                value: kamarProvider.isLoading
                    ? '...'
                    : '${kamarProvider.tagihanMenunggak}',
                color: AppColors.statusMenunggak,
              ),
            ]),

            const SizedBox(height: 28),

            // ── Sync Info ────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.statusInfo.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.statusInfo.withOpacity(0.2)),
              ),
              child: Row(children: [
                Icon(Icons.sync_rounded, size: 18, color: AppColors.statusInfo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Data sinkron otomatis • Tarik ke bawah untuk refresh',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.statusInfo,
                      fontSize: 11,
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ── Stat Card Widget ────────────────────────────────────────
// ══════════════════════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(height: 12),
            Text(value, style: AppTextStyles.h2.copyWith(fontSize: 22)),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
