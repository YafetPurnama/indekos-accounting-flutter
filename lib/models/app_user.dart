import 'package:cloud_firestore/cloud_firestore.dart';

/// Sv informasi dari Firebase Auth + role dari Firestore.
class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? role;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.role,
    required this.createdAt,
  });

  /// Apakah user sudah memilih role
  bool get hasRole => role != null && role!.isNotEmpty;

  /// Apakah user adalah pemilik
  bool get isPemilik => role == 'pemilik';

  /// Apakah user adalah penyewa
  bool get isPenyewa => role == 'penyewa';

  /// Buat AppUser dari Firestore document
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'],
      role: data['role'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Konversi ke Map untuk disimpan ke Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Buat salinan dengan field yang diubah
  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? role,
    DateTime? createdAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
