import 'package:cloud_firestore/cloud_firestore.dart';

class Contribution {
  final String? id;
  final String name;
  final double taka;
  final DateTime date;
  final String monthYear;
  final String ballTape;
  final int ballCount;
  final int tapeCount;

  Contribution({
    this.id,
    required this.name,
    required this.taka,
    required this.date,
    required this.monthYear,
    this.ballTape = '',
    this.ballCount = 0,
    this.tapeCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'taka': taka,
      'date': Timestamp.fromDate(date),
      'monthYear': monthYear,
      'ballTape': ballTape,
      'ballCount': ballCount,
      'tapeCount': tapeCount,
    };
  }

  factory Contribution.fromMap(Map<String, dynamic> map, {String? docId}) {
    return Contribution(
      id: docId ?? map['id'],
      name: map['name'] ?? '',
      taka: (map['taka'] ?? 0).toDouble(),
      date: map['date'] is Timestamp ? (map['date'] as Timestamp).toDate() : DateTime.parse(map['date'].toString()),
      monthYear: map['monthYear'] ?? '',
      ballTape: map['ballTape'] ?? '',
      ballCount: map['ballCount'] ?? 0,
      tapeCount: map['tapeCount'] ?? 0,
    );
  }
}
