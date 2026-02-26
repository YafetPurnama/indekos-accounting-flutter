import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../services/supabase_service.dart';

/// CRUD Manajemen Pengguna
/// [readOnly]
class UserScreen extends StatefulWidget {
  final bool readOnly;
  const UserScreen({super.key, this.readOnly = false});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  List<Map<String, dynamic>> _userList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final list = await SupabaseService.fetchUserList();
    if (mounted)
      setState(() {
        _userList = list;
        _isLoading = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    final listPenyewa =
        _userList.where((u) => u['role'] == 'penyewa').toList();
    final listAdmin = _userList
        .where((u) => u['role'] == 'admin' || u['role'] == 'pemilik')
        .toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Column(
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
                        Icon(Icons.person_outline, size: 18),
                        SizedBox(width: 6),
                        Text('Penyewa'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.admin_panel_settings_outlined, size: 18),
                        SizedBox(width: 6),
                        Text('Admin'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // ── TabBarView ──────────────────────────────────
            Expanded(
              child: TabBarView(
                children: [
                  _buildUserList(listPenyewa),
                  _buildUserList(listAdmin),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: widget.readOnly
            ? null
            : FloatingActionButton(
                backgroundColor: AppColors.primary,
                onPressed: () => _showFormSheet(context),
                child: const Icon(Icons.person_add, color: Colors.white),
              ),
      ),
    );
  }

  Widget _buildUserList(List<Map<String, dynamic>> users) {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : users.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: users.length,
                  itemBuilder: (context, index) => _buildUserCard(users[index]),
                ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Center(
          child: Column(
            children: [
              Icon(Icons.people_outline, size: 64, color: AppColors.textHint),
              const SizedBox(height: 16),
              Text('Belum ada data pengguna',
                  style: AppTextStyles.labelLarge
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Text(
                  widget.readOnly
                      ? 'Data pengguna kosong'
                      : 'Tap + untuk menambah pengguna',
                  style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final role = (user['role'] as String?) ?? '';
    final roleColor = role == 'pemilik'
        ? AppColors.primary
        : role == 'admin'
            ? AppColors.accent
            : AppColors.secondary;
    final nama = (user['nama'] as String?) ?? 'Tanpa Nama';
    final email = (user['email'] as String?) ?? '-';
    final status = (user['status'] as String?) ?? 'aktif';
    final isAktif = status == 'aktif';

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
          onTap: widget.readOnly
              ? null
              : () => _showFormSheet(context, user: user),
          onLongPress: widget.readOnly ? null : () => _confirmDelete(user),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 22,
                  backgroundColor: roleColor.withOpacity(0.1),
                  child: Text(
                    nama.isNotEmpty ? nama[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: roleColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nama,
                          style:
                              AppTextStyles.labelLarge.copyWith(fontSize: 15)),
                      const SizedBox(height: 3),
                      Text(email,
                          style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (isAktif
                            ? AppColors.statusLunas
                            : AppColors.textHint)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isAktif ? 'Aktif' : 'Nonaktif',
                    style: TextStyle(
                        color: isAktif
                            ? AppColors.statusLunas
                            : AppColors.textHint,
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                // Role badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    role.isNotEmpty
                        ? role[0].toUpperCase() + role.substring(1)
                        : '—',
                    style: TextStyle(
                        color: roleColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Form Bottom Sheet ─────────────────────────────────────

  void _showFormSheet(BuildContext context, {Map<String, dynamic>? user}) {
    final isEdit = user != null;
    final namaCtrl = TextEditingController(text: user?['nama'] ?? '');
    final emailCtrl = TextEditingController(text: user?['email'] ?? '');
    final passwordCtrl = TextEditingController(text: user?['password'] ?? '');
    String selectedRole = (user?['role'] as String?) ?? 'penyewa';
    bool isStatusAktif = (user?['status'] as String? ?? 'aktif') == 'aktif';

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
                Text(isEdit ? 'Edit Pengguna' : 'Tambah Pengguna',
                    style: AppTextStyles.h3),
                const SizedBox(height: 20),
                _sheetField('Nama', namaCtrl, 'Nama lengkap'),
                const SizedBox(height: 14),
                _sheetField('Email', emailCtrl, 'contoh@email.com',
                    keyboard: TextInputType.emailAddress),
                const SizedBox(height: 14),
                _sheetField('Password', passwordCtrl, 'Min 6 karakter'),
                const SizedBox(height: 14),
                Text('Role',
                    style: AppTextStyles.bodySmall
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: ['pemilik', 'admin', 'penyewa'].map((r) {
                    final selected = selectedRole == r;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(r[0].toUpperCase() + r.substring(1),
                              style: TextStyle(
                                  fontSize: 13,
                                  color: selected
                                      ? Colors.white
                                      : AppColors.textSecondary)),
                          selected: selected,
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.scaffoldBackground,
                          onSelected: (_) {
                            setSheetState(() => selectedRole = r);
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                // ── Status Toggle ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Status',
                        style: AppTextStyles.bodySmall
                            .copyWith(fontWeight: FontWeight.w600)),
                    Row(
                      children: [
                        Text(
                          isStatusAktif ? 'Aktif' : 'Tidak Aktif',
                          style: TextStyle(
                            fontSize: 13,
                            color: isStatusAktif
                                ? AppColors.statusLunas
                                : AppColors.textHint,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: isStatusAktif,
                          activeColor: AppColors.statusLunas,
                          onChanged: (val) {
                            setSheetState(() => isStatusAktif = val);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    if (isEdit)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _confirmDelete(user);
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
                        onPressed: () => _saveUser(
                          ctx,
                          namaCtrl.text,
                          emailCtrl.text,
                          passwordCtrl.text,
                          selectedRole,
                          isStatusAktif ? 'aktif' : 'tidak aktif',
                          editId: user?['id_user'] as String?,
                        ),
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

  Widget _sheetField(String label, TextEditingController ctrl, String hint,
      {TextInputType keyboard = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboard,
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

  Future<void> _saveUser(
      BuildContext ctx, String nama, String email, String password, String role,
      String status,
      {String? editId}) async {
    if (nama.trim().isEmpty || email.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Nama dan email wajib diisi'),
            backgroundColor: AppColors.statusMenunggak),
      );
      return;
    }

    Navigator.pop(ctx);

    final data = <String, dynamic>{
      'nama': nama.trim(),
      'email': email.trim(),
      'role': role,
      'status': status,
    };
    if (password.trim().isNotEmpty) data['password'] = password.trim();

    try {
      if (editId != null) {
        await SupabaseService.updateUser(editId, data);

        // Sync role ke Firestore agar real-time listener ikut update
        try {
          final query = await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: email.trim())
              .limit(1)
              .get();
          if (query.docs.isNotEmpty) {
            await query.docs.first.reference.update({'role': role});
          }
        } catch (e) {
          debugPrint('⚠️ Firestore role sync gagal (non-blocking): $e');
        }
      } else {
        // Generate simple ID for new users
        data['id_user'] = 'user-${DateTime.now().millisecondsSinceEpoch}';
        await SupabaseService.addUser(data);
      }
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(editId != null ? 'User diperbarui' : 'User ditambahkan'),
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

  void _confirmDelete(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pengguna'),
        content: Text('Yakin hapus ${user['nama']}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await SupabaseService.deleteUser(user['id_user'] as String);
                _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('User dihapus'),
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
