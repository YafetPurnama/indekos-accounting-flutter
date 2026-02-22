/// Model data untuk tabel `pembayaran` di Supabase.
/// Core Akuntansi: Transaksi pembayaran & bukti bayar.
class Pembayaran {
  final String id;
  final String? tagihanId;
  final DateTime? tanggalBayar;
  final double nominalDibayar;
  final String? metodePembayaran; // 'Transfer BCA', 'Tunai', 'QRIS'
  final String? buktiFotoUrl;
  final String statusValidasi; // 'pending', 'valid', 'ditolak'
  final DateTime? createdAt;

  Pembayaran({
    required this.id,
    this.tagihanId,
    this.tanggalBayar,
    required this.nominalDibayar,
    this.metodePembayaran,
    this.buktiFotoUrl,
    this.statusValidasi = 'pending',
    this.createdAt,
  });

  /// Buat Pembayaran dari JSON response Supabase
  factory Pembayaran.fromJson(Map<String, dynamic> json) {
    return Pembayaran(
      id: json['id_pembayaran'] as String,
      tagihanId: json['tagihan_id'] as String?,
      tanggalBayar: json['tanggal_bayar'] != null
          ? DateTime.parse(json['tanggal_bayar'] as String)
          : null,
      nominalDibayar: (json['nominal_dibayar'] as num).toDouble(),
      metodePembayaran: json['metode_pembayaran'] as String?,
      buktiFotoUrl: json['bukti_foto_url'] as String?,
      statusValidasi: json['status_validasi'] as String? ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  /// Konversi ke JSON untuk insert/update ke Supabase
  Map<String, dynamic> toJson() {
    return {
      'tagihan_id': tagihanId,
      'nominal_dibayar': nominalDibayar,
      'metode_pembayaran': metodePembayaran,
      'bukti_foto_url': buktiFotoUrl,
      'status_validasi': statusValidasi,
    };
  }

  /// Apakah pembayaran sudah divalidasi
  bool get isValid => statusValidasi == 'valid';

  /// Apakah pembayaran masih pending
  bool get isPending => statusValidasi == 'pending';

  /// Apakah pembayaran ditolak
  bool get isDitolak => statusValidasi == 'ditolak';

  Pembayaran copyWith({
    String? id,
    String? tagihanId,
    DateTime? tanggalBayar,
    double? nominalDibayar,
    String? metodePembayaran,
    String? buktiFotoUrl,
    String? statusValidasi,
    DateTime? createdAt,
  }) {
    return Pembayaran(
      id: id ?? this.id,
      tagihanId: tagihanId ?? this.tagihanId,
      tanggalBayar: tanggalBayar ?? this.tanggalBayar,
      nominalDibayar: nominalDibayar ?? this.nominalDibayar,
      metodePembayaran: metodePembayaran ?? this.metodePembayaran,
      buktiFotoUrl: buktiFotoUrl ?? this.buktiFotoUrl,
      statusValidasi: statusValidasi ?? this.statusValidasi,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
