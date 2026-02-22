/// Data u/ tabel `kamar`
class Kamar {
  final String id;
  final String nomorKamar;
  final String? fasilitas;
  final double hargaPerBulan;
  final String status; // 'kosong', 'terisi', 'perbaikan'
  final String? branchId;
  final String? branchName;
  final DateTime? createdAt;

  Kamar({
    required this.id,
    required this.nomorKamar,
    this.fasilitas,
    required this.hargaPerBulan,
    this.status = 'kosong',
    this.branchId,
    this.branchName,
    this.createdAt,
  });

  factory Kamar.fromJson(Map<String, dynamic> json) {
    return Kamar(
      id: json['id_kamar'] as String,
      nomorKamar: json['nomor_kamar'] as String,
      fasilitas: json['fasilitas'] as String?,
      hargaPerBulan: (json['harga_per_bulan'] as num).toDouble(),
      status: json['status'] as String? ?? 'kosong',
      branchId: json['branch_id'] as String?,
      branchName: json['branch'] is Map
          ? json['branch']['nama_branch'] as String?
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nomor_kamar': nomorKamar,
      'fasilitas': fasilitas,
      'harga_per_bulan': hargaPerBulan,
      'status': status,
      'branch_id': branchId,
    };
  }

  bool get isKosong => status == 'kosong';
  bool get isTerisi => status == 'terisi';

  Kamar copyWith({
    String? id,
    String? nomorKamar,
    String? fasilitas,
    double? hargaPerBulan,
    String? status,
    String? branchId,
    String? branchName,
    DateTime? createdAt,
  }) {
    return Kamar(
      id: id ?? this.id,
      nomorKamar: nomorKamar ?? this.nomorKamar,
      fasilitas: fasilitas ?? this.fasilitas,
      hargaPerBulan: hargaPerBulan ?? this.hargaPerBulan,
      status: status ?? this.status,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
