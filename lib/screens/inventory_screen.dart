import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/inventory_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/ball_provider.dart';
import '../models/inventory.dart';
import '../utils/status_dialog.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _ballBoughtController = TextEditingController(text: '0');
  final _tapeBoughtController = TextEditingController(text: '0');
  final _ballLostController = TextEditingController(text: '0');
  final _totalStockController = TextEditingController(text: '0');
  bool _isStockUpdate = false;
  DateTime _selectedDate = DateTime.now();
  String _selectedMonthYear = DateFormat('MM-yyyy').format(DateTime.now());
  late List<String> _monthList;

  @override
  void initState() {
    super.initState();
    _generateMonthList();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InventoryProvider>(context, listen: false).fetchInventory();
      Provider.of<BallProvider>(context, listen: false).init();
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
  void dispose() {
    _tabController.dispose();
    _ballBoughtController.dispose();
    _tapeBoughtController.dispose();
    _ballLostController.dispose();
    _totalStockController.dispose();
    super.dispose();
  }

  void _showStatusDialog(String message, bool isSuccess) {
    StatusDialog.show(
      context, 
      message: message, 
      isSuccess: isSuccess, 
      title: isSuccess ? "RECORD SAVED" : "ERROR",
    );
  }

  void _showAddInventorySheet() {
    _selectedDate = DateTime.now(); 
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24, right: 24, top: 24,
          ),
          decoration: const BoxDecoration(color: Color(0xFF020C3B), borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 20),
                Text('LOG BALL & TAPE', style: GoogleFonts.bebasNeue(color: Colors.white, fontSize: 28, letterSpacing: 1.5)),
                const SizedBox(height: 25),
                GestureDetector(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2101));
                    if (picked != null) setModalState(() => _selectedDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Log Date', style: TextStyle(color: Colors.white38, fontSize: 10)),
                            Text(DateFormat('dd MMMM, yyyy').format(_selectedDate), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Icon(Icons.calendar_today, color: Colors.orange, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SwitchListTile(
                  title: const Text('Manual Stock Update', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Reset total count manually', style: TextStyle(color: Colors.white38, fontSize: 11)),
                  value: _isStockUpdate, activeColor: Colors.orange, contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setModalState(() => _isStockUpdate = v),
                ),
                const SizedBox(height: 10),
                if (_isStockUpdate) ...[
                  _buildInput(_totalStockController, 'Total Stock Count', Icons.inventory),
                ] else ...[
                  _buildInput(_ballBoughtController, 'Balls Bought', Icons.add_circle),
                  const SizedBox(height: 12),
                  _buildInput(_tapeBoughtController, 'Tapes Bought', Icons.layers),
                  const SizedBox(height: 12),
                  _buildInput(_ballLostController, 'Manual Balls Lost', Icons.remove_circle),
                ],
                const SizedBox(height: 35),
                SizedBox(
                  width: double.infinity, height: 60,
                  child: ElevatedButton(
                    onPressed: () async {
                      final auth = Provider.of<AuthProvider>(context, listen: false);
                      final inv = Inventory(
                        date: _selectedDate,
                        ballsBrought: _isStockUpdate ? 0 : (int.tryParse(_ballBoughtController.text) ?? 0),
                        tapesBrought: _isStockUpdate ? 0 : (int.tryParse(_tapeBoughtController.text) ?? 0),
                        ballsLost: _isStockUpdate ? 0 : (int.tryParse(_ballLostController.text) ?? 0),
                        totalStock: _isStockUpdate ? (int.tryParse(_totalStockController.text) ?? 0) : 0,
                        isStockUpdate: _isStockUpdate,
                        monthYear: DateFormat('MM-yyyy').format(_selectedDate),
                        recordedBy: auth.currentUser?.name ?? 'Admin',
                      );
                      final success = await Provider.of<InventoryProvider>(context, listen: false).addInventory(inv);
                      if (mounted) {
                        Navigator.pop(context);
                        _showStatusDialog(success ? "Inventory record saved!" : "Failed to save record.", success);
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 8),
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

  Widget _buildInput(TextEditingController ctrl, String label, IconData icon) {
    return TextField(
      controller: ctrl, keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label, labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.orange, size: 20),
        filled: true, fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final invProvider = Provider.of<InventoryProvider>(context);
    final ballProvider = Provider.of<BallProvider>(context);
    final isAdmin = Provider.of<AuthProvider>(context).isAdmin;

    return Scaffold(
      backgroundColor: const Color(0xFF051970),
      appBar: AppBar(
        title: Text('BALL & TAPE LOG', style: GoogleFonts.bebasNeue(color: Colors.white, letterSpacing: 1.5)),
        backgroundColor: const Color(0xFF020C3B), elevation: 0,
        bottom: TabBar(
          controller: _tabController, indicatorColor: Colors.orange, labelColor: Colors.orange, unselectedLabelColor: Colors.white38,
          tabs: const [Tab(text: 'MONTHLY SUMMARY'), Tab(text: 'LOG HISTORY')],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async { 
          await invProvider.fetchInventory(force: true); 
          await ballProvider.refresh();
        },
        color: Colors.orange,
        child: TabBarView(
          controller: _tabController,
          children: [ _buildSummary(invProvider, ballProvider), _buildHistory(invProvider, isAdmin) ],
        ),
      ),
      floatingActionButton: isAdmin ? FloatingActionButton(onPressed: _showAddInventorySheet, backgroundColor: Colors.orange, child: const Icon(Icons.add_chart, color: Colors.white)) : null,
    );
  }

  Widget _buildSummary(InventoryProvider inv, BallProvider ball) {
    final totals = inv.getMonthlyTotals()[_selectedMonthYear] ?? {'bought': 0, 'tape': 0, 'lost': 0};
    final remaining = inv.getCumulativeRemaining(_selectedMonthYear);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildMonthPicker(),
          const SizedBox(height: 25),
          Row(
            children: [
              Expanded(child: _buildStatCard('BOUGHT', '${totals['bought']}', Colors.blue, Icons.shopping_bag)),
              const SizedBox(width: 15),
              Expanded(child: _buildStatCard('TAPES', '${totals['tape']}', Colors.purpleAccent, Icons.layers)),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: _buildStatCard('LOG LOST', '${totals['lost']}', Colors.redAccent, Icons.auto_delete)),
              const SizedBox(width: 15),
              Expanded(child: _buildStatCard('STOCK', '$remaining', Colors.greenAccent, Icons.inventory)),
            ],
          ),
          const SizedBox(height: 35),
          Row(
            children: [ Container(width: 4, height: 20, color: Colors.orange), const SizedBox(width: 10), Text('MONTHLY LOG TABLE', style: GoogleFonts.bebasNeue(color: Colors.white, fontSize: 18, letterSpacing: 1)) ],
          ),
          const SizedBox(height: 15),
          _buildTable(inv.getItemsForMonth(_selectedMonthYear)),
          const SizedBox(height: 35),
          _buildNewsTicker(inv, ball),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildNewsTicker(InventoryProvider inv, BallProvider ball) {
    final playerLost = ball.getTotalLostForMonth(_selectedMonthYear);
    final managementLost = (inv.getMonthlyTotals()[_selectedMonthYear] ?? {'lost': 0})['lost'] ?? 0;
    
    // Math: Unintentionally = (Total Logged in Inventory) - (Specific Players' Lost)
    final unintentionallyLost = (managementLost - playerLost) < 0 ? 0 : (managementLost - playerLost);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.campaign_rounded, color: Colors.orange, size: 20),
              const SizedBox(width: 10),
              Text('MONTHLY LOSS ANALYSIS', style: GoogleFonts.bebasNeue(color: Colors.orange, fontSize: 18, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 15),
          _newsItem(
            "MANAGEMENT LOG", 
            "A total of $managementLost balls were recorded missing in the official inventory logs.",
            Icons.assignment_outlined
          ),
          const Divider(color: Colors.white10, height: 25),
          _newsItem(
            "PLAYER RECORDS", 
            "Players have specific accountability for $playerLost balls lost during match sessions.",
            Icons.person_search_outlined
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.analytics_outlined, color: Colors.redAccent, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      "UNINTENTIONALLY LOST",
                      style: GoogleFonts.bebasNeue(color: Colors.redAccent, fontSize: 14, letterSpacing: 1),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "There are $unintentionallyLost balls unintentionally lost (unaccounted field loss) this month.",
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _newsItem(String tag, String text, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white38, size: 16),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tag, style: GoogleFonts.bebasNeue(color: Colors.white38, fontSize: 12, letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(text, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String val, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(
        children: [ Icon(icon, color: color, size: 18), const SizedBox(height: 8), Text(label, style: GoogleFonts.poppins(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)), Text(val, style: GoogleFonts.bebasNeue(color: color, fontSize: 28)) ],
      ),
    );
  }

  Widget _buildMonthPicker() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal, itemCount: _monthList.length,
        itemBuilder: (context, index) {
          final m = _monthList[index]; final isSelected = _selectedMonthYear == m;
          String display = m == 'Overall' ? 'OVERALL' : DateFormat('MMM yy').format(DateFormat('MM-yyyy').parse(m)).toUpperCase();
          return GestureDetector(
            onTap: () => setState(() => _selectedMonthYear = m),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200), margin: const EdgeInsets.only(right: 10), padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(gradient: isSelected ? const LinearGradient(colors: [Colors.orange, Colors.deepOrange]) : null, color: isSelected ? null : Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: isSelected ? Colors.orange : Colors.white10)),
              alignment: Alignment.center, child: Text(display, style: GoogleFonts.bebasNeue(color: isSelected ? Colors.white : Colors.white38, fontSize: 15, letterSpacing: 1)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTable(List<Inventory> items) {
    if (items.isEmpty) return Center(child: Padding(padding: const EdgeInsets.all(30), child: Text('No records for this month', style: GoogleFonts.poppins(color: Colors.white24, fontSize: 12))));
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white10)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: DataTable(
          columnSpacing: 10, horizontalMargin: 15, headingRowHeight: 50, headingRowColor: WidgetStateProperty.all(Colors.white.withOpacity(0.05)),
          columns: const [
            DataColumn(label: Text('DATE', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('BOUGHT', style: TextStyle(color: Colors.white70, fontSize: 10))),
            DataColumn(label: Text('LOST', style: TextStyle(color: Colors.white70, fontSize: 10))),
            DataColumn(label: Text('REM', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold))),
          ],
          rows: items.map((item) {
            int rem = item.ballsBrought - item.ballsLost;
            return DataRow(cells: [
              DataCell(Text(DateFormat('dd MMM').format(item.date), style: const TextStyle(color: Colors.white, fontSize: 11))),
              DataCell(Text(item.isStockUpdate ? '-' : '${item.ballsBrought}', style: TextStyle(color: Colors.blueAccent, fontSize: 12))),
              DataCell(Text(item.isStockUpdate ? '-' : '${item.ballsLost}', style: TextStyle(color: Colors.redAccent, fontSize: 12))),
              DataCell(Text(item.isStockUpdate ? '${item.totalStock}' : '$rem', style: GoogleFonts.bebasNeue(color: Colors.greenAccent, fontSize: 16))),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildHistory(InventoryProvider inv, bool isAdmin) {
    final list = inv.inventoryList;
    if (list.isEmpty) return const Center(child: Text('No history found', style: TextStyle(color: Colors.white24)));
    return ListView.builder(
      padding: const EdgeInsets.all(16), itemCount: list.length,
      itemBuilder: (context, i) {
        final item = list[i]; final bool isStock = item.isStockUpdate;
        return Container(
          margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: isStock ? Colors.greenAccent.withOpacity(0.2) : Colors.white10)),
          child: Row(
            children: [
              Container(width: 55, padding: const EdgeInsets.symmetric(vertical: 8), decoration: BoxDecoration(color: (isStock ? Colors.greenAccent : Colors.orange).withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Column(children: [Text(DateFormat('dd').format(item.date), style: GoogleFonts.bebasNeue(color: isStock ? Colors.greenAccent : Colors.orange, fontSize: 22)), Text(DateFormat('MMM').format(item.date).toUpperCase(), style: TextStyle(color: isStock ? Colors.greenAccent : Colors.orange, fontSize: 10, fontWeight: FontWeight.bold))])),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(isStock ? 'STOCK UPDATE' : 'INVENTORY LOG', style: GoogleFonts.bebasNeue(color: Colors.white, fontSize: 16, letterSpacing: 1)), Text(isStock ? 'Set current stock to ${item.totalStock}' : 'Bought: ${item.ballsBrought} | Lost: ${item.ballsLost} | Rem: ${item.ballsBrought - item.ballsLost}', style: const TextStyle(color: Colors.white38, fontSize: 11))])),
              if (isAdmin) IconButton(icon: const Icon(Icons.delete_outline, color: Colors.white24, size: 20), onPressed: () => inv.deleteInventory(item.id!)),
            ],
          ),
        );
      },
    );
  }
}