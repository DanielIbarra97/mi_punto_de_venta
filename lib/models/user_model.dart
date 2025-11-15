import 'package:cloud_firestore/cloud_firestore.dart';

class UserData {
  final String uid;
  final String email;
  final String role; // 'vendedor', 'administrador', 'consultor'
  final Timestamp createdAt;

  UserData({
    required this.uid,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  factory UserData.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserData(
      uid: doc.id,
      email: data['email'] ?? '',
      role: data['role'] ?? 'vendedor', // Valor por defecto
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
}