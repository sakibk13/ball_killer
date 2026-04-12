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

class _RecordsScreenState extends State<RecordsScreen> {
  String _selectedMonthYear = 'Overall';
  late List<String> _monthList;

  @override
  void initState() {
    super.initState();
    _generateMonthList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BallProvider>(context, listen: false).fetchAllRecords();
    });
  }

  void _generateMonthList() {
    _monthList = ['Overall'];
    DateTime now = DateTime.now();
    for (int i = 0; i < 12; i++) {
      DateTime date = DateTime(now.year, now.month - i, 1);
      _monthList.add(DateFormat('MM-yyyy').format(date));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ballProvider = Provider.of<BallProvider>(context);

    final filteredRecords = _selectedMonthYear == 'Overall' 
        ? ballProvider.allRecords 
        : ballProvider.allRecords.where((r) => r.monthYear == _selectedMonthYear).toList();

    final totalLost = filteredRecords.fold(0, (sum, r) => sum + r.lostCount);

    // Group records by month, then by date
    Map<String, Map<String, List<BallRecord>>> grouped = {};
    final sortedRecords = List<BallRecord>.from(filteredRecords)..sort((a, b) => b.date.compareTo(a.date));

    for (var r in sortedRecords) {
      String monthKey = DateFormat('MMMM yyyy').format(r.date).toUpperCase();
      String dateKey = DateFormat('yyyy-MM-dd').format(r.date);
      grouped.putIfAbsent(monthKey, () => {});
      grouped[monthKey]!.putIfAbsent(dateKey, () => []);
      grouped[monthKey]![dateKey]!.add(r);
    }

    final monthKeys = grouped.keys.toList();

    return Scaffold(
      backgroundColor: const Color(0xFF051970),
      appBar: AppBar(
        title: Text('TRACK OVERVIEW', style: GoogleFonts.bebasNeue(fontSize: 24, letterSpacing: 1.5, color: Colors.white)),
        backgroundColor: const Color(0xFF020C3B),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => ballProvider.refresh(),
        color: Colors.orange,
        child: Column(
          children: [
            _buildMonthPicker(),
            _buildStatsHeader(totalLost),
            Expanded(
              child: monthKeys.isEmpty 
                ? Center(child: Text('No data for selected period', style: GoogleFonts.poppins(color: Colors.white24)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: monthKeys.length,
                    itemBuilder: (context, mIndex) {
                      final monthStr = monthKeys[mIndex];
                      final dailyData = grouped[monthStr]!;
                      final dateKeys = dailyData.keys.toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8, top: 16, bottom: 12),
                            child: Row(
                              children: [
                                Container(width: 4, height: 18, color: Colors.orange),
                                const SizedBox(width: 10),
                                Text(monthStr, style: GoogleFonts.bebasNeue(color: Colors.white, fontSize: 20, letterSpacing: 1.5)),
                              ],
                            ),
                          ),
                          ...dateKeys.map((dateStr) {
                            final dayRecords = dailyData[dateStr]!;
                            final date = DateTime.parse(dateStr);
                            final dailyTotal = dayRecords.fold(0, (sum, r) => sum + r.lostCount);

                            // AGGREGATE PLAYER RECORDS FOR THIS DAY
                            Map<String, int> playerAggregated = {};
                            for (var r in dayRecords) {
                              playerAggregated[r.playerName] = (playerAggregated[r.playerName] ?? 0) + r.lostCount;
                            }
                            final aggregatedList = playerAggregated.entries.toList()
                              ..sort((a, b) => b.value.compareTo(a.value));

                            return Container(
                              margin: const EdgeInsets.only(bottom: 24),
                              decoration: BoxDecoration(
                                color: const Color(0xFF020C3B),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.white.withOpacity(0.08)),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.04),
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                              child: const Icon(Icons.calendar_today, color: Colors.orange, size: 18),
                                            ),
                                            const SizedBox(width: 12),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(DateFormat('EEEE').format(date).toUpperCase(), style: GoogleFonts.bebasNeue(color: Colors.orange, fontSize: 14, letterSpacing: 1)),
                                                Text(DateFormat('dd MMMM').format(date), style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(colors: [Colors.redAccent.withOpacity(0.2), Colors.redAccent.withOpacity(0.05)]),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
                                          ),
                                          child: Column(
                                            children: [
                                              Text('TOTAL LOST', style: GoogleFonts.bebasNeue(color: Colors.redAccent, fontSize: 10, letterSpacing: 0.5)),
                                              Text('$dailyTotal', style: GoogleFonts.bebasNeue(color: Colors.white, fontSize: 20)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                                      ),
                                      child: Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.03),
                                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(child: Text('PLAYER NAME', style: GoogleFonts.bebasNeue(color: Colors.white38, fontSize: 13, letterSpacing: 1))),
                                                Text('BALLS LOST', style: GoogleFonts.bebasNeue(color: Colors.white38, fontSize: 13, letterSpacing: 1)),
                                              ],
                                            ),
                                          ),
                                          const Divider(color: Colors.white10, height: 1),
                                          ListView.separated(
                                            shrinkWrap: true,
                                            physics: const NeverScrollableScrollPhysics(),
                                            itemCount: aggregatedList.length,
                                            separatorBuilder: (context, i) => Divider(color: Colors.white.withOpacity(0.03), height: 1),
                                            itemBuilder: (context, i) {
                                              final entry = aggregatedList[i];
                                              return Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Row(
                                                        children: [
                                                          CircleAvatar(
                                                            radius: 12,
                                                            backgroundColor: Colors.orange.withOpacity(0.1),
                                                            child: Text(entry.key[0].toUpperCase(), style: GoogleFonts.bebasNeue(color: Colors.orange, fontSize: 12)),
                                                          ),
                                                          const SizedBox(width: 12),
                                                          Text(entry.key.toUpperCase(), style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w500)),
                                                        ],
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                      decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                                      child: Text('${entry.value}', style: GoogleFonts.bebasNeue(color: Colors.redAccent, fontSize: 18)),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      );
                    },
                  ),
            ),
          ],
        ),
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
          String display = m == 'Overall' ? 'OVERALL' : DateFormat('MMM yy').format(DateFormat('MM-yyyy').parse(m)).toUpperCase();
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

  Widget _buildStatsHeader(int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: const BoxDecoration(color: Color(0xFF020C3B), borderRadius: BorderRadius.vertical(bottom: Radius.circular(30))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TOTAL BALLS LOST', style: GoogleFonts.bebasNeue(color: Colors.white38, fontSize: 14, letterSpacing: 1.2)),
          Row(
            children: [
              Text('$total', style: GoogleFonts.bebasNeue(color: Colors.redAccent, fontSize: 40)),
              const SizedBox(width: 8),
              const Icon(Icons.auto_delete, color: Colors.redAccent, size: 28),
            ],
          ),
        ],
      ),
    );
  }
}
