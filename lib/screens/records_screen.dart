import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/ball_provider.dart';
import '../models/ball_record.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<String> _monthList;

  @override
  void initState() {
    super.initState();
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
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.orange,
          labelColor: Colors.orange,
          unselectedLabelColor: Colors.white38,
          labelStyle: GoogleFonts.bebasNeue(fontSize: 14, letterSpacing: 1),
          tabs: _monthList.map((m) {
            String display = m == 'Overall' ? 'OVERALL' : DateFormat('MMM yy').format(DateFormat('MM-yyyy').parse(m)).toUpperCase();
            return Tab(text: display);
          }).toList(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ballProvider.refresh(),
        color: Colors.orange,
        child: TabBarView(
          controller: _tabController,
          children: _monthList.map((m) => _buildMonthTable(m, ballProvider.allRecords)).toList(),
        ),
      ),
    );
  }

  Widget _buildMonthTable(String monthYear, List<BallRecord> allRecords) {
    final filteredRecords = monthYear == 'Overall' 
        ? allRecords 
        : allRecords.where((r) => r.monthYear == monthYear).toList();

    if (filteredRecords.isEmpty) {
      return Center(child: Text('No records found', style: GoogleFonts.poppins(color: Colors.white24)));
    }

    // Sort by date descending
    final sorted = List<BallRecord>.from(filteredRecords)..sort((a, b) => b.date.compareTo(a.date));
    
    // Aggregate by Date and Player Name
    Map<String, Map<String, int>> aggregated = {};
    for (var r in sorted) {
      String dateStr = DateFormat('dd/MM/yy').format(r.date);
      aggregated.putIfAbsent(dateStr, () => {});
      aggregated[dateStr]![r.playerName] = (aggregated[dateStr]![r.playerName] ?? 0) + r.lostCount;
    }

    List<Map<String, dynamic>> tableRows = [];
    int grandTotal = 0;
    
    // Convert map to list for DataTable
    aggregated.forEach((date, players) {
      players.forEach((name, count) {
        tableRows.add({'date': date, 'name': name, 'count': count});
        grandTotal += count;
      });
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(15),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF020C3B),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.white.withOpacity(0.05)),
                columnSpacing: 20,
                columns: [
                  DataColumn(label: Text('DATE', style: GoogleFonts.bebasNeue(color: Colors.orange, fontSize: 14))),
                  DataColumn(label: Text('PLAYER NAME', style: GoogleFonts.bebasNeue(color: Colors.white70, fontSize: 14))),
                  DataColumn(label: Text('TOTAL LOST', style: GoogleFonts.bebasNeue(color: Colors.white70, fontSize: 14))),
                ],
                rows: [
                  ...tableRows.map((row) => DataRow(cells: [
                    DataCell(Text(row['date'], style: const TextStyle(color: Colors.white60, fontSize: 12))),
                    DataCell(Text(row['name'].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text('${row['count']}', style: GoogleFonts.bebasNeue(color: Colors.redAccent, fontSize: 16)),
                      )
                    ),
                  ])),
                  // Grand Total Row
                  DataRow(
                    color: WidgetStateProperty.all(Colors.orange.withOpacity(0.1)),
                    cells: [
                      const DataCell(Text('')),
                      DataCell(Text('GRAND TOTAL', style: GoogleFonts.bebasNeue(color: Colors.orange, fontSize: 16, letterSpacing: 1))),
                      DataCell(Text('$grandTotal', style: GoogleFonts.bebasNeue(color: Colors.white, fontSize: 22))),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}
