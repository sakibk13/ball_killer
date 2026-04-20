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
  late List<String> _monthList;
  bool _isProcessing = false;
  String? _selectedMonth;

  @override
  void initState() {
    super.initState();
    _generateMonthList();
    _selectedMonth = _monthList.first; // Default to Overall or Current
  }

  void _generateMonthList() {
    _monthList = ['Overall'];
    DateTime now = DateTime.now();
    for (int i = 0; i < 12; i++) {
      DateTime date = DateTime(now.year, now.month - i, 1);
      _monthList.add(DateFormat('MM-yyyy').format(date));
    }
  }

  Future<void> _generateMonthlyBundle() async {
    if (_selectedMonth == null) return;

    setState(() => _isProcessing = true);

    try {
      final ballProv = Provider.of<BallProvider>(context, listen: false);
      final fineProv = Provider.of<FineProvider>(context, listen: false);
      final contProv = Provider.of<ContributionProvider>(context, listen: false);
      final fundProv = Provider.of<FundProvider>(context, listen: false);

      final String month = _selectedMonth!;
      final masterPdf = pw.Document();

      // PAGE 1: LEADERBOARD
      final players = ballProv.getPlayersWithTotals(monthYear: month);
      await ExportService.addLeaderboard(masterPdf, monthYear: month, players: players);

      // PAGE 2: FINE REPORT
      final playersWithTotals = ballProv.getPlayersWithTotals(monthYear: month);
      final enriched = playersWithTotals.map((p) {
        final double finePaid = fineProv.getTotalPaidForPlayer(p['id'], month);
        final double contribPaid = contProv.contributions
            .where((c) => c.playerId == p['id'] && (month == 'Overall' || c.monthYear == month) && c.isFinePayment)
            .fold(0.0, (sum, c) => sum + c.taka);
        
        final double allContribs = contProv.contributions
            .where((c) => c.playerId == p['id'] && (month == 'Overall' || c.monthYear == month))
            .fold(0.0, (sum, c) => sum + c.taka);

        final double totalFineOwed = (p['total'] as int) * 50.0;
        final double totalFineGiven = finePaid + contribPaid;
        final double totalMoneyGiven = finePaid + allContribs;

        double due = 0;
        double credit = 0;
        if (totalMoneyGiven >= totalFineOwed) {
          due = 0; credit = totalMoneyGiven - totalFineOwed;
        } else {
          due = totalFineOwed - totalMoneyGiven; credit = 0;
        }

        return {
          ...p,
          'totalFine': totalFineOwed,
          'paid': totalMoneyGiven,
          'due': due,
          'surplus': credit,
        };
      }).toList();
      await ExportService.addFineReport(masterPdf, monthYear: month, sortedPlayers: enriched);

      // PAGE 3: CLUB FUND (FULL HISTORY)
      await ExportService.addFundReport(masterPdf, funds: fundProv.funds, grandTotal: fundProv.grandTotal);

      // PAGE 4: PAYMENT NOTICE
      await ExportService.addPaymentInstructionPage(masterPdf);

      final Uint8List mergedBytes = await masterPdf.save();
      final String filename = 'Club_Report_${month.replaceAll('-', '_')}.pdf';
      
      await ExportService.downloadMultiplePdfs([mergedBytes], [filename]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Professional Monthly Bundle Generated!"))
        );
      }
    } catch (e) {
      if (mounted) {
        StatusDialog.show(context, title: "ERROR", message: "Failed to generate bundle: $e", isSuccess: false);
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
          Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(),
                const SizedBox(height: 40),
                Text('SELECT MONTH TO GENERATE BUNDLE', style: GoogleFonts.bebasNeue(color: Colors.orange, fontSize: 18, letterSpacing: 1)),
                const SizedBox(height: 15),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 2.8,
                    ),
                    itemCount: _monthList.length,
                    itemBuilder: (ctx, i) {
                      final month = _monthList[i];
                      final isSelected = _selectedMonth == month;
                      final label = month == 'Overall' ? 'OVERALL' : DateFormat('MMMM yyyy').format(DateFormat('MM-yyyy').parse(month)).toUpperCase();

                      return InkWell(
                        onTap: () => setState(() => _selectedMonth = month),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.orange.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: isSelected ? Colors.orange : Colors.white10),
                            boxShadow: isSelected ? [BoxShadow(color: Colors.orange.withOpacity(0.1), blurRadius: 10)] : null,
                          ),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(label, textAlign: TextAlign.center, style: GoogleFonts.bebasNeue(color: isSelected ? Colors.orange : Colors.white60, fontSize: 13, letterSpacing: 0.5)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator(color: Colors.orange)),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomAction(),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF020C3B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_motion_rounded, color: Colors.orange, size: 30),
              const SizedBox(width: 15),
              Expanded(
                child: Text('4-PAGE MONTHLY BUNDLE', style: GoogleFonts.bebasNeue(color: Colors.white, fontSize: 20)),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildInfoRow(Icons.check_circle_outline, 'Page 1: Official Leaderboard'),
          _buildInfoRow(Icons.check_circle_outline, 'Page 2: Fine & Credit Report'),
          _buildInfoRow(Icons.check_circle_outline, 'Page 3: Total Club Fund Reserve'),
          _buildInfoRow(Icons.check_circle_outline, 'Page 4: Payment Instruction Notice'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.greenAccent, size: 14),
          const SizedBox(width: 10),
          Text(text, style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      color: const Color(0xFF020C3B),
      child: ElevatedButton.icon(
        onPressed: _generateMonthlyBundle,
        icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.white),
        label: Text('GENERATE & SHARE BUNDLE', style: GoogleFonts.bebasNeue(fontSize: 18, color: Colors.white)),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
      ),
    );
  }
}
