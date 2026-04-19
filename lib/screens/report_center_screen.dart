import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;

import '../providers/ball_provider.dart';
import '../providers/fine_provider.dart';
import '../providers/contribution_provider.dart';
import '../providers/fund_provider.dart';
import '../utils/export_service.dart';
import '../utils/status_dialog.dart';

class ReportCenterScreen extends StatefulWidget {
  const ReportCenterScreen({super.key});

  @override
  State<ReportCenterScreen> createState() => _ReportCenterScreenState();
}

class _ReportCenterScreenState extends State<ReportCenterScreen> {
  final Set<String> _selectedReports = {};
  late List<String> _monthList;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _generateMonthList();
  }

  void _generateMonthList() {
    _monthList = ['Overall'];
    DateTime now = DateTime.now();
    for (int i = 0; i < 6; i++) {
      DateTime date = DateTime(now.year, now.month - i, 1);
      _monthList.add(DateFormat('MM-yyyy').format(date));
    }
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedReports.contains(id)) {
        _selectedReports.remove(id);
      } else {
        _selectedReports.add(id);
      }
    });
  }

  Future<void> _processReports() async {
    if (_selectedReports.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      final ballProv = Provider.of<BallProvider>(context, listen: false);
      final fineProv = Provider.of<FineProvider>(context, listen: false);
      final contProv = Provider.of<ContributionProvider>(context, listen: false);
      final fundProv = Provider.of<FundProvider>(context, listen: false);

      // Create a SINGLE master PDF document
      final masterPdf = pw.Document();

      for (String id in _selectedReports) {
        final parts = id.split('|');
        final type = parts[0];
        final month = parts[1];

        if (type == 'LEADERBOARD') {
          final players = ballProv.getPlayersWithTotals(monthYear: month);
          await ExportService.addLeaderboard(masterPdf, monthYear: month, players: players);
        } 
        else if (type == 'FINE') {
          final playersWithTotals = ballProv.getPlayersWithTotals(monthYear: month);
          final enriched = playersWithTotals.map((p) {
            final double finePaid = fineProv.getTotalPaidForPlayer(p['id'], month);
            final double contribPaid = contProv.contributions
                .where((c) => c.playerId == p['id'] && (month == 'Overall' || c.monthYear == month) && c.isFinePayment)
                .fold(0.0, (sum, c) => sum + c.taka);
            final double totalFineGiven = finePaid + contribPaid;
            return {...p, 'totalFine': (p['total'] as int) * 50.0, 'paid': totalFineGiven, 'due': ((p['total'] as int) * 50.0 - totalFineGiven).clamp(0, double.infinity)};
          }).toList();
          await ExportService.addFineReport(masterPdf, monthYear: month, sortedPlayers: enriched);
        }
        else if (type == 'FIN_SUM') {
          final data = contProv.getGroupedContributions();
          final filtered = month == 'Overall' ? data : (data.containsKey(month) ? {month: data[month]!} : <String, Map<String, double>>{});
          await ExportService.addFinancialSummaryReport(masterPdf, monthYear: month, data: filtered);
        }
        else if (type == 'FIN_DET') {
          final list = month == 'Overall' ? contProv.contributions : contProv.contributions.where((c) => c.monthYear == month).toList();
          final payments = month == 'Overall' ? fineProv.payments : fineProv.payments.where((p) => p.monthYear == month).toList();
          final combined = [...list, ...payments]..sort((a, b) => (b as dynamic).date.compareTo((a as dynamic).date));
          await ExportService.addFinancialDetailedReport(masterPdf, monthYear: month, contributions: combined);
        }
        else if (type == 'FUND') {
          await ExportService.addFundReport(masterPdf, funds: fundProv.funds, grandTotal: fundProv.grandTotal);
        }
      }

      // Final bytes of the single merged PDF
      final Uint8List mergedBytes = await masterPdf.save();
      
      // Open standard system dialog (Save / Share)
      await ExportService.downloadMultiplePdfs([mergedBytes], ['Club_Merged_Report.pdf']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Select 'Save to device' to download the merged PDF"))
        );
      }
    } catch (e) {
      if (mounted) {
        StatusDialog.show(context, title: "ERROR", message: "Failed to merge reports: $e", isSuccess: false);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF051970),
      appBar: AppBar(
        title: Text('REPORT CENTER', style: GoogleFonts.bebasNeue(color: Colors.white, letterSpacing: 1.2)),
        backgroundColor: const Color(0xFF020C3B),
        elevation: 0,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            children: [
              _buildSection('🏆 LEADERBOARD REPORTS', 'LEADERBOARD'),
              _buildSection('💰 FINE NOTICE REPORTS', 'FINE'),
              _buildSection('📊 FINANCIAL SUMMARIES', 'FIN_SUM'),
              _buildSection('📝 DETAILED FINANCIALS', 'FIN_DET'),
              _buildFundSection(),
            ],
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator(color: Colors.orange)),
            ),
        ],
      ),
      bottomSheet: _selectedReports.isEmpty ? null : _buildBottomActions(),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF020C3B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _processReports,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: Text('MERGE & EXPORT (${_selectedReports.length})', style: GoogleFonts.bebasNeue()),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(vertical: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String typePrefix) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(title, style: GoogleFonts.bebasNeue(color: Colors.orange, fontSize: 18, letterSpacing: 1)),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 3,
          ),
          itemCount: _monthList.length,
          itemBuilder: (ctx, i) {
            final month = _monthList[i];
            final id = '$typePrefix|$month';
            final isSelected = _selectedReports.contains(id);
            final label = month == 'Overall' ? 'OVERALL' : DateFormat('MMM yy').format(DateFormat('MM-yyyy').parse(month)).toUpperCase();

            return InkWell(
              onTap: () => _toggleSelection(id),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Colors.orange.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? Colors.orange : Colors.white10),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: isSelected, onChanged: (_) => _toggleSelection(id), 
                      activeColor: Colors.orange, side: const BorderSide(color: Colors.white24),
                    ),
                    Expanded(child: Text(label, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildFundSection() {
    final id = 'FUND|Overall';
    final isSelected = _selectedReports.contains(id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text('🏦 CLUB FUND RESERVE', style: GoogleFonts.bebasNeue(color: Colors.orange, fontSize: 18, letterSpacing: 1)),
        ),
        InkWell(
          onTap: () => _toggleSelection(id),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: isSelected ? Colors.orange.withOpacity(0.2) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? Colors.orange : Colors.white10),
            ),
            child: Row(
              children: [
                Checkbox(value: isSelected, onChanged: (_) => _toggleSelection(id), activeColor: Colors.orange),
                Text('OFFICIAL FUND REPORT (FULL HISTORY)', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
