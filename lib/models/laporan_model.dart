class LaporanModel {
  final String idLaporan;
  final String? penyewaId;
  final String? kamarId;
  final String judul;
  final String deskripsi;
  final double perkiraanBiayaPerbaikan;
  final String? fotoUrl;
  final String status;
  final DateTime createdAt;

  // Joined properties (opsional saat fetch dengan table lain)
  final String? namaPenyewa;
  final String? nomorKamar;

  LaporanModel({
    required this.idLaporan,
    this.penyewaId,
    this.kamarId,
    required this.judul,
    required this.deskripsi,
    this.perkiraanBiayaPerbaikan = 0,
    this.fotoUrl,
    required this.status,
    required this.createdAt,
    this.namaPenyewa,
    this.nomorKamar,
  });

  factory LaporanModel.fromJson(Map<String, dynamic> json) {
    // Handling relasi
    String? tmpNamaPenyewa;
    if (json['penyewa'] != null && json['penyewa']['users'] != null) {
      tmpNamaPenyewa = json['penyewa']['users']['nama'];
    }

    String? tmpNomorKamar;
    if (json['kamar'] != null) {
      tmpNomorKamar = json['kamar']['nomor_kamar'];
    }

    return LaporanModel(
      idLaporan: json['id_laporan'] ?? '',
      penyewaId: json['penyewa_id'],
      kamarId: json['kamar_id'],
      judul: json['judul'] ?? '',
      deskripsi: json['deskripsi'] ?? '',
      perkiraanBiayaPerbaikan: (json['perkiraan_biaya_perbaikan'] ?? 0).toDouble(),
      fotoUrl: json['foto_url'],
      status: json['status'] ?? 'menunggu_respon',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      namaPenyewa: tmpNamaPenyewa,
      nomorKamar: tmpNomorKamar,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_laporan': idLaporan,
      'penyewa_id': penyewaId,
      'kamar_id': kamarId,
      'judul': judul,
      'deskripsi': deskripsi,
      'perkiraan_biaya_perbaikan': perkiraanBiayaPerbaikan,
      'foto_url': fotoUrl,
      'status': status,
    };
  }
}
