import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/contribution_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/ball_provider.dart';
import '../models/contribution.dart';
import '../utils/status_dialog.dart';

class ContributionScreen extends StatefulWidget {
  const ContributionScreen({super.key});

  @override
  State<ContributionScreen> createState() => _ContributionScreenState();
}

class _ContributionScreenState extends State<ContributionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _nameController = TextEditingController();
  final _takaController = TextEditingController();
  final _ballCountController = TextEditingController(text: '0');
  final _tapeCountController = TextEditingController(text: '0');
  final _infoController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ContributionProvider>(context, listen: false).fetchContributions();
      Provider.of<BallProvider>(context, listen: false).fetchPlayers();
    });
  }

  void _updateTotal() {
    int balls = int.tryParse(_ballCountController.text) ?? 0;
    int tapes = int.tryParse(_tapeCountController.text) ?? 0;
    int total = (balls * 40) + (tapes * 20);
    if (total > 0) _takaController.text = total.toString();
  }

  void _showAddSheet() {
    final players = Provider.of<BallProvider>(context, listen: false).players;
    _selectedDate = DateTime.now(); 

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          decoration: const BoxDecoration(color: Color(0xFF020C3B), borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 20),
                Text('ADD CONTRIBUTION', style: GoogleFonts.bebasNeue(color: Colors.white, fontSize: 28, letterSpacing: 1.5)),
                const SizedBox(height: 25),
                
                GestureDetector(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2101),
                    );
                    if (picked != null) setModalState(() => _selectedDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Contribution Date', style: TextStyle(color: Colors.white38, fontSize: 10)),
                            Text(DateFormat('dd MMMM, yyyy').format(_selectedDate), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Icon(Icons.calendar_today, color: Colors.orange, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Autocomplete<String>(
                  optionsBuilder: (v) => players.where((p) => p.name.toLowerCase().contains(v.text.toLowerCase())).map((p) => p.name),
                  onSelected: (v) => _nameController.text = v,
                  fieldViewBuilder: (ctx, focusCtrl, focus, onSub) => TextField(
                    controller: focusCtrl,
                    focusNode: focus,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDeco('Contributor Name', Icons.person_outline),
                    onChanged: (v) => _nameController.text = v,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildCounter('BALLS (40৳)', _ballCountController, () => setModalState(() => _updateTotal()))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildCounter('TAPES (20৳)', _tapeCountController, () => setModalState(() => _updateTotal()))),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _takaController, 
                  keyboardType: TextInputType.number, 
                  style: GoogleFonts.bebasNeue(color: Colors.greenAccent, fontSize: 24), 
                  decoration: _inputDeco('Total Amount (৳)', Icons.payments_outlined),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _infoController, 
                  style: const TextStyle(color: Colors.white70, fontSize: 14), 
                  decoration: _inputDeco('Optional Note', Icons.note_alt_outlined),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_nameController.text.isEmpty || _takaController.text.isEmpty) return;
                      
                      int balls = int.tryParse(_ballCountController.text) ?? 0;
                      int tapes = int.tryParse(_tapeCountController.text) ?? 0;
                      
                      List<String> items = [];
                      if (balls > 0) items.add('$balls ball${balls > 1 ? "s" : ""}');
                      if (tapes > 0) items.add('$tapes tape${tapes > 1 ? "s" : ""}');
                      
                      String autoNote = items.join(", ");
                      String manualNote = _infoController.text.trim();
                      String finalNote = autoNote;
                      if (manualNote.isNotEmpty) {
                        finalNote = autoNote.isEmpty ? manualNote : "$autoNote | $manualNote";
                      }

                      final c = Contribution(
                        name: _nameController.text,
                        taka: double.parse(_takaController.text),
                        date: _selectedDate,
                        monthYear: DateFormat('MM-yyyy').format(_selectedDate),
                        ballTape: finalNote,
                        ballCount: balls,
                        tapeCount: tapes,
                      );
                      final success = await Provider.of<ContributionProvider>(context, listen: false).addContribution(c);
                      if (mounted) {
                        Navigator.pop(context);
                        StatusDialog.show(
                          context, 
                          message: success ? "The contribution has been logged." : "Check your connection and try again.", 
                          isSuccess: success, 
                          title: success ? "RECORD SAVED" : "SAVE FAILED",
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 8,
                    ),
                    child: Text('SAVE RECORD', style: GoogleFonts.bebasNeue(fontSize: 20, letterSpacing: 1.2, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCounter(String label, TextEditingController ctrl, VoidCallback onUpdate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.white24, size: 20), onPressed: () {
                int v = int.parse(ctrl.text);
                if (v > 0) ctrl.text = (v - 1).toString();
                onUpdate();
              }),
              Text(ctrl.text, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.orange, size: 20), onPressed: () {
                ctrl.text = (int.parse(ctrl.text) + 1).toString();
                onUpdate();
              }),
            ],
          ),
        )
      ],
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
      prefixIcon: Icon(icon, color: Colors.orange, size: 20),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.orange, width: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ContributionProvider>(context);
    final isAdmin = Provider.of<AuthProvider>(context).isAdmin;

    return Scaffold(
      backgroundColor: const Color(0xFF051970),
      appBar: AppBar(
        title: Text('FINANCIAL RECORDS', style: GoogleFonts.bebasNeue(color: Colors.white, fontSize: 24, letterSpacing: 1.5)),
        backgroundColor: const Color(0xFF020C3B),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.orange,
          labelColor: Colors.orange,
          unselectedLabelColor: Colors.white38,
          tabs: const [Tab(text: 'MONTHLY SUMMARY'), Tab(text: 'DETAILED LOGS')],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.fetchContributions(force: true),
        color: Colors.orange,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildMonthlyDetailed(provider),
            _buildFullHistory(provider, isAdmin),
          ],
        ),
      ),
      floatingActionButton: isAdmin ? FloatingActionButton(
        onPressed: _showAddSheet, 
        backgroundColor: Colors.orange, 
        child: const Icon(Icons.add_card, color: Colors.white)
      ) : null,
    );
  }

  Widget _buildMonthlyDetailed(ContributionProvider p) {
    final data = p.getGroupedContributions();
    if (data.isEmpty) return const Center(child: Text('No records found', style: TextStyle(color: Colors.white24)));
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: data.length,
      itemBuilder: (ctx, i) {
        String monthKey = data.keys.elementAt(i);
        Map<String, double> players = data[monthKey]!;
        double total = players.values.fold(0, (s, v) => s + v);
        
        DateTime date = DateFormat('MM-yyyy').parse(monthKey);
        String monthName = DateFormat('MMMM yyyy').format(date);

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: const Color(0xFF020C3B),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white10),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(monthName.toUpperCase(), style: GoogleFonts.bebasNeue(color: Colors.orange, fontSize: 22, letterSpacing: 1)),
                        Text('COLLECTION SUMMARY', style: GoogleFonts.poppins(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Text('${total.toStringAsFixed(0)} ৳', style: GoogleFonts.bebasNeue(color: Colors.greenAccent, fontSize: 24)),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: players.entries.map((e) {
                    final personLogs = p.contributions.where((c) => c.name == e.key && c.monthYear == monthKey).toList();
                    final datesStr = personLogs.map((c) => DateFormat('dd').format(c.date)).toSet().join(", ");

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(width: 4, height: 25, decoration: BoxDecoration(color: Colors.orange.withOpacity(0.5), borderRadius: BorderRadius.circular(2))),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(e.key, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                      Text('Dates: $datesStr', style: const TextStyle(color: Colors.white24, fontSize: 10)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text('${e.value.toStringAsFixed(0)} ৳', style: GoogleFonts.bebasNeue(color: Colors.white70, fontSize: 20)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFullHistory(ContributionProvider p, bool isAdmin) {
    final list = p.contributions;
    if (list.isEmpty) return const Center(child: Text('No transaction history', style: TextStyle(color: Colors.white24)));
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final item = list[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05), 
            borderRadius: BorderRadius.circular(20), 
            border: Border.all(color: Colors.white10)
          ),
          child: Row(
            children: [
              Container(
                width: 55,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    Text(DateFormat('dd').format(item.date), style: GoogleFonts.bebasNeue(color: Colors.orange, fontSize: 22)),
                    Text(DateFormat('MMM').format(item.date).toUpperCase(), style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    if (item.ballTape.isNotEmpty) 
                      Text(item.ballTape, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${item.taka.toStringAsFixed(0)} ৳', style: GoogleFonts.bebasNeue(color: Colors.greenAccent, fontSize: 22)),
                  if (isAdmin) 
                    GestureDetector(
                      onTap: () => p.deleteContribution(item.id!),
                      child: const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Icon(Icons.delete_outline, color: Colors.white24, size: 18),
                      ),
                    ),
                ],
              )
            ],
          ),
        );
      },
    );
  }
}