import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import 'branch_screen.dart';
import 'kamar_screen.dart';
import 'fasilitas_screen.dart';

/// Wrapper screen: Page Cabang, Kamar & Fasilitas
class ManagementScreen extends StatelessWidget {
  final bool readOnly;
  const ManagementScreen({super.key, this.readOnly = false});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          // ── TabBar ──────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            decoration: BoxDecoration(
              color: AppColors.scaffoldBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              unselectedLabelStyle: AppTextStyles.bodySmall.copyWith(
                fontSize: 13,
              ),
              splashBorderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.all(4),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.store_rounded, size: 18),
                      SizedBox(width: 6),
                      Text('Cabang'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.meeting_room_rounded, size: 18),
                      SizedBox(width: 6),
                      Text('Kamar'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.room_preferences_rounded, size: 18),
                      // Icon(Icons.wifi_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('Fasilitas'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ── Tab Content ────────────────────────────────
          Expanded(
            child: TabBarView(
              children: [
                BranchScreen(readOnly: readOnly),
                KamarScreen(readOnly: readOnly),
                FasilitasScreen(readOnly: readOnly),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
