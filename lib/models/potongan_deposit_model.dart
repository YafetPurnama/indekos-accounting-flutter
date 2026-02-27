/// Mencatat riwayat pemotongan deposit penyewa karena kerusakan/pelanggaran.
class PotonganDeposit {
  final String id;
  final String penyewaId;
  final double nominal;
  final String alasan;
  final DateTime tanggalDeduction;
  final DateTime? createdAt;
  final String? createdBy;

  PotonganDeposit({
    required this.id,
    required this.penyewaId,
    required this.nominal,
    required this.alasan,
    required this.tanggalDeduction,
    this.createdAt,
    this.createdBy,
  });

  factory PotonganDeposit.fromJson(Map<String, dynamic> json) {
    return PotonganDeposit(
      id: json['id_potongan_deposit'] as String,
      penyewaId: json['id_penyewa'] as String,
      nominal: (json['nominal'] as num?)?.toDouble() ?? 0,
      alasan: json['alasan'] as String? ?? '',
      tanggalDeduction: DateTime.parse(json['tanggal_deduction'] as String),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      createdBy: json['created_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_penyewa': penyewaId,
      'nominal': nominal,
      'alasan': alasan,
      'tanggal_deduction': tanggalDeduction.toIso8601String().split('T')[0],
    };
  }

  PotonganDeposit copyWith({
    String? id,
    String? penyewaId,
    double? nominal,
    String? alasan,
    DateTime? tanggalDeduction,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return PotonganDeposit(
      id: id ?? this.id,
      penyewaId: penyewaId ?? this.penyewaId,
      nominal: nominal ?? this.nominal,
      alasan: alasan ?? this.alasan,
      tanggalDeduction: tanggalDeduction ?? this.tanggalDeduction,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
