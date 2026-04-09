import 'package:cloud_firestore/cloud_firestore.dart';

class Inventory {
  final String? id;
  final DateTime date;
  final int ballsBrought;
  final int tapesBrought;
  final int ballsLost;
  final int totalStock;
  final bool isStockUpdate;
  final String monthYear;
  final String recordedBy;

  Inventory({
    this.id,
    required this.date,
    this.ballsBrought = 0,
    this.tapesBrought = 0,
    this.ballsLost = 0,
    this.totalStock = 0,
    this.isStockUpdate = false,
    required this.monthYear,
    required this.recordedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'ballsBrought': ballsBrought,
      'tapesBrought': tapesBrought,
      'ballsLost': ballsLost,
      'totalStock': totalStock,
      'isStockUpdate': isStockUpdate,
      'monthYear': monthYear,
      'recordedBy': recordedBy,
    };
  }

  factory Inventory.fromMap(Map<String, dynamic> map, {String? docId}) {
    return Inventory(
      id: docId ?? map['id'],
      date: (map['date'] as Timestamp).toDate(),
      ballsBrought: map['ballsBrought'] ?? 0,
      tapesBrought: map['tapesBrought'] ?? 0,
      ballsLost: map['ballsLost'] ?? 0,
      totalStock: map['totalStock'] ?? 0,
      isStockUpdate: map['isStockUpdate'] ?? false,
      monthYear: map['monthYear'] ?? '',
      recordedBy: map['recordedBy'] ?? '',
    );
  }
}
