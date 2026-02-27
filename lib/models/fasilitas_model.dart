/// Data u/ tabel `fasilitas`
class Fasilitas {
  final String id;
  final String namaFasilitas;
  final double hargaUnit;
  final int qtyUnit;
  final String? keterangan;
  final DateTime? tanggalPembelian;
  final int umurEkonomisTahun;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;

  Fasilitas({
    required this.id,
    required this.namaFasilitas,
    this.hargaUnit = 0,
    this.qtyUnit = 0,
    this.keterangan,
    this.tanggalPembelian,
    this.umurEkonomisTahun = 5,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
  });

  factory Fasilitas.fromJson(Map<String, dynamic> json) {
    return Fasilitas(
      id: json['id_fasilitas'] as String,
      namaFasilitas: json['nama_fasilitas'] as String,
      hargaUnit: (json['harga_unit'] as num?)?.toDouble() ?? 0,
      qtyUnit: (json['qty_unit'] as num?)?.toInt() ?? 0,
      keterangan: json['keterangan_fasilitas'] as String?,
      tanggalPembelian: json['tanggal_pembelian'] != null
          ? DateTime.parse(json['tanggal_pembelian'] as String)
          : null,
      umurEkonomisTahun:
          (json['umur_ekonomis_tahun'] as num?)?.toInt() ?? 5,
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
      'nama_fasilitas': namaFasilitas,
      'harga_unit': hargaUnit,
      'qty_unit': qtyUnit,
      'keterangan_fasilitas': keterangan,
      'umur_ekonomis_tahun': umurEkonomisTahun,
      if (tanggalPembelian != null)
        'tanggal_pembelian':
            tanggalPembelian!.toIso8601String().split('T')[0],
    };
  }

  // ── Depresiasi (Metode Garis Lurus / Straight Line) ──────────

  /// Total harga perolehan seluruh unit fasilitas ini
  double get totalHargaPerolehan => hargaUnit * qtyUnit;

  /// Penyusutan per tahun = Total Harga Perolehan / Umur Ekonomis
  double get depresiasiPerTahun {
    if (umurEkonomisTahun <= 0) return 0;
    return totalHargaPerolehan / umurEkonomisTahun;
  }

  /// Penyusutan per bulan
  double get depresiasiPerBulan => depresiasiPerTahun / 12;

  Fasilitas copyWith({
    String? id,
    String? namaFasilitas,
    double? hargaUnit,
    int? qtyUnit,
    String? keterangan,
    DateTime? tanggalPembelian,
    int? umurEkonomisTahun,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) {
    return Fasilitas(
      id: id ?? this.id,
      namaFasilitas: namaFasilitas ?? this.namaFasilitas,
      hargaUnit: hargaUnit ?? this.hargaUnit,
      qtyUnit: qtyUnit ?? this.qtyUnit,
      keterangan: keterangan ?? this.keterangan,
      tanggalPembelian: tanggalPembelian ?? this.tanggalPembelian,
      umurEkonomisTahun: umurEkonomisTahun ?? this.umurEkonomisTahun,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}
