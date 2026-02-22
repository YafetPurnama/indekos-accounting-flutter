/// Data u/ tabel `branch`
class Branch {
  final String id;
  final String namaBranch;
  final String? alamat;
  final String? kota;
  final String? keterangan;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;

  Branch({
    required this.id,
    required this.namaBranch,
    this.alamat,
    this.kota,
    this.keterangan,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id_branch'] as String,
      namaBranch: json['nama_branch'] as String,
      alamat: json['alamat'] as String?,
      kota: json['kota'] as String?,
      keterangan: json['keterangan'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      createdBy: json['created_by'] as String?,
      updatedBy: json['updated_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama_branch': namaBranch,
      'alamat': alamat,
      'kota': kota,
      'keterangan': keterangan,
    };
  }

  Branch copyWith({
    String? id,
    String? namaBranch,
    String? alamat,
    String? kota,
    String? keterangan,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) {
    return Branch(
      id: id ?? this.id,
      namaBranch: namaBranch ?? this.namaBranch,
      alamat: alamat ?? this.alamat,
      kota: kota ?? this.kota,
      keterangan: keterangan ?? this.keterangan,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}
