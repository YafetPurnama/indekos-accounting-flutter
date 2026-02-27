/// Mencatat riwayat pemotongan deposit penyewa karena kerusakan/pelanggaran.
class DepositDeduction {
  final String id;
  final String penyewaId;
  final double nominal;
  final String alasan;
  final DateTime tanggalDeduction;
  final DateTime? createdAt;
  final String? createdBy;

  DepositDeduction({
    required this.id,
    required this.penyewaId,
    required this.nominal,
    required this.alasan,
    required this.tanggalDeduction,
    this.createdAt,
    this.createdBy,
  });

  factory DepositDeduction.fromJson(Map<String, dynamic> json) {
    return DepositDeduction(
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

  DepositDeduction copyWith({
    String? id,
    String? penyewaId,
    double? nominal,
    String? alasan,
    DateTime? tanggalDeduction,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return DepositDeduction(
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
