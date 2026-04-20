import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/ball_provider.dart';
import '../providers/fine_provider.dart';
import '../providers/contribution_provider.dart';
import '../providers/fund_provider.dart';
import '../services/google_sync_service.dart';
import '../utils/status_dialog.dart';

class ManagePlayersScreen extends StatefulWidget {
  const ManagePlayersScreen({super.key});

  @override
  State<ManagePlayersScreen> createState() => _ManagePlayersScreenState();
}

class _ManagePlayersScreenState extends State<ManagePlayersScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadUrl();
  }

  Future<void> _loadUrl() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _urlController.text = prefs.getString('google_script_url') ?? 'https://script.google.com/macros/s/AKfycbwp0DU5dLj2tQiY8FzOty31qfTBnAq7NrnlVXJXJV1k42bLqtA5BJyHHpN--EtnZ-8e/exec';
    });
  }

  Future<void> _saveUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('google_script_url', url);
  }

  Future<void> _handleSync() async {
    if (_urlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your Google Script URL first')));
      return;
    }

    setState(() => _isSyncing = true);

    try {
      final ballProv = Provider.of<BallProvider>(context, listen: false);
      final fineProv = Provider.of<FineProvider>(context, listen: false);
      final contProv = Provider.of<ContributionProvider>(context, listen: false);
      final fundProv = Provider.of<FundProvider>(context, listen: false);

      final players = ballProv.players;
      final List<Map<String, dynamic>> enriched = players.map((p) {
        final double finePaid = fineProv.getTotalPaidForPlayer(p.id!, 'Overall');
        final double allContribs = contProv.contributions.where((c) => c.playerId == p.id!).fold(0.0, (s, c) => s + c.taka);
        final double totalFineOwed = p.totalLost * 50.0;
        final double totalMoneyGiven = finePaid + allContribs;
        double due = 0; double credit = 0;
        if (totalMoneyGiven >= totalFineOwed) {
          due = 0; credit = totalMoneyGiven - totalFineOwed;
        } else {
          due = totalFineOwed - totalMoneyGiven; credit = 0;
        }
        return {'name': p.name, 'total': p.totalLost, 'totalFine': totalFineOwed, 'paid': totalMoneyGiven, 'due': due, 'surplus': credit};
      }).toList();

      final success = await GoogleSyncService.syncAllData(
        scriptUrl: _urlController.text,
        playerStatus: enriched,
        ballRecords: ballProv.allRecords,
        contribs: contProv.contributions,
        payments: fineProv.payments,
        funds: fundProv.funds,
      );

      if (mounted) {
        StatusDialog.show(context, title: success ? "SYNC SUCCESS" : "SYNC FAILED", message: success ? "All data synced to Google Sheets!" : "Check your Script URL and permissions.", isSuccess: success);
      }
    } catch (e) {
      if (mounted) StatusDialog.show(context, title: "ERROR", message: e.toString(), isSuccess: false);
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF051970),
      appBar: AppBar(
        title: Text('ADMIN PANEL', style: GoogleFonts.bebasNeue(color: Colors.white, letterSpacing: 1.2)),
        backgroundColor: const Color(0xFF020C3B),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSyncSection(),
            const SizedBox(height: 40),
            Text('PLAYER MANAGEMENT', style: GoogleFonts.bebasNeue(color: Colors.orange, fontSize: 18, letterSpacing: 1)),
            const SizedBox(height: 15),
            _buildActionTile(context, 'ADD NEW PLAYER', Icons.person_add_alt_1, Colors.greenAccent, () {}),
            _buildActionTile(context, 'EDIT PLAYER INFO', Icons.manage_accounts, Colors.blueAccent, () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF020C3B),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_sync_rounded, color: Colors.orange, size: 28),
              const SizedBox(width: 15),
              Text('GOOGLE SHEETS SYNC', style: GoogleFonts.bebasNeue(color: Colors.white, fontSize: 20)),
            ],
          ),
          const SizedBox(height: 15),
          Text('Enter your Google Apps Script Web App URL below to sync all data to your master spreadsheet.', style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 20),
          TextField(
            controller: _urlController,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              hintText: 'https://script.google.com/macros/s/.../exec',
              hintStyle: const TextStyle(color: Colors.white12),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            ),
            onChanged: _saveUrl,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSyncing ? null : _handleSync,
              icon: _isSyncing ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.sync),
              label: Text(_isSyncing ? 'SYNCING...' : 'START CLOUD SYNC', style: GoogleFonts.bebasNeue(fontSize: 16)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.05))),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
            const SizedBox(width: 20),
            Text(title, style: GoogleFonts.bebasNeue(color: Colors.white, fontSize: 16, letterSpacing: 1)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
          ],
        ),
      ),
    );
  }
}
