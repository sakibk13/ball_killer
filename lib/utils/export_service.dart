import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../models/contribution.dart';
import '../models/fine_payment.dart';

class ExportService {
  static Future<void> exportFinancialSummaryReport({
    required String monthYear,
    required Map<String, Map<String, double>> data,
  }) async {
    final pdf = pw.Document();
    pw.MemoryImage? logoImage;
    try {
      final ByteData logoBytes = await rootBundle.load('assets/icon/logo3.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (e) {
      debugPrint('Error loading logo: $e');
    }

    final String dateStr = monthYear == 'Overall' ? 'OVERALL' : DateFormat('MMMM yyyy').format(DateFormat('MM-yyyy').parse(monthYear));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        header: (context) => _buildPdfHeader('FINANCIAL SUMMARY REPORT', logoImage),
        footer: (context) => _buildPdfFooter('Official Financial Summary Document', context.pageNumber),
        build: (pw.Context context) {
          List<pw.Widget> widgets = [];
          
          widgets.add(
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('PERIOD: ${dateStr.toUpperCase()}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                pw.Text('DATE: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}', style: pw.TextStyle(fontSize: 8)),
              ],
            ),
          );
          widgets.add(pw.SizedBox(height: 16));

          for (var monthKey in data.keys) {
            Map<String, double> players = data[monthKey]!;
            double monthlyTotal = players.values.fold(0, (s, v) => s + v);
            DateTime date = DateFormat('MM-yyyy').parse(monthKey);

            widgets.add(
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(DateFormat('MMMM yyyy').format(date).toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.Text('TOTAL: BDT ${monthlyTotal.toInt()}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.blue800)),
                  ],
                ),
              ),
            );

            widgets.add(
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.3),
                columnWidths: {0: const pw.FlexColumnWidth(), 1: const pw.FixedColumnWidth(100)},
                children: [
                  ...players.entries.map((e) {
                    return pw.TableRow(
                      children: [
                        _buildDataCell(e.key.toUpperCase()),
                        _buildDataCell('BDT ${e.value.toInt()}', align: pw.TextAlign.right, fontWeight: pw.FontWeight.bold),
                      ],
                    );
                  }),
                ],
              ),
            );
            widgets.add(pw.SizedBox(height: 15));
          }

          return widgets;
        },
      ),
    );
    await _saveAndShare(pdf, 'financial_summary_${monthYear.replaceAll('-', '_')}.pdf');
  }

  static Future<void> exportFinancialDetailedReport({
    required String monthYear,
    required List<dynamic> contributions,
  }) async {
    final pdf = pw.Document();
    pw.MemoryImage? logoImage;
    try {
      final ByteData logoBytes = await rootBundle.load('assets/icon/logo3.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (e) {
      debugPrint('Error loading logo: $e');
    }

    final String dateStr = monthYear == 'Overall' ? 'OVERALL' : DateFormat('MMMM yyyy').format(DateFormat('MM-yyyy').parse(monthYear));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        header: (context) => _buildPdfHeader('DETAILED FINANCIAL HISTORY', logoImage),
        footer: (context) => _buildPdfFooter('Official Financial Transaction History', context.pageNumber),
        build: (pw.Context context) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('PERIOD: ${dateStr.toUpperCase()}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                pw.Text('DATE: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}', style: pw.TextStyle(fontSize: 8)),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.3),
              columnWidths: {
                0: const pw.FixedColumnWidth(50), 
                1: const pw.FlexColumnWidth(), 
                2: const pw.FlexColumnWidth(1.2), 
                3: const pw.FixedColumnWidth(60)
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue900),
                  children: [
                    _buildHeaderCell('DATE'), 
                    _buildHeaderCell('NAME'), 
                    _buildHeaderCell('NOTE/ITEMS'), 
                    _buildHeaderCell('AMOUNT'),
                  ],
                ),
                ...contributions.map((item) {
                  bool isFine = item is FinePayment;
                  String name = isFine ? item.playerName : (item as Contribution).name;
                  String note = isFine ? "Fine Collection" : (item as Contribution).ballTape;
                  if (isFine && item.note != null && item.note!.isNotEmpty) note += " | ${item.note}";
                  double amount = isFine ? item.amountPaid : (item as Contribution).taka;
                  DateTime date = isFine ? item.date : (item as Contribution).date;

                  return pw.TableRow(
                    children: [
                      _buildDataCell(DateFormat('dd MMM').format(date)),
                      _buildDataCell(name.toUpperCase(), fontWeight: pw.FontWeight.bold),
                      _buildDataCell(note, fontSize: 7, color: isFine ? PdfColors.green800 : null),
                      _buildDataCell('${amount.toInt()} ৳', align: pw.TextAlign.right, fontWeight: pw.FontWeight.bold, color: isFine ? PdfColors.green800 : null),
                    ],
                  );
                }),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    pw.SizedBox(),
                    _buildDataCell('TOTAL COLLECTION', fontWeight: pw.FontWeight.bold),
                    pw.SizedBox(),
                    _buildDataCell('${contributions.fold(0.0, (s, c) => s + (c is FinePayment ? c.amountPaid : (c as Contribution).taka)).toInt()} ৳', align: pw.TextAlign.right, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );
    await _saveAndShare(pdf, 'financial_detailed_${monthYear.replaceAll('-', '_')}.pdf');
  }

  static Future<void> exportLeaderboard({
    required String monthYear,
    required List<Map<String, dynamic>> players,
  }) async {
    final pdf = pw.Document();
    pw.MemoryImage? logoImage;
    try {
      final ByteData logoBytes = await rootBundle.load('assets/icon/logo3.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (e) {
      debugPrint('Error loading logo: $e');
    }

    final sortedPlayers = List<Map<String, dynamic>>.from(players)
      ..sort((a, b) {
        int cmp = (b['total'] as num).compareTo(a['total'] as num);
        if (cmp != 0) return cmp;
        return (a['name'] as String).toLowerCase().compareTo((b['name'] as String).toLowerCase());
      });

    final String dateStr = monthYear == 'Overall' ? 'OVERALL' : DateFormat('MMMM yyyy').format(DateFormat('MM-yyyy').parse(monthYear));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        header: (context) => _buildPdfHeader('CLUB LEADERBOARD', logoImage),
        footer: (context) => _buildPdfFooter('Official Leaderboard Ranking', context.pageNumber),
        build: (pw.Context context) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('PERIOD: ${dateStr.toUpperCase()}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                pw.Text('DATE: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}', style: pw.TextStyle(fontSize: 8)),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.3),
              columnWidths: {
                0: const pw.FixedColumnWidth(30), 
                1: const pw.FixedColumnWidth(40),
                2: const pw.FlexColumnWidth(), 
                3: const pw.FixedColumnWidth(60)
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue900),
                  children: [
                    _buildHeaderCell('RANK'), 
                    _buildHeaderCell('PHOTO'),
                    _buildHeaderCell('PLAYER NAME'), 
                    _buildHeaderCell('BALLS LOST'),
                  ],
                ),
                ...sortedPlayers.asMap().entries.map((entry) {
                  final i = entry.key;
                  final p = entry.value;
                  pw.MemoryImage? playerPhoto;
                  if (p['photoUrl'] != null && p['photoUrl'].isNotEmpty) {
                    try {
                      playerPhoto = pw.MemoryImage(base64Decode(p['photoUrl']));
                    } catch (e) {}
                  }

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: i % 2 == 0 ? PdfColors.white : PdfColors.grey50),
                    children: [
                      _buildDataCell('${i + 1}', align: pw.TextAlign.center),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: pw.Center(
                          child: pw.Container(
                            height: 25, width: 25,
                            decoration: pw.BoxDecoration(
                              shape: pw.BoxShape.circle,
                              color: PdfColors.grey200,
                              image: playerPhoto != null ? pw.DecorationImage(image: playerPhoto, fit: pw.BoxFit.cover) : null,
                            ),
                            child: playerPhoto == null ? pw.Center(child: pw.Text(p['name'][0].toUpperCase(), style: const pw.TextStyle(fontSize: 8))) : null,
                          ),
                        ),
                      ),
                      _buildDataCell(p['name'].toString().toUpperCase(), fontWeight: pw.FontWeight.bold),
                      _buildDataCell('${p['total']}', align: pw.TextAlign.center, color: i < 3 ? PdfColors.red800 : null, fontWeight: i < 3 ? pw.FontWeight.bold : null),
                    ],
                  );
                }),
              ],
            ),
          ];
        },
      ),
    );
    await _saveAndShare(pdf, 'leaderboard_${monthYear.replaceAll('-', '_')}.pdf');
  }

  static Future<void> exportFineReport({
    required String monthYear,
    required List<Map<String, dynamic>> sortedPlayers,
  }) async {
    final pdf = pw.Document();
    pw.MemoryImage? logoImage;
    try {
      final ByteData logoBytes = await rootBundle.load('assets/icon/logo3.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (e) {
      debugPrint('Error loading logo: $e');
    }

    final String dateStr = monthYear == 'Overall' ? 'OVERALL' : DateFormat('MMMM yyyy').format(DateFormat('MM-yyyy').parse(monthYear));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        header: (context) => _buildPdfHeader('OFFICIAL FINE REPORT', logoImage),
        footer: (context) => _buildPdfFooter('Official Fine Record Document', context.pageNumber),
        build: (pw.Context context) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('PERIOD: ${dateStr.toUpperCase()}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                pw.Text('DATE: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}', style: pw.TextStyle(fontSize: 8)),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.3),
              columnWidths: {
                0: const pw.FixedColumnWidth(25), 
                1: const pw.FixedColumnWidth(30),
                2: const pw.FlexColumnWidth(), 
                3: const pw.FixedColumnWidth(35), 
                4: const pw.FixedColumnWidth(55),
                5: const pw.FixedColumnWidth(55),
                6: const pw.FixedColumnWidth(55),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue900),
                  children: [
                    _buildHeaderCell('RK'), 
                    _buildHeaderCell('DP'),
                    _buildHeaderCell('PLAYER NAME'), 
                    _buildHeaderCell('LST'), 
                    _buildHeaderCell('TOTAL'),
                    _buildHeaderCell('GIVEN'),
                    _buildHeaderCell('DUE'),
                  ],
                ),
                ...sortedPlayers.asMap().entries.where((e) => (e.value['total'] as int) > 0).map((entry) {
                  final i = entry.key;
                  final p = entry.value;
                  final lost = p['total'] as int;
                  final fine = p['totalFine'] as double;
                  final given = p['paid'] as double;
                  final due = p['due'] as double;

                  pw.MemoryImage? playerPhoto;
                  if (p['photoUrl'] != null && p['photoUrl'].isNotEmpty) {
                    try {
                      playerPhoto = pw.MemoryImage(base64Decode(p['photoUrl']));
                    } catch (e) {}
                  }
                  
                  return pw.TableRow(
                    children: [
                      _buildDataCell('${i + 1}', align: pw.TextAlign.center),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: pw.Center(
                          child: pw.Container(
                            height: 20, width: 20,
                            decoration: pw.BoxDecoration(
                              shape: pw.BoxShape.circle,
                              color: PdfColors.grey200,
                              image: playerPhoto != null ? pw.DecorationImage(image: playerPhoto, fit: pw.BoxFit.cover) : null,
                            ),
                            child: playerPhoto == null ? pw.Center(child: pw.Text(p['name'][0].toUpperCase(), style: const pw.TextStyle(fontSize: 6))) : null,
                          ),
                        ),
                      ),
                      _buildDataCell(p['name'].toString().toUpperCase(), fontWeight: pw.FontWeight.bold, fontSize: 7),
                      _buildDataCell('$lost', align: pw.TextAlign.center, fontSize: 7),
                      _buildDataCell('${fine.toInt()}৳', align: pw.TextAlign.right, fontWeight: pw.FontWeight.bold, fontSize: 7),
                      _buildDataCell('${given.toInt()}৳', align: pw.TextAlign.right, color: PdfColors.green700, fontSize: 7),
                      _buildDataCell('${due.toInt()}৳', align: pw.TextAlign.right, color: due > 0 ? PdfColors.red700 : PdfColors.green700, fontWeight: pw.FontWeight.bold, fontSize: 7),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 15),
            pw.Text('Note: Fines must be paid to the club treasurer.', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
          ];
        },
      ),
    );
    await _saveAndShare(pdf, 'fine_report_${monthYear.replaceAll('-', '_')}.pdf');
  }

  static pw.Widget _buildPdfHeader(String title, pw.MemoryImage? logo) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('BALL KILLER', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                pw.Text('by Mini Cricket', style: pw.TextStyle(fontSize: 14, fontStyle: pw.FontStyle.italic, color: PdfColors.orange800)),
              ],
            ),
            if (logo != null)
              pw.Container(height: 50, width: 50, child: pw.Image(logo)),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Text(title, style: pw.TextStyle(fontSize: 10, letterSpacing: 1.5, color: PdfColors.grey700, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Divider(thickness: 1.5, color: PdfColors.blue900),
        pw.SizedBox(height: 8),
      ],
    );
  }

  static pw.Widget _buildPdfFooter(String docType, int pageNum) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300, thickness: 0.5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(docType, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
            pw.Text('Page $pageNum', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey400)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildHeaderCell(String text) {
    return pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(text, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 8)));
  }

  static pw.Widget _buildDataCell(String text, {pw.TextAlign align = pw.TextAlign.left, pw.FontWeight? fontWeight, PdfColor? color, double fontSize = 8}) {
    return pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(text, textAlign: align, style: pw.TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: color)));
  }

  static Future<void> _saveAndShare(pw.Document pdf, String fileName) async {
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/$fileName");
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)], text: 'Ball Killer Club Report');
  }
}
