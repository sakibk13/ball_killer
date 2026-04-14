import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/ball_provider.dart';
import '../models/ball_record.dart';
import '../utils/quotes.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<String> _monthList;
  late String _randomQuote;

  @override
  void initState() {
    super.initState();
    _randomQuote = "“খেলাধুলায় বাড়ে বল, মাদক ছেড়ে খেলতে চল।”";
    _generateMonthList();
    _tabController = TabController(length: _monthList.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BallProvider>(context, listen: false).fetchAllRecords();
    });
  }

  void _generateMonthList() {
    _monthList = ['Overall'];
    DateTime now = DateTime.now();
    for (int i = 0; i < 11; i++) {
      DateTime date = DateTime(now.year, now.month - i, 1);
      _monthList.add(DateFormat('MM-yyyy').format(date));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ballProvider = Provider.of<BallProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF051970),
      appBar: AppBar(
        title: Text('TRACK OVERVIEW', style: GoogleFonts.bebasNeue(fontSize: 24, letterSpacing: 1.5, color: Colors.white)),
        backgroundColor: const Color(0xFF020C3B),
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.orange,
          labelColor: Colors.orange,
          unselectedLabelColor: Colors.white38,
          labelStyle: GoogleFonts.bebasNeue(fontSize: 14, letterSpacing: 1),
          tabs: _monthList.map((m) {
            String display = m == 'Overall' ? 'OVERALL' : DateFormat('MMMM yyyy').format(DateFormat('MM-yyyy').parse(m)).toUpperCase();
            return Tab(text: display);
          }).toList(),
        ),
      ),
      body: Column(
        children: [
          _buildHeroHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ballProvider.refresh(),
              color: Colors.orange,
              child: TabBarView(
                controller: _tabController,
                children: _monthList.map((m) => _buildMonthTable(m, ballProvider.allRecords)).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF020C3B),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.orange.withOpacity(0.2)),
                ),
                child: Image.asset('assets/icon/logo3.png', height: 50, width: 50, errorBuilder: (c, e, s) => const Icon(Icons.sports_cricket, color: Colors.orange, size: 40)),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BALL KILLER CLUB',
                      style: GoogleFonts.bebasNeue(color: Colors.white, fontSize: 32, letterSpacing: 2),
                    ),
                    Text(
                      'PROFESSIONAL TRACK OVERVIEW',
                      style: GoogleFonts.bebasNeue(color: Colors.orange, fontSize: 14, letterSpacing: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                const Icon(Icons.format_quote_rounded, color: Colors.orange, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _randomQuote,
                    style: GoogleFonts.hindSiliguri(
                      color: Colors.white70, 
                      fontSize: 16, 
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthTable(String monthYear, List<BallRecord> allRecords) {
    final filteredRecords = monthYear == 'Overall' 
        ? allRecords 
        : allRecords.where((r) => r.monthYear == monthYear).toList();

    if (filteredRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history_rounded, size: 100, color: Colors.white10),
            const SizedBox(height: 16),
            Text('NO RECORDS FOUND', style: GoogleFonts.bebasNeue(color: Colors.white24, fontSize: 24, letterSpacing: 2)),
          ],
        ),
      );
    }

    // Sort by date descending
    final sorted = List<BallRecord>.from(filteredRecords)..sort((a, b) => b.date.compareTo(a.date));
    
    // Group by Date
    Map<String, List<BallRecord>> groupedByDate = {};
    for (var r in sorted) {
      String dateStr = DateFormat('yyyy-MM-dd').format(r.date);
      groupedByDate.putIfAbsent(dateStr, () => []);
      groupedByDate[dateStr]!.add(r);
    }

    // Sort dates descending
    var dates = groupedByDate.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      itemCount: dates.length,
      itemBuilder: (context, index) {
        String dateKey = dates[index];
        DateTime date = DateTime.parse(dateKey);
        List<BallRecord> records = groupedByDate[dateKey]!;
        
        // Aggregate records for this date by player
        Map<String, int> playerTotals = {};
        for (var r in records) {
          playerTotals[r.playerName] = (playerTotals[r.playerName] ?? 0) + r.lostCount;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 30),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left side: Calendar style date
                Container(
                  width: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF020C3B), Color(0xFF051970)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('MMM').format(date).toUpperCase(),
                        style: GoogleFonts.bebasNeue(color: Colors.orange, fontSize: 18, letterSpacing: 1),
                      ),
                      Text(
                        DateFormat('dd').format(date),
                        style: GoogleFonts.bebasNeue(color: Colors.white, fontSize: 36, height: 1),
                      ),
                      Text(
                        DateFormat('yyyy').format(date),
                        style: GoogleFonts.bebasNeue(color: Colors.white38, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // Right side: Table of players
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF020C3B).withOpacity(0.6),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            color: Colors.white.withOpacity(0.05),
                            child: Row(
                              children: [
                                Expanded(child: Text('PLAYER', style: GoogleFonts.bebasNeue(color: Colors.white60, fontSize: 12, letterSpacing: 1))),
                                SizedBox(width: 60, child: Center(child: Text('LOST', style: GoogleFonts.bebasNeue(color: Colors.orange, fontSize: 12, letterSpacing: 1)))),
                              ],
                            ),
                            ),
                            ...playerTotals.entries.map((entry) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      entry.key.toUpperCase(),
                                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 60,
                                    child: Center(
                                      child: Text(
                                        '${entry.value}',
                                        style: GoogleFonts.bebasNeue(color: Colors.redAccent, fontSize: 22),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            }),                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
