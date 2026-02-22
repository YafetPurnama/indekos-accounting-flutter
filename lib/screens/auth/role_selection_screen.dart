import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/auth_provider.dart';

/// Pages pemilihan role — muncul hanya saat pertama kali login.
/// User memilih: Pemilik Indekos atau Penyewa.
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.loginGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 48),

                // ── Header ──────────────────────────────────
                Text(
                  'Pilih Peran Anda',
                  style: AppTextStyles.h2.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pilih peran yang sesuai untuk mengakses\nfitur yang relevan',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 48),

                // ── Card Pemilik ────────────────────────────
                _RoleCard(
                  title: 'Pemilik Indekos',
                  subtitle:
                      'Kelola properti, tagihan,\nlaporan keuangan & penyewa',
                  icon: Icons.admin_panel_settings_rounded,
                  roleValue: 'pemilik',
                  isSelected: _selectedRole == 'pemilik',
                  gradientColors: const [Color(0xFF3949AB), Color(0xFF1A237E)],
                  onTap: () => setState(() => _selectedRole = 'pemilik'),
                ),

                const SizedBox(height: 16),

                // ── Card Admin ──────────────────────────────
                _RoleCard(
                  title: 'Admin',
                  subtitle:
                      'Pantau data kamar, pengguna,\n& statistik dashboard',
                  icon: Icons.manage_accounts_rounded,
                  roleValue: 'admin',
                  isSelected: _selectedRole == 'admin',
                  gradientColors: const [Color(0xFFFF8F00), Color(0xFFE65100)],
                  onTap: () => setState(() => _selectedRole = 'admin'),
                ),

                const SizedBox(height: 16),

                // ── Card Penyewa ────────────────────────────
                _RoleCard(
                  title: 'Penyewa',
                  subtitle: 'Lihat tagihan, riwayat\npembayaran & info kamar',
                  icon: Icons.person_rounded,
                  roleValue: 'penyewa',
                  isSelected: _selectedRole == 'penyewa',
                  gradientColors: const [Color(0xFF00897B), Color(0xFF00695C)],
                  onTap: () => setState(() => _selectedRole = 'penyewa'),
                ),

                const Spacer(),

                // ── Tombol Lanjut ────────────────────────────
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _selectedRole != null && !auth.isLoading
                            ? () => _handleRoleSelection(context)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          disabledBackgroundColor:
                              Colors.white.withOpacity(0.3),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: auth.isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                'Lanjutkan',
                                style: AppTextStyles.button.copyWith(
                                  color: _selectedRole != null
                                      ? AppColors.primary
                                      : AppColors.textHint,
                                ),
                              ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleRoleSelection(BuildContext context) async {
    if (_selectedRole == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.setRole(_selectedRole!);

    if (!context.mounted) return;

    final route = (_selectedRole == 'pemilik' || _selectedRole == 'admin')
        ? '/owner-dashboard'
        : '/tenant-dashboard';
    Navigator.pushReplacementNamed(context, route);
  }
}

/// Animasi seleksi saat choose role [card]
class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String roleValue;
  final bool isSelected;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.roleValue,
    required this.isSelected,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                )
              : null,
          color: isSelected ? null : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.white.withOpacity(0.5)
                : Colors.white.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: gradientColors.first.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 28,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),

            // Teks
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: Colors.white,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // Checkmark
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isSelected ? Colors.white : Colors.white.withOpacity(0.15),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: gradientColors.first,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
