import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/ball_provider.dart';
import '../providers/fine_provider.dart';
import '../providers/auth_provider.dart';
import '../models/fine_payment.dart';
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
      Provider.of<FineProvider>(context, listen: false).fetchPayments();
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
    final fineProvider = Provider.of<FineProvider>(context);
    
    final playersWithTotals = ballProvider.getPlayersWithTotals(monthYear: _selectedMonthYear);
    
    final enrichedPlayers = playersWithTotals.map((p) {
      final String playerId = p['id'];
      final int totalLost = p['total'] as int;
      final double totalFine = totalLost * 50.0;
      final double paid = fineProvider.getTotalPaidForPlayer(playerId, _selectedMonthYear);
      final double due = totalFine - paid;
      
      return {
        ...p,
        'totalFine': totalFine,
        'paid': paid,
        'due': due,
      };
    }).toList();

    final sortedPlayers = List<Map<String, dynamic>>.from(enrichedPlayers)
      ..sort((a, b) => (b['total'] as num).compareTo(a['total'] as num));

    final topPlayer = sortedPlayers.isNotEmpty ? sortedPlayers.first : null;
    final int totalLost = topPlayer != null ? (topPlayer['total'] as int) : 0;
    final double fineAmount = topPlayer != null ? topPlayer['totalFine'] : 0.0;
    final double topPaid = topPlayer != null ? topPlayer['paid'] : 0.0;
    final double topDue = topPlayer != null ? topPlayer['due'] : 0.0;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF051970),
        appBar: AppBar(
          title: Text('PLAYER FINES', style: GoogleFonts.bebasNeue(color: Colors.white, letterSpacing: 1.2)),
          backgroundColor: const Color(0xFF020C3B),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.orange),
              onPressed: () {
                ExportService.exportFineReport(
                  monthYear: _selectedMonthYear,
                  sortedPlayers: sortedPlayers,
                );
              },
            ),
            const SizedBox(width: 10),
          ],
          bottom: TabBar(
            indicatorColor: Colors.orange,
            labelColor: Colors.orange,
            unselectedLabelColor: Colors.white38,
            labelStyle: GoogleFonts.bebasNeue(letterSpacing: 1.2),
            tabs: const [
              Tab(text: 'NOTICES', icon: Icon(Icons.warning_amber_rounded)),
              Tab(text: 'GIVEN HISTORY', icon: Icon(Icons.history_edu_outlined)),
            ],
          ),
        ),
        body: Column(
          children: [
            _buildMonthPicker(),
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Notices
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        if (topPlayer != null && totalLost > 0) ...[
                          _buildFineCard(topPlayer, totalLost, fineAmount, topPaid, topDue),
                          const SizedBox(height: 30),
                          _buildSectionHeader('RANKING ${_selectedMonthYear == 'Overall' ? 'OVERALL' : 'THIS MONTH'}'),
                          const SizedBox(height: 15),
                          _buildRankingList(sortedPlayers),
                        ] else ...[
                          const SizedBox(height: 100),
                          const Icon(Icons.verified_user_outlined, color: Colors.greenAccent, size: 80),
                          const SizedBox(height: 20),
                          Text('NO FINES FOUND', style: GoogleFonts.bebasNeue(color: Colors.white70, fontSize: 24)),
                          Text('Everything is clear!', style: GoogleFonts.poppins(color: Colors.white38, fontSize: 14)),
                        ],
                      ],
                    ),
                  ),
                  // Tab 2: Given History (Date First Layout)
                  _buildGivenHistoryTab(fineProvider),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) {
            return FloatingActionButton(
              onPressed: () => _showAddFineGivenDialog(context, enrichedPlayers),
              backgroundColor: Colors.orange,
              child: const Icon(Icons.add, color: Colors.white),
            );
          }
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
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                gradient: isSelected ? const LinearGradient(colors: [Colors.orange, Colors.deepOrange]) : null,
                color: isSelected ? null : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? Colors.orange : Colors.white10),
              ),
              alignment: Alignment.center,
              child: Text(display, style: GoogleFonts.bebasNeue(color: isSelected ? Colors.white : Colors.white38, fontSize: 16, letterSpacing: 1)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFineCard(Map<String, dynamic> player, int lost, double fine, double given, double due) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOP BALL KILLER', style: GoogleFonts.bebasNeue(color: Colors.white70, fontSize: 16, letterSpacing: 1.5)),
                    Text('MONTHLY FINE NOTICE', style: GoogleFonts.bebasNeue(color: Colors.white, fontSize: 24, letterSpacing: 1.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white30, width: 2)),
            child: CircleAvatar(
              radius: 45,
              backgroundColor: Colors.white24,
              backgroundImage: player['photoUrl'] != null && player['photoUrl'].isNotEmpty 
                  ? MemoryImage(base64Decode(player['photoUrl'])) 
                  : null,
              child: player['photoUrl'] == null || player['photoUrl'].isEmpty 
                  ? Text(player['name'][0], style: const TextStyle(color: Colors.white, fontSize: 35)) 
                  : null,
            ),
          ),
          const SizedBox(height: 15),
          Text(player['name'].toUpperCase(), style: GoogleFonts.bebasNeue(color: Colors.white, fontSize: 28, letterSpacing: 2)),
          const SizedBox(height: 25),
          
          // Redesigned square layout for details
          Row(
            children: [
              Expanded(child: _buildSquareDetail('BALLS LOST', '$lost', Colors.white24)),
              const SizedBox(width: 10),
              Expanded(child: _buildSquareDetail('TOTAL FINE', '${fine.toInt()} ৳', Colors.yellowAccent.withOpacity(0.1), textCol: Colors.yellowAccent)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildSquareDetail('GIVEN', '${given.toInt()} ৳', Colors.greenAccent.withOpacity(0.1), textCol: Colors.greenAccent)),
              const SizedBox(width: 10),
              Expanded(child: _buildSquareDetail('DUE', '${due.toInt()} ৳', due > 0 ? Colors.orangeAccent.withOpacity(0.1) : Colors.greenAccent.withOpacity(0.1), textCol: due > 0 ? Colors.orangeAccent : Colors.greenAccent)),
            ],
          ),

          const SizedBox(height: 20),
          Text(
            '* As per club rules, the top ball killer must pay a fine of 50 Taka per ball lost.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.white60, fontSize: 10, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildSquareDetail(String label, String val, Color bg, {Color textCol = Colors.white}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.bebasNeue(color: Colors.white38, fontSize: 10, letterSpacing: 1)),
          Text(val, style: GoogleFonts.bebasNeue(color: textCol, fontSize: 20)),
        ],
      ),
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
        final fine = p['totalFine'] as double;
        final given = p['paid'] as double;
        final due = p['due'] as double;

        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: i == 0 ? Colors.redAccent.withOpacity(0.4) : Colors.white10),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text('${i + 1}', style: GoogleFonts.bebasNeue(color: i == 0 ? Colors.redAccent : Colors.white24, fontSize: 20)),
                  const SizedBox(width: 15),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white10,
                    backgroundImage: p['photoUrl'] != null && p['photoUrl'].isNotEmpty 
                        ? MemoryImage(base64Decode(p['photoUrl'])) 
                        : null,
                    child: p['photoUrl'] == null || p['photoUrl'].isEmpty ? Text(p['name'][0], style: const TextStyle(color: Colors.orange)) : null,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(p['name'].toUpperCase(), style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('$total BALLS', style: GoogleFonts.bebasNeue(color: i == 0 ? Colors.redAccent : Colors.white70, fontSize: 15)),
                      if (total > 0)
                        Text('FINE: ${fine.toInt()} ৳', style: GoogleFonts.bebasNeue(color: Colors.yellowAccent, fontSize: 13)),
                    ],
                  ),
                ],
              ),
              if (total > 0) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: Colors.white10, height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMiniStatus('GIVEN', '${given.toInt()} ৳', Colors.greenAccent),
                    _buildMiniStatus('DUE', '${due.toInt()} ৳', due > 0 ? Colors.orangeAccent : Colors.greenAccent),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniStatus(String label, String val, Color color) {
    return Row(
      children: [
        Text('$label: ', style: GoogleFonts.bebasNeue(color: Colors.white38, fontSize: 12)),
        Text(val, style: GoogleFonts.bebasNeue(color: color, fontSize: 14)),
      ],
    );
  }

  Widget _buildGivenHistoryTab(FineProvider fineProvider) {
    final payments = fineProvider.getPaymentsForMonth(_selectedMonthYear);

    if (payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history_edu_outlined, color: Colors.white10, size: 80),
            const SizedBox(height: 20),
            Text('NO GIVEN HISTORY', style: GoogleFonts.bebasNeue(color: Colors.white24, fontSize: 24)),
            Text('Records will appear here', style: GoogleFonts.poppins(color: Colors.white10, fontSize: 12)),
          ],
        ),
      );
    }

    // Group by Date
    Map<String, List<FinePayment>> grouped = {};
    for (var p in payments) {
      String dateStr = DateFormat('yyyy-MM-dd').format(p.date);
      grouped.putIfAbsent(dateStr, () => []);
      grouped[dateStr]!.add(p);
    }
    var dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: dates.length,
      itemBuilder: (context, index) {
        String dateKey = dates[index];
        DateTime date = DateTime.parse(dateKey);
        List<FinePayment> items = grouped[dateKey]!;

        return Container(
          margin: const EdgeInsets.only(bottom: 25),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Calendar Card
              Container(
                width: 65,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF020C3B), Color(0xFF051970)]),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.orange.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Text(DateFormat('MMM').format(date).toUpperCase(), style: GoogleFonts.bebasNeue(color: Colors.orange, fontSize: 14)),
                    Text(DateFormat('dd').format(date), style: GoogleFonts.bebasNeue(color: Colors.white, fontSize: 28, height: 1)),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  children: items.map((p) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.playerName.toUpperCase(), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              if (p.note != null && p.note!.isNotEmpty)
                                Text(p.note!, style: const TextStyle(color: Colors.white38, fontSize: 9)),
                            ],
                          ),
                        ),
                        Text('${p.amountPaid.toInt()} ৳', style: GoogleFonts.bebasNeue(color: Colors.greenAccent, fontSize: 18)),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => _confirmDeleteGivenFine(context, fineProvider, p),
                          child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteGivenFine(BuildContext context, FineProvider provider, FinePayment payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF020C3B),
        title: Text('DELETE RECORD', style: GoogleFonts.bebasNeue(color: Colors.white)),
        content: Text('Remove this record of ${payment.amountPaid.toInt()} ৳?', style: GoogleFonts.poppins(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              provider.deletePayment(payment.id!);
              Navigator.pop(context);
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showAddFineGivenDialog(BuildContext context, List<Map<String, dynamic>> players) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Only admins can add collection records')));
      return;
    }

    final formKey = GlobalKey<FormState>();
    String? selectedPlayerId;
    String? selectedPlayerName;
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF020C3B),
          title: Text('ADD FINE GIVEN', style: GoogleFonts.bebasNeue(color: Colors.white, letterSpacing: 1.2)),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    dropdownColor: const Color(0xFF020C3B),
                    decoration: _inputDecoration('SELECT PLAYER'),
                    style: const TextStyle(color: Colors.white),
                    items: players.where((p) => (p['total'] as int) > 0).map<DropdownMenuItem<String>>((p) {
                      return DropdownMenuItem<String>(
                        value: p['id'],
                        child: Text(p['name'].toString().toUpperCase()),
                        onTap: () => selectedPlayerName = p['name'],
                      );
                    }).toList(),
                    onChanged: (val) => selectedPlayerId = val,
                    validator: (val) => val == null ? 'Please select a player' : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: amountController,
                    decoration: _inputDecoration('GIVEN AMOUNT (৳)'),
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    validator: (val) => val == null || val.isEmpty ? 'Enter amount' : null,
                  ),
                  const SizedBox(height: 15),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setDialogState(() => selectedDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('DATE: ${DateFormat('MMM dd, yyyy').format(selectedDate)}', style: const TextStyle(color: Colors.white70)),
                          const Icon(Icons.calendar_today, color: Colors.orange, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: noteController,
                    decoration: _inputDecoration('OPTIONAL NOTE'),
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () async {
                if (formKey.currentState!.validate() && selectedPlayerId != null) {
                  final payment = FinePayment(
                    playerId: selectedPlayerId!,
                    playerName: selectedPlayerName!,
                    amountPaid: double.parse(amountController.text),
                    date: selectedDate,
                    note: noteController.text,
                    monthYear: DateFormat('MM-yyyy').format(selectedDate),
                  );
                  
                  final success = await Provider.of<FineProvider>(context, listen: false).addPayment(payment);
                  if (success) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Record added successfully')));
                  }
                }
              },
              child: const Text('SAVE RECORD', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.orange)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
    );
  }
}
