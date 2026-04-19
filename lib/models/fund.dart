import 'package:cloud_firestore/cloud_firestore.dart';

class Fund {
  final String? id;
  final String name;
  final double amount;
  final DateTime date;
  final String? note;

  Fund({
    this.id,
    required this.name,
    required this.amount,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'note': note,
    };
  }

  factory Fund.fromMap(Map<String, dynamic> map, {String? docId}) {
    return Fund(
      id: docId,
      name: map['name'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      date: (map['date'] as Timestamp).toDate(),
      note: map['note'],
    );
  }
}
