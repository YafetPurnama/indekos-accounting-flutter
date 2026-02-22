/// Model data untuk tabel `tagihan` di Supabase.
/// Core Akuntansi: Invoice / Piutang bulanan per penyewa.
class Tagihan {
  final String id;
  final String? penyewaId;
  final DateTime bulanTagihan;
  final double nominalKamar;
  final double dendaKeterlambatan;
  final double totalTagihan;
  final bool statusLunas;
  final DateTime jatuhTempo;
  final DateTime? createdAt;

  Tagihan({
    required this.id,
    this.penyewaId,
    required this.bulanTagihan,
    required this.nominalKamar,
    this.dendaKeterlambatan = 0,
    required this.totalTagihan,
    this.statusLunas = false,
    required this.jatuhTempo,
    this.createdAt,
  });

  factory Tagihan.fromJson(Map<String, dynamic> json) {
    return Tagihan(
      id: json['id_tagihan'] as String,
      penyewaId: json['penyewa_id'] as String?,
      bulanTagihan: DateTime.parse(json['bulan_tagihan'] as String),
      nominalKamar: (json['nominal_kamar'] as num).toDouble(),
      dendaKeterlambatan:
          (json['denda_keterlambatan'] as num?)?.toDouble() ?? 0,
      totalTagihan: (json['total_tagihan'] as num).toDouble(),
      statusLunas: json['status_lunas'] as bool? ?? false,
      jatuhTempo: DateTime.parse(json['jatuh_tempo'] as String),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  /// Konversi ke JSON untuk insert/update ke Supabase
  Map<String, dynamic> toJson() {
    return {
      'penyewa_id': penyewaId,
      'bulan_tagihan': bulanTagihan.toIso8601String().split('T')[0],
      'nominal_kamar': nominalKamar,
      'denda_keterlambatan': dendaKeterlambatan,
      'total_tagihan': totalTagihan,
      'status_lunas': statusLunas,
      'jatuh_tempo': jatuhTempo.toIso8601String().split('T')[0],
    };
  }

  /// Apakah tagihan sudah lewat jatuh tempo dan belum lunas (menunggak)
  bool get isMenunggak => !statusLunas && DateTime.now().isAfter(jatuhTempo);

  /// Apakah tagihan masih dalam status pending (belum lunas, belum lewat)
  bool get isPending => !statusLunas && !DateTime.now().isAfter(jatuhTempo);

  Tagihan copyWith({
    String? id,
    String? penyewaId,
    DateTime? bulanTagihan,
    double? nominalKamar,
    double? dendaKeterlambatan,
    double? totalTagihan,
    bool? statusLunas,
    DateTime? jatuhTempo,
    DateTime? createdAt,
  }) {
    return Tagihan(
      id: id ?? this.id,
      penyewaId: penyewaId ?? this.penyewaId,
      bulanTagihan: bulanTagihan ?? this.bulanTagihan,
      nominalKamar: nominalKamar ?? this.nominalKamar,
      dendaKeterlambatan: dendaKeterlambatan ?? this.dendaKeterlambatan,
      totalTagihan: totalTagihan ?? this.totalTagihan,
      statusLunas: statusLunas ?? this.statusLunas,
      jatuhTempo: jatuhTempo ?? this.jatuhTempo,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
