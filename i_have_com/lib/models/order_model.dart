import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String userId;
  final List<Map<String, dynamic>> items;
  final double totalAmount;
  final String status;
  final DateTime? createdAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.status,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'items': items,
      'totalAmount': totalAmount,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory OrderModel.fromMap(String id, Map<String, dynamic> map) {
    final timestamp = map['createdAt'];

    return OrderModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      items: (map['items'] as List<dynamic>? ?? [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList(),
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0,
      status: map['status'] as String? ?? 'pending',
      createdAt: timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }
}
