import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/ball_provider.dart';
import '../models/ball_record.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BallProvider>(context, listen: false).fetchAllRecords();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final ballProvider = Provider.of<BallProvider>(context);
    final isAdmin = authProvider.isAdmin;

    final totalLost = ballProvider.allRecords.fold(0, (sum, r) => sum + r.lostCount);

    return Scaffold(
      backgroundColor: const Color(0xFF051970),
      appBar: AppBar(
        title: Text(
          'ACTIVITY HISTORY',
          style: GoogleFonts.bebasNeue(fontSize: 24, letterSpacing: 1.5, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF020C3B),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => ballProvider.refresh(),
        color: Colors.orange,
        child: ballProvider.isLoading && ballProvider.allRecords.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : Column(
              children: [
                _buildStatsHeader(totalLost),
                Expanded(
                  child: ballProvider.allRecords.isEmpty 
                    ? Center(child: Text('No activity yet', style: GoogleFonts.poppins(color: Colors.white24)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: ballProvider.allRecords.length,
                        itemBuilder: (context, index) {
                          return _buildRecordCard(context, ballProvider.allRecords[index], isAdmin);
                        },
                      ),
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildStatsHeader(int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF020C3B),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('GRAND TOTAL LOST', style: GoogleFonts.bebasNeue(color: Colors.white38, fontSize: 14, letterSpacing: 1.2)),
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

  Widget _buildRecordCard(BuildContext context, BallRecord record, bool isAdmin) {
    final ballProvider = Provider.of<BallProvider>(context, listen: false);
    final isLoss = record.lostCount > 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isLoss ? Colors.redAccent : Colors.greenAccent).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isLoss ? Icons.remove_circle_outline : Icons.add_circle_outline,
              color: isLoss ? Colors.redAccent : Colors.greenAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.playerName,
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  DateFormat('dd MMM, hh:mm a').format(record.date),
                  style: GoogleFonts.poppins(color: Colors.white38, fontSize: 10),
                ),
                if (isAdmin)
                  Text(
                    'Recorded by: ${record.recordedBy}',
                    style: GoogleFonts.poppins(color: Colors.white24, fontSize: 9),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (isLoss ? Colors.redAccent : Colors.greenAccent).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${isLoss ? "+" : ""}${record.lostCount}',
              style: GoogleFonts.bebasNeue(
                color: isLoss ? Colors.redAccent : Colors.greenAccent,
                fontSize: 20,
              ),
            ),
          ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white24, size: 20),
              onPressed: () => _showDeleteConfirm(context, record, ballProvider),
            ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, BallRecord record, BallProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF020C3B),
        title: const Text('Delete?', style: TextStyle(color: Colors.white)),
        content: const Text('Remove this record from history?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.deleteRecord(record.id!, record.playerId, record.lostCount);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}