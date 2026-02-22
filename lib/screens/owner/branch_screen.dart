import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/branch_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import 'kamar_screen.dart';

/// CRUD Cabang / Lokasi Indekos
/// [readOnly] = true → Admin view-only
class BranchScreen extends StatefulWidget {
  final bool readOnly;
  const BranchScreen({super.key, this.readOnly = false});

  @override
  State<BranchScreen> createState() => _BranchScreenState();
}

class _BranchScreenState extends State<BranchScreen> {
  List<Branch> _branchList = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 0;
  final int _perPage = 10;
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData(reset: true);
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _loadData();
    }
  }

  Future<void> _loadData({bool reset = false}) async {
    if (reset) {
      _page = 0;
      _hasMore = true;
    }
    if (!_hasMore && !reset) return;

    setState(() => _isLoading = true);

    final list = await SupabaseService.fetchBranchList(
      search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      page: _page,
      perPage: _perPage,
    );

    if (mounted) {
      setState(() {
        if (reset) {
          _branchList = list;
        } else {
          _branchList.addAll(list);
        }
        _hasMore = list.length == _perPage;
        _page++;
        _isLoading = false;
      });
    }
  }

  String? get _currentUserId {
    try {
      return Provider.of<AuthProvider>(context, listen: false).user?.uid;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ── Search Box ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => _loadData(reset: true),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Cari cabang...',
                hintStyle: TextStyle(color: AppColors.textHint, fontSize: 13),
                prefixIcon: Icon(Icons.search_rounded,
                    color: AppColors.textHint, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _loadData(reset: true);
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.scaffoldBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // ── List ───────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadData(reset: true),
              color: AppColors.primary,
              child: _branchList.isEmpty && !_isLoading
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                      itemCount: _branchList.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _branchList.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2.5),
                              ),
                            ),
                          );
                        }
                        return _buildBranchCard(_branchList[index]);
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: widget.readOnly
          ? null
          : FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: () => _showFormSheet(context),
              child:
                  const Icon(Icons.add_business_rounded, color: Colors.white),
            ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            children: [
              Icon(Icons.store_outlined, size: 64, color: AppColors.textHint),
              const SizedBox(height: 16),
              Text(
                _searchCtrl.text.isNotEmpty
                    ? 'Tidak ditemukan'
                    : 'Belum ada cabang',
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                widget.readOnly
                    ? 'Data cabang kosong'
                    : 'Tap + untuk menambah cabang',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBranchCard(Branch branch) {
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
          onTap: () => _openKamarForBranch(branch),
          onLongPress: widget.readOnly
              ? null
              : () => _showFormSheet(context, branch: branch),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.apartment_rounded,
                      color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(branch.namaBranch,
                          style:
                              AppTextStyles.labelLarge.copyWith(fontSize: 15)),
                      if (branch.alamat != null &&
                          branch.alamat!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(branch.alamat!,
                            style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 12, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                      if (branch.kota != null && branch.kota!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 12, color: AppColors.textHint),
                            const SizedBox(width: 3),
                            Text(branch.kota!,
                                style: AppTextStyles.bodySmall.copyWith(
                                    fontSize: 11, color: AppColors.textHint)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Arrow
                Icon(Icons.chevron_right_rounded,
                    color: AppColors.textHint, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Tap branch → buka halaman kamar (VIEW ONLY, tanpa FAB)
  void _openKamarForBranch(Branch branch) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text('Kamar — ${branch.namaBranch}')),
          body: KamarScreen(
            readOnly: true,
            branchId: branch.id,
            branchName: branch.namaBranch,
          ),
        ),
      ),
    );
  }

  // ── Form Bottom Sheet ─────────────────────────────────────

  void _showFormSheet(BuildContext context, {Branch? branch}) {
    final isEdit = branch != null;
    final namaCtrl = TextEditingController(text: branch?.namaBranch ?? '');
    final alamatCtrl = TextEditingController(text: branch?.alamat ?? '');
    final kotaCtrl = TextEditingController(text: branch?.kota ?? '');
    final keteranganCtrl =
        TextEditingController(text: branch?.keterangan ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
              Text(isEdit ? 'Edit Cabang' : 'Tambah Cabang',
                  style: AppTextStyles.h3),
              const SizedBox(height: 20),
              _sheetField('Nama Cabang *', namaCtrl, 'Contoh: Kos Melati A'),
              const SizedBox(height: 14),
              _sheetField('Alamat', alamatCtrl, 'Jl. Contoh No. 123'),
              const SizedBox(height: 14),
              _sheetField('Kota', kotaCtrl, 'Surabaya'),
              const SizedBox(height: 14),
              _sheetField('Keterangan', keteranganCtrl, 'Catatan tambahan'),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (isEdit)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _confirmDelete(branch);
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
                      onPressed: () => _saveBranch(
                        ctx,
                        namaCtrl.text,
                        alamatCtrl.text,
                        kotaCtrl.text,
                        keteranganCtrl.text,
                        editId: branch?.id,
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
    );
  }

  Widget _sheetField(String label, TextEditingController ctrl, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
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

  Future<void> _saveBranch(
    BuildContext ctx,
    String nama,
    String alamat,
    String kota,
    String keterangan, {
    String? editId,
  }) async {
    if (nama.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama cabang wajib diisi'),
          backgroundColor: AppColors.statusMenunggak,
        ),
      );
      return;
    }

    Navigator.pop(ctx);

    final data = <String, dynamic>{
      'nama_branch': nama.trim(),
      'alamat': alamat.trim().isEmpty ? null : alamat.trim(),
      'kota': kota.trim().isEmpty ? null : kota.trim(),
      'keterangan': keterangan.trim().isEmpty ? null : keterangan.trim(),
    };

    try {
      if (editId != null) {
        await SupabaseService.updateBranch(editId, data,
            userId: _currentUserId);
      } else {
        await SupabaseService.addBranch(data, userId: _currentUserId);
      }
      _loadData(reset: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                editId != null ? 'Cabang diperbarui' : 'Cabang ditambahkan'),
            backgroundColor: AppColors.statusLunas,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $e'),
            backgroundColor: AppColors.statusMenunggak,
          ),
        );
      }
    }
  }

  void _confirmDelete(Branch branch) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Cabang'),
        content: Text('Yakin hapus "${branch.namaBranch}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await SupabaseService.deleteBranch(branch.id,
                    userId: _currentUserId);
                _loadData(reset: true);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cabang dihapus'),
                      backgroundColor: AppColors.statusLunas,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal: $e'),
                      backgroundColor: AppColors.statusMenunggak,
                    ),
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
