import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/fund.dart';
import '../models/contribution.dart';
import '../models/ball_record.dart';
import '../models/fine_payment.dart';

class CsvExportService {
  static Future<void> exportFundsToCsv(List<Fund> funds) async {
    String csv = 'Date,Source,Type,Amount,Note\n';
    for (var f in funds) {
      csv += '${DateFormat('yyyy-MM-dd').format(f.date)},"${f.name}",${f.type},${f.amount},"${f.note ?? ''}"\n';
    }
    await _shareCsv(csv, 'club_fund_backup.csv');
  }

  static Future<void> exportFinancialsToCsv(List<Contribution> contribs, List<FinePayment> payments) async {
    String csv = 'Date,Name,Type,Amount,Description\n';
    final List<dynamic> combined = [...contribs, ...payments];
    combined.sort((a, b) => b.date.compareTo(a.date));

    for (var item in combined) {
      bool isFine = item is FinePayment;
      String date = DateFormat('yyyy-MM-dd').format(item.date);
      String name = isFine ? item.playerName : item.name;
      String type = isFine ? 'Fine' : 'Contribution';
      double amount = isFine ? item.amountPaid : item.taka;
      String desc = isFine ? (item.note ?? '') : item.ballTape;
      csv += '$date,"$name",$type,$amount,"$desc"\n';
    }
    await _shareCsv(csv, 'financial_records_backup.csv');
  }

  static Future<void> exportRecordsToCsv(List<BallRecord> records) async {
    String csv = 'Date,Player Name,Balls Lost,Recorded By\n';
    final sorted = List<BallRecord>.from(records)..sort((a, b) => b.date.compareTo(a.date));
    for (var r in sorted) {
      csv += '${DateFormat('yyyy-MM-dd').format(r.date)},"${r.playerName}",${r.lostCount},"${r.recordedBy}"\n';
    }
    await _shareCsv(csv, 'ball_loss_records_backup.csv');
  }

  static Future<void> _shareCsv(String csvContent, String fileName) async {
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/$fileName';
    final file = File(path);
    await file.writeAsString(csvContent);
    await Share.shareXFiles([XFile(path)], text: 'Excel Backup');
  }
}
