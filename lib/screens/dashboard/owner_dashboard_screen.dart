import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/branch_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../owner/management_screen.dart';
import '../owner/penyewa_screen.dart';
import '../owner/user_screen.dart';
import '../owner/lainnya_screen.dart';

/// Dashboard Pemilik
class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  // Index 2 = Dashboard (center)
  int _currentIndex = 2;

  // Urutan: Penyewa, Pengguna, Dashboard, Management, Lainnya
  final List<String> _titles = [
    'Penyewa',
    'Pengguna',
    'Dashboard Pemilik',
    'Management',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      auth.addListener(_onAuthChanged);
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
              PenyewaScreen(readOnly: isAdmin),
              UserScreen(readOnly: isAdmin),
              const _DashboardTab(),
              ManagementScreen(readOnly: isAdmin),
              LainnyaScreen(readOnly: isAdmin),
            ],
          );
        },
      ),
      // ── Bottom Nav dengan FAB tengah ──
      // -- LETAK PERUBAHAN DISINI --

      // floatingActionButton: SizedBox(
      //   width: 56,
      //   height: 56,
      //   child: FloatingActionButton(
      //     elevation: 4,
      //     backgroundColor: _currentIndex == 2? AppColors.primary
      //         : AppColors.primary.withOpacity(0.7),
      //     shape: const CircleBorder(),
      //     onPressed: () => setState(() => _currentIndex = 2),
      //     child: Icon(
      //       _currentIndex == 2
      //           ? Icons.dashboard_rounded
      //           : Icons.dashboard_outlined,
      //       color: Colors.white,
      //       size: 26,
      //     ),
      //   ),
      // ),
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // bottomNavigationBar: BottomAppBar(
      //   shape: const CircularNotchedRectangle(),
      //   notchMargin: 8,
      //   color: Colors.white,
      //   elevation: 12,
      //   child: SizedBox(
      //     height: 60,
      //     child: Row(
      //       mainAxisAlignment: MainAxisAlignment.spaceAround,
      //       children: [
      //         _navItem(
      //             Icons.people_outline, Icons.people_rounded, 'Penyewa', 0),
      //         _navItem(Icons.manage_accounts_outlined,
      //             Icons.manage_accounts_rounded, 'Pengguna', 1),
      //         const SizedBox(width: 48),
      //         _navItem(Icons.business_outlined, Icons.business_rounded,
      //             'Management', 3),
      //         _navItem(Icons.more_horiz_rounded, Icons.more_horiz_rounded,
      //             'Lainnya', 4),
      //       ],
      //     ),
      //   ),
      // ),

      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          elevation: 0,
          backgroundColor: AppColors.primary,
          shape: const CircleBorder(),
          onPressed: () => setState(() => _currentIndex = 2),
          child: Icon(
            _currentIndex == 2
                ? Icons.dashboard_rounded
                : Icons.dashboard_outlined,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        padding: EdgeInsets.zero,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 16,
        shadowColor: Colors.black.withOpacity(0.4),
        child: SizedBox(
          height:
              65, // Ketinggian yang sangat proporsional (tidak kerempeng, tidak gembrot)
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.meeting_room_outlined, Icons.meeting_room_rounded,
                  'Penyewa', 0),
              _navItem(Icons.manage_accounts_outlined,
                  Icons.manage_accounts_rounded, 'Pengguna', 1),
              const SizedBox(width: 48), // Lubang transparan untuk FAB
              _navItem(Icons.business_outlined, Icons.business_rounded,
                  'Manajemen', 3),
              _navItem(Icons.more_horiz_rounded, Icons.more_horiz_rounded,
                  'Lainnya', 4),
            ],
          ),
        ),
      ),
      // -- LETAK PERUBAHAN DISINI --
    );
  }

  // -- LETAK PERUBAHAN DISINI --

  // Widget _navItem(IconData icon, IconData activeIcon, String label, int index) {
  //   final isActive = _currentIndex == index;
  //   return Expanded(
  //     child: InkWell(
  //       onTap: () => setState(() => _currentIndex = index),
  //       child: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           Icon(
  //             isActive ? activeIcon : icon,
  //             size: 22,
  //             color: isActive ? AppColors.primary : AppColors.textHint,
  //           ),
  //           const SizedBox(height: 2),
  //           Text(
  //             label,
  //             style: TextStyle(
  //               fontSize: 10,
  //               color: isActive ? AppColors.primary : AppColors.textHint,
  //               fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
  //             ),
  //             overflow: TextOverflow.ellipsis,
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
  // -- LETAK PERUBAHAN DISINI --

  Widget _navItem(IconData icon, IconData activeIcon, String label, int index) {
    final isActive = _currentIndex == index;
    return Expanded(
      child: Material(
        color: Colors
            .transparent, // Agar background putih BottomAppBar tetap terlihat
        child: InkWell(
          customBorder:
              const CircleBorder(), // Efek gelombang sentuhan berbentuk bulat halus
          onTap: () => setState(() => _currentIndex = index),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center, // Kunci agar konten pas di tengah bar
            mainAxisSize: MainAxisSize.max,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                size: 24,
                color: isActive
                    ? AppColors.primary
                    : Colors.grey.shade400, // Abu-abu elegan jika tidak aktif
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isActive ? AppColors.primary : Colors.grey.shade500,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
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
// ── Tab Dashboard (index 2) ─────────────────────────────────
// ══════════════════════════════════════════════════════════════

class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  List<Branch> _branches = [];
  String? _selectedBranchId; // null = Semua Cabang
  Map<String, int> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    final branches = await SupabaseService.fetchAllBranches();
    final stats = await SupabaseService.fetchDashboardStatsByBranch();

    if (mounted) {
      setState(() {
        _branches = branches;
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  Future<void> _onBranchChanged(String? branchId) async {
    setState(() {
      _selectedBranchId = branchId;
      _isLoading = true;
    });

    final stats =
        await SupabaseService.fetchDashboardStatsByBranch(branchId: branchId);

    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.refreshUserData();
    await _onBranchChanged(_selectedBranchId);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    final totalKamar = _stats['totalKamar'] ?? 0;
    final kamarTerisi = _stats['kamarTerisi'] ?? 0;
    final penyewaAktif = _stats['penyewaAktif'] ?? 0;
    final tagihanPending = _stats['tagihanPending'] ?? 0;
    final tagihanMenunggak = _stats['tagihanMenunggak'] ?? 0;

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
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

            // ── Ringkasan Header + Dropdown ─────────────
            Row(
              children: [
                Text('Ringkasan', style: AppTextStyles.h3),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),

            // ── Branch Dropdown ──────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.scaffoldBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: _selectedBranchId,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppColors.primary),
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  hint: const Text('Pilih cabang untuk melihat ringkasan',
                      style:
                          TextStyle(fontSize: 13, color: AppColors.textHint)),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('📊 Semua Cabang',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    ..._branches.map((b) => DropdownMenuItem<String?>(
                          value: b.id,
                          child: Text('🏠 ${b.namaBranch}'),
                        )),
                  ],
                  onChanged: _onBranchChanged,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Quick Stats ──────────────────────────────
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              Row(children: [
                _StatCard(
                  icon: Icons.meeting_room_rounded,
                  label: 'Kamar Terpakai',
                  value: '$kamarTerisi / $totalKamar',
                  color: AppColors.statusInfo,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  icon: Icons.people_rounded,
                  label: 'Penyewa Aktif',
                  value: '$penyewaAktif',
                  color: AppColors.statusLunas,
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                _StatCard(
                  icon: Icons.receipt_long_rounded,
                  label: 'Tagihan Pending',
                  value: '$tagihanPending',
                  color: AppColors.statusPending,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  icon: Icons.warning_amber_rounded,
                  label: 'Menunggak',
                  value: '$tagihanMenunggak',
                  color: AppColors.statusMenunggak,
                ),
              ]),
            ],

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
