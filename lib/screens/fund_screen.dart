import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/ball_provider.dart';
import '../providers/fund_provider.dart';
import '../providers/auth_provider.dart';
import '../models/fund.dart';
import '../utils/export_service.dart';

class FundScreen extends StatefulWidget {
  const FundScreen({super.key});

  @override
  State<FundScreen> createState() => _FundScreenState();
}

class _FundScreenState extends State<FundScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FundProvider>(context, listen: false).fetchFunds();
    });
  }

  @override
  Widget build(BuildContext context) {
    final fundProvider = Provider.of<FundProvider>(context);
    final isAdmin = Provider.of<AuthProvider>(context, listen: false).isAdmin;

    return Scaffold(
      backgroundColor: const Color(0xFF051970),
      appBar: AppBar(
        title: Text('CLUB FUND', style: GoogleFonts.bebasNeue(color: Colors.white, letterSpacing: 1.2)),
        backgroundColor: const Color(0xFF020C3B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.orange),
            onPressed: () {
              ExportService.exportFundReport(
                funds: fundProvider.funds,
                grandTotal: fundProvider.grandTotal,
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          _buildGrandTotalCard(fundProvider.grandTotal),
          Expanded(
            child: fundProvider.isLoading 
                ? const Center(child: CircularProgressIndicator(color: Colors.orange))
                : _buildFundList(fundProvider, isAdmin),
          ),
        ],
      ),
      floatingActionButton: isAdmin ? FloatingActionButton(
        onPressed: () => _showAddFundDialog(context),
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,
    );
  }

  Widget _buildGrandTotalCard(double total) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00C853), Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 20, spreadRadius: 5)
        ],
      ),
      child: Column(
        children: [
          Text('GRAND TOTAL FUND', style: GoogleFonts.bebasNeue(color: Colors.white70, fontSize: 18, letterSpacing: 1.5)),
          const SizedBox(height: 10),
          Text('${total.toInt()} ৳', style: GoogleFonts.bebasNeue(color: Colors.white, fontSize: 48, letterSpacing: 2)),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: Text('AVAILABLE BALANCE', style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildFundList(FundProvider provider, bool isAdmin) {
    if (provider.funds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance_wallet_outlined, color: Colors.white10, size: 80),
            const SizedBox(height: 20),
            Text('NO FUND HISTORY', style: GoogleFonts.bebasNeue(color: Colors.white24, fontSize: 24)),
          ],
        ),
      );
    }

    // Group by Date
    Map<String, List<Fund>> grouped = {};
    for (var f in provider.funds) {
      String dateStr = DateFormat('yyyy-MM-dd').format(f.date);
      grouped.putIfAbsent(dateStr, () => []);
      grouped[dateStr]!.add(f);
    }
    var dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: dates.length,
      itemBuilder: (context, index) {
        String dateKey = dates[index];
        DateTime date = DateTime.parse(dateKey);
        List<Fund> items = grouped[dateKey]!;
        
        // Calculate daily net total
        double dailyTotal = items.fold(0, (sum, item) {
          return item.type == 'EXPENSE' ? sum - item.amount : sum + item.amount;
        });

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
                    const SizedBox(height: 5),
                    Text('${dailyTotal.toInt()}', style: GoogleFonts.bebasNeue(color: dailyTotal >= 0 ? Colors.greenAccent : Colors.redAccent, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  children: items.map((f) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: f.type == 'EXPENSE' ? Colors.redAccent.withOpacity(0.1) : Colors.white10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(f.name.toUpperCase(), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              if (f.note != null && f.note!.isNotEmpty)
                                Text(f.note!, style: const TextStyle(color: Colors.white38, fontSize: 9)),
                              Text(f.type, style: TextStyle(color: f.type == 'EXPENSE' ? Colors.redAccent : Colors.greenAccent, fontSize: 8, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Text(
                          '${f.type == 'EXPENSE' ? '-' : ''}${f.amount.toInt()} ৳', 
                          style: GoogleFonts.bebasNeue(color: f.type == 'EXPENSE' ? Colors.redAccent : Colors.greenAccent, fontSize: 18)
                        ),
                        if (isAdmin) ...[
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => _confirmDeleteFund(context, provider, f),
                            child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                          ),
                        ],
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

  void _confirmDeleteFund(BuildContext context, FundProvider provider, Fund fund) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF020C3B),
        title: Text('DELETE ENTRY', style: GoogleFonts.bebasNeue(color: Colors.white)),
        content: Text('Remove this entry of ${fund.amount.toInt()}?', style: GoogleFonts.poppins(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              provider.deleteFund(fund.id!);
              Navigator.pop(context);
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showAddFundDialog(BuildContext context) {
    final ballProvider = Provider.of<BallProvider>(context, listen: false);
    final players = ballProvider.players;
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String entryType = 'INCOME';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF020C3B),
          title: Text('ADD TO FUND', style: GoogleFonts.bebasNeue(color: Colors.white, letterSpacing: 1.2)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // INCOME / EXPENSE Toggle
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setDialogState(() => entryType = 'INCOME'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: entryType == 'INCOME' ? Colors.greenAccent.withOpacity(0.2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text('INCOME', style: GoogleFonts.bebasNeue(color: entryType == 'INCOME' ? Colors.greenAccent : Colors.white24)),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setDialogState(() => entryType = 'EXPENSE'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: entryType == 'EXPENSE' ? Colors.redAccent.withOpacity(0.2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text('EXPENSE', style: GoogleFonts.bebasNeue(color: entryType == 'EXPENSE' ? Colors.redAccent : Colors.white24)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text == '') return const Iterable<String>.empty();
                    return players.where((p) => p.name.toLowerCase().contains(textEditingValue.text.toLowerCase())).map((p) => p.name);
                  },
                  onSelected: (String selection) { nameController.text = selection; },
                  fieldViewBuilder: (ctx, ctrl, focus, onSub) => TextFormField(
                    controller: ctrl,
                    focusNode: focus,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDeco('NAME / SOURCE'),
                    onChanged: (v) => nameController.text = v,
                  ),
                  optionsViewBuilder: (ctx, onSelected, options) => Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      color: const Color(0xFF020C3B),
                      elevation: 4.0,
                      child: Container(
                        width: 250,
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (ctx, i) {
                            final name = options.elementAt(i);
                            final p = players.firstWhere((p) => p.name == name);
                            return ListTile(
                              leading: CircleAvatar(
                                radius: 15,
                                backgroundColor: Colors.white10,
                                backgroundImage: p.photoUrl != '' ? MemoryImage(base64Decode(p.photoUrl)) : null,
                                child: p.photoUrl == '' ? Text(p.name[0], style: const TextStyle(fontSize: 10)) : null,
                              ),
                              title: Text(p.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 13)),
                              onTap: () => onSelected(name),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDeco('AMOUNT (৳)'),
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
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
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
                TextField(
                  controller: noteController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDeco('OPTIONAL NOTE'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () async {
                if (nameController.text.isNotEmpty && amountController.text.isNotEmpty) {
                  final fund = Fund(
                    name: nameController.text,
                    amount: double.parse(amountController.text),
                    date: selectedDate,
                    note: noteController.text,
                    type: entryType,
                  );
                  final success = await Provider.of<FundProvider>(context, listen: false).addFund(fund);
                  if (success) {
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text('SAVE', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label) {
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
