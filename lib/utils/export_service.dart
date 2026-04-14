import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class ExportService {
  static Future<void> exportLeaderboard({
    required String monthYear,
    required List<Map<String, dynamic>> players,
  }) async {
    final pdf = pw.Document();
    
    pw.MemoryImage? logoImage;
    pw.Font? banglaFont;
    try {
      final ByteData logoBytes = await rootBundle.load('assets/icon/logo3.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
      
      final ByteData fontBytes = await rootBundle.load('assets/bangla.ttf');
      banglaFont = pw.Font.ttf(fontBytes);
    } catch (e) {
      debugPrint('Error loading assets: $e');
    }

    final sortedPlayers = List<Map<String, dynamic>>.from(players)
      ..sort((a, b) {
        int cmp = (b['total'] as num).compareTo(a['total'] as num);
        if (cmp != 0) return cmp;
        return (a['name'] as String).toLowerCase().compareTo((b['name'] as String).toLowerCase());
      });

    const String banglaQuote = "“খেলাধুলায় বাড়ে বল, মাদক ছেড়ে খেলতে চল।”";
    final String dateStr = monthYear == 'Overall' 
        ? 'OVERALL' 
        : DateFormat('MMMM yyyy').format(DateFormat('MM-yyyy').parse(monthYear));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        header: (context) => pw.Column(
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
                if (logoImage != null)
                  pw.Container(height: 50, width: 50, child: pw.Image(logoImage)),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Text('OFFICIAL LEADERBOARD', style: pw.TextStyle(fontSize: 10, letterSpacing: 1.5, color: PdfColors.grey700, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Divider(thickness: 1.5, color: PdfColors.blue900),
            pw.SizedBox(height: 8),
          ],
        ),
        footer: (context) => pw.Column(
          children: [
            pw.Divider(color: PdfColors.grey300, thickness: 0.5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Official Club Ranking Document', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey400)),
              ],
            ),
          ],
        ),
        build: (pw.Context context) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('PERIOD: ${dateStr.toUpperCase()}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                pw.Text('DATE: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}', style: pw.TextStyle(fontSize: 8)),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: const pw.BoxDecoration(
                color: PdfColors.grey100,
                border: pw.Border(left: pw.BorderSide(color: PdfColors.blue900, width: 3)),
              ),
              child: pw.Text(banglaQuote, style: pw.TextStyle(fontSize: 12, color: PdfColors.blueGrey800, font: banglaFont)),
            ),
            pw.SizedBox(height: 16),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.3),
              columnWidths: {0: const pw.FixedColumnWidth(40), 1: const pw.FlexColumnWidth(), 2: const pw.FixedColumnWidth(70)},
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue900),
                  children: [_buildHeaderCell('RANK'), _buildHeaderCell('PLAYER NAME'), _buildHeaderCell('LOST')],
                ),
                ...sortedPlayers.asMap().entries.map((entry) {
                  final i = entry.key;
                  final p = entry.value;
                  final lost = p['total'] as int;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: i % 2 == 0 ? PdfColors.white : PdfColors.grey50),
                    children: [
                      _buildDataCell('${i + 1}', align: pw.TextAlign.center),
                      _buildDataCell(p['name'].toString().toUpperCase(), fontWeight: pw.FontWeight.bold),
                      _buildDataCell('$lost', align: pw.TextAlign.center, fontWeight: pw.FontWeight.bold, color: lost > 0 ? PdfColors.red700 : PdfColors.green700),
                    ],
                  );
                }),
              ],
            ),
          ];
        },
      ),
    );
    await _previewPdf(pdf, 'leaderboard_${monthYear.replaceAll('-', '_')}');
  }

  static Future<void> exportFineReport({
    required String monthYear,
    required List<Map<String, dynamic>> sortedPlayers,
  }) async {
    final pdf = pw.Document();
    pw.MemoryImage? logoImage;
    pw.Font? banglaFont;
    try {
      final ByteData logoBytes = await rootBundle.load('assets/icon/logo3.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
      final ByteData fontBytes = await rootBundle.load('assets/bangla.ttf');
      banglaFont = pw.Font.ttf(fontBytes);
    } catch (e) {
      debugPrint('Error loading assets: $e');
    }

    const String banglaQuote = "“খেলাধুলায় বাড়ে বল, মাদক ছেড়ে খেলতে চল।”";
    final String dateStr = DateFormat('MMMM yyyy').format(DateFormat('MM-yyyy').parse(monthYear));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        header: (context) => pw.Column(
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
                if (logoImage != null)
                  pw.Container(height: 50, width: 50, child: pw.Image(logoImage)),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Text('OFFICIAL FINE REPORT', style: pw.TextStyle(fontSize: 10, letterSpacing: 1.5, color: PdfColors.grey700, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Divider(thickness: 1.5, color: PdfColors.blue900),
            pw.SizedBox(height: 8),
          ],
        ),
        footer: (context) => pw.Column(
          children: [
            pw.Divider(color: PdfColors.grey300, thickness: 0.5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Official Fine Record Document', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                pw.Text('Page ${context.pageNumber}', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey400)),
              ],
            ),
          ],
        ),
        build: (pw.Context context) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('PERIOD: ${dateStr.toUpperCase()}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                pw.Text('DATE: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}', style: pw.TextStyle(fontSize: 8)),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: const pw.BoxDecoration(
                color: PdfColors.grey100,
                border: pw.Border(left: pw.BorderSide(color: PdfColors.blue900, width: 3)),
              ),
              child: pw.Text(banglaQuote, style: pw.TextStyle(fontSize: 12, color: PdfColors.blueGrey800, font: banglaFont)),
            ),
            pw.SizedBox(height: 16),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.3),
              columnWidths: {0: const pw.FixedColumnWidth(40), 1: const pw.FlexColumnWidth(), 2: const pw.FixedColumnWidth(50), 3: const pw.FixedColumnWidth(80)},
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue900),
                  children: [_buildHeaderCell('RANK'), _buildHeaderCell('PLAYER NAME'), _buildHeaderCell('LOST'), _buildHeaderCell('TOTAL FINE')],
                ),
                ...sortedPlayers.asMap().entries.where((e) => (e.value['total'] as int) > 0).map((entry) {
                  final i = entry.key;
                  final p = entry.value;
                  final lost = p['total'] as int;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: i % 2 == 0 ? PdfColors.white : PdfColors.grey50),
                    children: [
                      _buildDataCell('${i + 1}', align: pw.TextAlign.center),
                      _buildDataCell(p['name'].toString().toUpperCase(), fontWeight: pw.FontWeight.bold),
                      _buildDataCell('$lost', align: pw.TextAlign.center),
                      _buildDataCell('BDT ${lost * 50}', align: pw.TextAlign.right, color: PdfColors.red700, fontWeight: pw.FontWeight.bold),
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
    await _previewPdf(pdf, 'fine_report_$monthYear');
  }

  static pw.Widget _buildHeaderCell(String text) {
    return pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(text, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 8)));
  }

  static pw.Widget _buildDataCell(String text, {pw.TextAlign align = pw.TextAlign.left, pw.FontWeight? fontWeight, PdfColor? color}) {
    return pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(text, textAlign: align, style: pw.TextStyle(fontSize: 8, fontWeight: fontWeight, color: color)));
  }

  static Future<void> _previewPdf(pw.Document pdf, String fileName) async {
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save(), name: fileName);
  }
}
