/// Model data untuk tabel `biaya_operasional` di Supabase.
/// Pencatatan pengeluaran operasional indekos (listrik, air, perbaikan, dll).
class BiayaOperasional {
  final String id;
  final String? branchId;
  final String kategori;
  final String? deskripsi;
  final double nominal;
  final DateTime tanggalTransaksi;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;

  // Display field (dari join)
  final String? namaBranch;

  /// Kategori yang tersedia
  static const List<String> kategoriList = [
    'Listrik',
    'Air',
    'Internet',
    'Kebersihan',
    'Keamanan',
    'Perbaikan',
    'Lainnya',
  ];

  BiayaOperasional({
    required this.id,
    this.branchId,
    required this.kategori,
    this.deskripsi,
    required this.nominal,
    required this.tanggalTransaksi,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.namaBranch,
  });

  factory BiayaOperasional.fromJson(Map<String, dynamic> json) {
    // Parse join data dari branch
    String? namaBranch;
    if (json['branch'] is Map) {
      namaBranch = json['branch']['nama_branch'] as String?;
    }

    return BiayaOperasional(
      id: json['id_biaya'] as String,
      branchId: json['branch_id'] as String?,
      kategori: json['kategori'] as String,
      deskripsi: json['deskripsi'] as String?,
      nominal: (json['nominal'] as num).toDouble(),
      tanggalTransaksi:
          DateTime.parse(json['tanggal_transaksi'] as String),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      createdBy: json['created_by'] as String?,
      updatedBy: json['updated_by'] as String?,
      namaBranch: namaBranch,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'branch_id': branchId,
      'kategori': kategori,
      'deskripsi': deskripsi,
      'nominal': nominal,
      'tanggal_transaksi':
          tanggalTransaksi.toIso8601String().split('T')[0],
    };
  }

  BiayaOperasional copyWith({
    String? id,
    String? branchId,
    String? kategori,
    String? deskripsi,
    double? nominal,
    DateTime? tanggalTransaksi,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? namaBranch,
  }) {
    return BiayaOperasional(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      kategori: kategori ?? this.kategori,
      deskripsi: deskripsi ?? this.deskripsi,
      nominal: nominal ?? this.nominal,
      tanggalTransaksi: tanggalTransaksi ?? this.tanggalTransaksi,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      namaBranch: namaBranch ?? this.namaBranch,
    );
  }
}
