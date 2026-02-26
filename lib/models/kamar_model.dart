import 'fasilitas_model.dart';

/// Data u/ tabel `kamar`
class Kamar {
  final String id;
  final String nomorKamar;
  final double hargaPerBulan;
  final String status; // 'kosong', 'terisi', 'perbaikan'
  final String? branchId;
  final String? branchName;
  final DateTime? createdAt;
  final List<Fasilitas> fasilitasList;

  Kamar({
    required this.id,
    required this.nomorKamar,
    required this.hargaPerBulan,
    this.status = 'kosong',
    this.branchId,
    this.branchName,
    this.createdAt,
    this.fasilitasList = const [],
  });

  factory Kamar.fromJson(Map<String, dynamic> json) {
    List<Fasilitas> parsedFasilitas = [];
    if (json['kamar_fasilitas'] is List) {
      for (final kf in json['kamar_fasilitas']) {
        if (kf is Map && kf['fasilitas'] is Map) {
          parsedFasilitas.add(
              Fasilitas.fromJson(Map<String, dynamic>.from(kf['fasilitas'])));
        }
      }
    }

    return Kamar(
      id: json['id_kamar'] as String,
      nomorKamar: json['nomor_kamar'] as String,
      hargaPerBulan: (json['harga_per_bulan'] as num).toDouble(),
      status: json['status'] as String? ?? 'kosong',
      branchId: json['branch_id'] as String?,
      branchName: json['branch'] is Map
          ? json['branch']['nama_branch'] as String?
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      fasilitasList: parsedFasilitas,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nomor_kamar': nomorKamar,
      'harga_per_bulan': hargaPerBulan,
      'status': status,
      'branch_id': branchId,
    };
  }

  bool get isKosong => status == 'kosong';
  bool get isTerisi => status == 'terisi';

  /// Display fasilitas: dari relasi kamar_fasilitas
  String? get fasilitasDisplay {
    if (fasilitasList.isNotEmpty) {
      return fasilitasList.map((f) => f.namaFasilitas).join(', ');
    }
    return null;
  }

  Kamar copyWith({
    String? id,
    String? nomorKamar,
    double? hargaPerBulan,
    String? status,
    String? branchId,
    String? branchName,
    DateTime? createdAt,
    List<Fasilitas>? fasilitasList,
  }) {
    return Kamar(
      id: id ?? this.id,
      nomorKamar: nomorKamar ?? this.nomorKamar,
      hargaPerBulan: hargaPerBulan ?? this.hargaPerBulan,
      status: status ?? this.status,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      createdAt: createdAt ?? this.createdAt,
      fasilitasList: fasilitasList ?? this.fasilitasList,
    );
  }
}
