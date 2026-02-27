import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/laporan_model.dart';
import '../../models/penyewa_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import 'package:intl/intl.dart';

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  Penyewa? _penyewa;
  List<LaporanModel> _laporanList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      _penyewa = await SupabaseService.fetchPenyewaByUserId(user.uid);
      if (_penyewa != null) {
        _laporanList = await SupabaseService.fetchLaporanByPenyewaId(_penyewa!.id);
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan & Keluhan'),
        backgroundColor: AppColors.secondary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _laporanList.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _laporanList.length,
                    itemBuilder: (ctx, index) {
                      final item = _laporanList[index];
                      return _LaporanCard(laporan: item);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _penyewa == null ? null : _showFormLaporan,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Buat Laporan'),
        backgroundColor: AppColors.secondary,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.report_gmailerrorred_rounded, size: 60, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text('Belum ada laporan', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text(
            'Jika ada kerusakan atau keluhan,\nsilakan buat laporan.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  void _showFormLaporan() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LaporanFormBottomSheet(
        penyewa: _penyewa!,
        onSuccess: _loadData,
      ),
    );
  }
}

class _LaporanCard extends StatelessWidget {
  final LaporanModel laporan;
  const _LaporanCard({required this.laporan});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;
    switch (laporan.status) {
      case 'selesai':
        statusColor = AppColors.statusLunas;
        statusText = 'Selesai';
        break;
      case 'diproses':
        statusColor = Colors.orange;
        statusText = 'Diproses';
        break;
      default:
        statusColor = AppColors.statusMenunggak;
        statusText = 'Menunggu Respon';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    laporan.judul,
                    style: AppTextStyles.h3.copyWith(fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                        fontSize: 12, color: statusColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('dd MMM yyyy, HH:mm').format(laporan.createdAt),
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
            ),
            const SizedBox(height: 12),
            Text(laporan.deskripsi, style: const TextStyle(fontSize: 14)),
            if (laporan.fotoUrl != null && laporan.fotoUrl!.isNotEmpty) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  laporan.fotoUrl!,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, e, trace) => Container(
                    height: 120,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class _LaporanFormBottomSheet extends StatefulWidget {
  final Penyewa penyewa;
  final VoidCallback onSuccess;

  const _LaporanFormBottomSheet({required this.penyewa, required this.onSuccess});

  @override
  State<_LaporanFormBottomSheet> createState() => _LaporanFormBottomSheetState();
}

class _LaporanFormBottomSheetState extends State<_LaporanFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _judulCtrl = TextEditingController();
  final _deskripsiCtrl = TextEditingController();
  File? _selectedFile;
  bool _isSubmitting = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _selectedFile = File(pickedFile.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      String? fotoUrl;
      if (_selectedFile != null) {
        fotoUrl = await SupabaseService.uploadFotoLaporan(
          _selectedFile!, 
          widget.penyewa.id
        );
      }

      await SupabaseService.addLaporan({
        'penyewa_id': widget.penyewa.id,
        'kamar_id': widget.penyewa.kamarId,
        'judul': _judulCtrl.text.trim(),
        'deskripsi': _deskripsiCtrl.text.trim(),
        'foto_url': fotoUrl,
        'status': 'menunggu_respon',
      }, userId: widget.penyewa.userId);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Laporan berhasil dikirim'), backgroundColor: AppColors.statusLunas),
        );
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim laporan: $e'), backgroundColor: AppColors.statusMenunggak),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _judulCtrl.dispose();
    _deskripsiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
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
              Text('Buat Laporan Baru', style: AppTextStyles.h3),
              const SizedBox(height: 16),

              TextFormField(
                controller: _judulCtrl,
                decoration: InputDecoration(
                  labelText: 'Judul (Misal: Kran Air Rusak)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _deskripsiCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Deskripsi Masalah',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              Text('Lampiran Foto (Opsional)',
                  style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: _selectedFile != null ? 150 : 80,
                  decoration: BoxDecoration(
                    color: AppColors.scaffoldBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: _selectedFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_selectedFile!, fit: BoxFit.cover),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_a_photo, color: AppColors.textHint),
                            const SizedBox(width: 8),
                            Text('Tap untuk tambah foto',
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Kirim Laporan', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
