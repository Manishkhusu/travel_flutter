import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final String name;
  final double amount;
  final DateTime dateTime;
  final String userId;

  Expense({
    required this.id,
    required this.name,
    required this.amount,
    required this.dateTime,
    required this.userId,
  });

  factory Expense.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Expense(
      id: documentId,
      name: data['name'] ?? 'Unknown',
      amount: (data['amount'] ?? 0).toDouble(),
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      userId: data['userId'] ?? 'Unknown',
    );
  }

  static fromJson(Map<String, dynamic> data, String id) {}

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'dateTime': dateTime,
      'userId': userId,
    };
  }
}
