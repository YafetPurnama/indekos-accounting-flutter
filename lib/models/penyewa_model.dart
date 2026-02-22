/// Model data untuk tabel `penyewa` di Supabase.
/// Merepresentasikan relasi antara user (penyewa) dengan kamar yang disewa.
class Penyewa {
  final String id;
  final String? userId;
  final String? kamarId;
  final DateTime tanggalMasuk;
  final String? nomorWhatsapp;
  final double deposit;
  final bool statusAktif;
  final DateTime? createdAt;

  Penyewa({
    required this.id,
    this.userId,
    this.kamarId,
    required this.tanggalMasuk,
    this.nomorWhatsapp,
    this.deposit = 0,
    this.statusAktif = true,
    this.createdAt,
  });

  /// Buat Penyewa dari JSON response Supabase
  factory Penyewa.fromJson(Map<String, dynamic> json) {
    return Penyewa(
      id: json['id_penyewa'] as String,
      userId: json['user_id'] as String?,
      kamarId: json['kamar_id'] as String?,
      tanggalMasuk: DateTime.parse(json['tanggal_masuk'] as String),
      nomorWhatsapp: json['nomor_whatsapp'] as String?,
      deposit: (json['deposit'] as num?)?.toDouble() ?? 0,
      statusAktif: json['status_aktif'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  /// Konversi ke JSON untuk insert/update ke Supabase
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'kamar_id': kamarId,
      'tanggal_masuk': tanggalMasuk.toIso8601String().split('T')[0],
      'nomor_whatsapp': nomorWhatsapp,
      'deposit': deposit,
      'status_aktif': statusAktif,
    };
  }

  Penyewa copyWith({
    String? id,
    String? userId,
    String? kamarId,
    DateTime? tanggalMasuk,
    String? nomorWhatsapp,
    double? deposit,
    bool? statusAktif,
    DateTime? createdAt,
  }) {
    return Penyewa(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      kamarId: kamarId ?? this.kamarId,
      tanggalMasuk: tanggalMasuk ?? this.tanggalMasuk,
      nomorWhatsapp: nomorWhatsapp ?? this.nomorWhatsapp,
      deposit: deposit ?? this.deposit,
      statusAktif: statusAktif ?? this.statusAktif,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
