import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/ball_provider.dart';
import '../utils/export_service.dart';

class FineScreen extends StatefulWidget {
  const FineScreen({super.key});

  @override
  State<FineScreen> createState() => _FineScreenState();
}

class _FineScreenState extends State<FineScreen> {
  String _selectedMonthYear = DateFormat('MM-yyyy').format(DateTime.now());
  late List<String> _monthList;

  @override
  void initState() {
    super.initState();
    _generateMonthList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BallProvider>(context, listen: false).init();
    });
  }

  void _generateMonthList() {
    _monthList = [];
    DateTime now = DateTime.now();
    for (int i = 0; i < 12; i++) {
      DateTime date = DateTime(now.year, now.month - i, 1);
      _monthList.add(DateFormat('MM-yyyy').format(date));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ballProvider = Provider.of<BallProvider>(context);
    final playersWithTotals = ballProvider.getPlayersWithTotals(monthYear: _selectedMonthYear);
    
    // Sort to find the top loser
    final sortedPlayers = List<Map<String, dynamic>>.from(playersWithTotals)
      ..sort((a, b) => (b['total'] as num).compareTo(a['total'] as num));

    final topPlayer = sortedPlayers.isNotEmpty ? sortedPlayers.first : null;
    final int finePerBall = 50;
    final int totalLost = topPlayer != null ? (topPlayer['total'] as int) : 0;
    final int fineAmount = totalLost * finePerBall;

    return Scaffold(
      backgroundColor: const Color(0xFF051970),
      appBar: AppBar(
        title: Text('PLAYER FINES', style: GoogleFonts.bebasNeue(color: Colors.white, letterSpacing: 1.2)),
        backgroundColor: const Color(0xFF020C3B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.orange),
            onPressed: () {
              final ballProvider = Provider.of<BallProvider>(context, listen: false);
              final playersWithTotals = ballProvider.getPlayersWithTotals(monthYear: _selectedMonthYear);
              final sortedPlayers = List<Map<String, dynamic>>.from(playersWithTotals)
                ..sort((a, b) => (b['total'] as num).compareTo(a['total'] as num));
              
              ExportService.exportFineReport(
                monthYear: _selectedMonthYear,
                sortedPlayers: sortedPlayers,
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          _buildMonthPicker(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (topPlayer != null && totalLost > 0) ...[
                    _buildFineCard(topPlayer, totalLost, fineAmount),
                    const SizedBox(height: 30),
                    _buildSectionHeader('RANKING THIS MONTH'),
                    const SizedBox(height: 15),
                    _buildRankingList(sortedPlayers),
                  ] else ...[
                    const SizedBox(height: 100),
                    const Icon(Icons.verified_user_outlined, color: Colors.greenAccent, size: 80),
                    const SizedBox(height: 20),
                    Text('NO FINES FOR THIS MONTH', style: GoogleFonts.bebasNeue(color: Colors.white70, fontSize: 24)),
                    Text('Everyone played safely!', style: GoogleFonts.poppins(color: Colors.white38, fontSize: 14)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthPicker() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: const Color(0xFF020C3B),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: _monthList.length,
        itemBuilder: (context, index) {
          final m = _monthList[index];
          final isSelected = _selectedMonthYear == m;
          String display = DateFormat('MMMM yyyy').format(DateFormat('MM-yyyy').parse(m)).toUpperCase();
          return GestureDetector(
            onTap: () => setState(() => _selectedMonthYear = m),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                gradient: isSelected ? const LinearGradient(colors: [Colors.orange, Colors.deepOrange]) : null,
                color: isSelected ? null : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? Colors.orange : Colors.white10),
                boxShadow: isSelected ? [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] : null,
              ),
              alignment: Alignment.center,
              child: Text(display, style: GoogleFonts.bebasNeue(color: isSelected ? Colors.white : Colors.white38, fontSize: 16, letterSpacing: 1)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFineCard(Map<String, dynamic> player, int lost, int fine) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB71C1C), Color(0xFFD32F2F), Color(0xFFC62828)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 25, spreadRadius: 5)
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 35),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOP BALL KILLER', style: GoogleFonts.bebasNeue(color: Colors.white70, fontSize: 18, letterSpacing: 1.5)),
                    Text('MONTHLY FINE NOTICE', style: GoogleFonts.bebasNeue(color: Colors.white, fontSize: 28, letterSpacing: 1.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 35),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white30, width: 2),
            ),
            child: CircleAvatar(
              radius: 55,
              backgroundColor: Colors.white24,
              backgroundImage: player['photoUrl'] != null && player['photoUrl'].isNotEmpty 
                  ? MemoryImage(base64Decode(player['photoUrl'])) 
                  : null,
              child: player['photoUrl'] == null || player['photoUrl'].isEmpty 
                  ? Text(player['name'][0], style: const TextStyle(color: Colors.white, fontSize: 45)) 
                  : null,
            ),
          ),
          const SizedBox(height: 20),
          Text(player['name'].toUpperCase(), style: GoogleFonts.bebasNeue(color: Colors.white, fontSize: 32, letterSpacing: 2)),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.25), borderRadius: BorderRadius.circular(25)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildFineDetail('BALLS LOST', '$lost'),
                _buildFineDetail('FINE RATE', '50 BDT'),
                _buildFineDetail('TOTAL FINE', '$fine BDT', color: Colors.yellowAccent),
              ],
            ),
          ),
          const SizedBox(height: 25),
          Text(
            '* As per club rules, the top ball killer of the month must pay a fine of 50 Taka per ball lost.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.white60, fontSize: 11, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildFineDetail(String label, String val, {Color color = Colors.white}) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.bebasNeue(color: Colors.white38, fontSize: 13, letterSpacing: 1)),
        const SizedBox(height: 5),
        Text(val, style: GoogleFonts.bebasNeue(color: color, fontSize: 26)),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 5, height: 22, decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 15),
        Text(title, style: GoogleFonts.bebasNeue(color: Colors.white, fontSize: 22, letterSpacing: 1.5)),
      ],
    );
  }

  Widget _buildRankingList(List<Map<String, dynamic>> players) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: players.length,
      itemBuilder: (context, i) {
        final p = players[i];
        final total = p['total'] as int;
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: i == 0 ? Colors.redAccent.withOpacity(0.4) : Colors.white10),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                alignment: Alignment.center,
                child: Text('${i + 1}', style: GoogleFonts.bebasNeue(color: i == 0 ? Colors.redAccent : Colors.white24, fontSize: 22)),
              ),
              const SizedBox(width: 15),
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white10,
                backgroundImage: p['photoUrl'] != null && p['photoUrl'].isNotEmpty 
                    ? MemoryImage(base64Decode(p['photoUrl'])) 
                    : null,
                child: p['photoUrl'] == null || p['photoUrl'].isEmpty ? Text(p['name'][0], style: const TextStyle(color: Colors.orange, fontSize: 14)) : null,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(p['name'].toUpperCase(), style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$total BALLS', style: GoogleFonts.bebasNeue(color: i == 0 ? Colors.redAccent : Colors.white70, fontSize: 16)),
                  if (total > 0)
                    Text('FINE: ${total * 50} BDT', style: GoogleFonts.bebasNeue(color: Colors.yellowAccent, fontSize: 14)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
