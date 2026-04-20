import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/fund.dart';
import '../models/contribution.dart';
import '../models/ball_record.dart';
import '../models/fine_payment.dart';

class GoogleSyncService {
  static Future<bool> syncAllData({
    required String scriptUrl,
    required List<Map<String, dynamic>> playerStatus,
    required List<BallRecord> ballRecords,
    required List<Contribution> contribs,
    required List<FinePayment> payments,
    required List<Fund> funds,
  }) async {
    try {
      final Map<String, dynamic> payload = {
        'status': playerStatus.map((p) => {
          'Rank': p['total'] > 0 ? '' : '', // Will be handled by script
          'Name': p['name'],
          'Lost': p['total'],
          'TotalFine': p['totalFine'],
          'Given': p['paid'],
          'Due': p['due'],
          'Credit': p['surplus']
        }).toList(),
        
        'history': ballRecords.map((r) => {
          'Date': DateFormat('yyyy-MM-dd').format(r.date),
          'Player': r.playerName,
          'Lost': r.lostCount,
          'By': r.recordedBy
        }).toList(),

        'financials': [
          ...contribs.map((c) => {
            'Date': DateFormat('yyyy-MM-dd').format(c.date),
            'Name': c.name,
            'Type': 'Contribution',
            'Amount': c.taka,
            'Note': c.ballTape
          }),
          ...payments.map((p) => {
            'Date': DateFormat('yyyy-MM-dd').format(p.date),
            'Name': p.playerName,
            'Type': 'Fine',
            'Amount': p.amountPaid,
            'Note': p.note ?? 'Fine Collection'
          })
        ],

        'fund': funds.map((f) => {
          'Date': DateFormat('yyyy-MM-dd').format(f.date),
          'Source': f.name,
          'Type': f.type,
          'Amount': f.amount,
          'Note': f.note ?? ''
        }).toList(),
      };

      final response = await http.post(
        Uri.parse(scriptUrl),
        body: jsonEncode(payload),
      );

      return response.statusCode == 200 || response.statusCode == 302;
    } catch (e) {
      print('Sync Error: $e');
      return false;
    }
  }
}
