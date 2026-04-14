import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/ball_provider.dart';
import '../models/player.dart';

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
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                gradient: isSelected ? const LinearGradient(colors: [Colors.orange, Colors.deepOrange]) : null,
                color: isSelected ? null : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: isSelected ? Colors.orange : Colors.white10),
              ),
              alignment: Alignment.center,
              child: Text(display, style: GoogleFonts.bebasNeue(color: isSelected ? Colors.white : Colors.white38, fontSize: 14)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFineCard(Map<String, dynamic> player, int lost, int fine) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB71C1C), Color(0xFFD32F2F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 20, spreadRadius: 5)
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOP BALL KILLER', style: GoogleFonts.bebasNeue(color: Colors.white70, fontSize: 16, letterSpacing: 1)),
                    Text('MONTHLY FINE NOTICE', style: GoogleFonts.bebasNeue(color: Colors.white, fontSize: 24, letterSpacing: 1.2)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white24,
            backgroundImage: player['photoUrl'] != null && player['photoUrl'].isNotEmpty 
                ? MemoryImage(base64Decode(player['photoUrl'])) 
                : null,
            child: player['photoUrl'] == null || player['photoUrl'].isEmpty 
                ? Text(player['name'][0], style: const TextStyle(color: Colors.white, fontSize: 40)) 
                : null,
          ),
          const SizedBox(height: 15),
          Text(player['name'].toUpperCase(), style: GoogleFonts.bebasNeue(color: Colors.white, fontSize: 28, letterSpacing: 1.5)),
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildFineDetail('BALLS LOST', '$lost'),
                Container(width: 1, height: 40, color: Colors.white10),
                _buildFineDetail('FINE RATE', '50 ৳'),
                Container(width: 1, height: 40, color: Colors.white10),
                _buildFineDetail('TOTAL FINE', '$fine ৳', color: Colors.yellowAccent),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '* As per club rules, the top ball killer of the month must pay a fine of 50 Taka per ball lost.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.white60, fontSize: 10, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildFineDetail(String label, String val, {Color color = Colors.white}) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.bebasNeue(color: Colors.white38, fontSize: 12)),
        Text(val, style: GoogleFonts.bebasNeue(color: color, fontSize: 24)),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 4, height: 18, color: Colors.orange),
        const SizedBox(width: 10),
        Text(title, style: GoogleFonts.bebasNeue(color: Colors.white, fontSize: 18, letterSpacing: 1)),
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
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: i == 0 ? Colors.redAccent.withOpacity(0.3) : Colors.white10),
          ),
          child: Row(
            children: [
              Text('${i + 1}', style: GoogleFonts.bebasNeue(color: i == 0 ? Colors.redAccent : Colors.white24, fontSize: 18)),
              const SizedBox(width: 15),
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white10,
                backgroundImage: p['photoUrl'] != null && p['photoUrl'].isNotEmpty 
                    ? MemoryImage(base64Decode(p['photoUrl'])) 
                    : null,
                child: p['photoUrl'] == null || p['photoUrl'].isEmpty ? Text(p['name'][0], style: const TextStyle(color: Colors.orange, fontSize: 12)) : null,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(p['name'].toUpperCase(), style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$total BALLS', style: GoogleFonts.bebasNeue(color: i == 0 ? Colors.redAccent : Colors.white70, fontSize: 14)),
                  if (i == 0 && total > 0)
                    Text('FINE: ${total * 50} ৳', style: GoogleFonts.bebasNeue(color: Colors.yellowAccent, fontSize: 12)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
