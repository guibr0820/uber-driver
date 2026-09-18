import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionItem {
  final String type; // deposit | withdraw
  final double amount;
  final DateTime createdAt;
  final String status;

  TransactionItem({
    required this.type,
    required this.amount,
    required this.createdAt,
    required this.status,
  });
}
