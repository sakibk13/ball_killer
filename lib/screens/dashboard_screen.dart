import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/ball_provider.dart';
import '../providers/inventory_provider.dart';
import 'manage_players_screen.dart';
import 'records_screen.dart';
import 'inventory_screen.dart';
import 'contribution_screen.dart';
import 'leaderboard_screen.dart';
import '../utils/status_dialog.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BallProvider>(context, listen: false).init();
      Provider.of<InventoryProvider>(context, listen: false).fetchInventory();
    });
  }

  Uint8List? _safeDecode(String? base64String) {
    if (base64String == null || base64String.trim().isEmpty) return null;
    try {
      // Handle potential data:image/png;base64, prefixes
      String cleanString = base64String.trim();
      if (cleanString.contains(',')) {
        cleanString = cleanString.split(',').last;
      }
      return base64Decode(cleanString);
    } catch (e) {
      debugPrint('Decode error: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final ballProvider = Provider.of<BallProvider>(context);
    final invProvider = Provider.of<InventoryProvider>(context);
    
    final isAdmin = authProvider.isAdmin;
    final remainingBalls = invProvider.getCumulativeRemaining('Overall');
    final user = authProvider.currentUser;
    final photoBytes = _safeDecode(user?.photoUrl);

    return Scaffold(
      backgroundColor: const Color(0xFF051970),
      appBar: AppBar(
        backgroundColor: const Color(0xFF020C3B),
        elevation: 0,
        title: Row(
          children: [
            Image.asset('assets/icon/logo3.png', width: 35, height: 35, errorBuilder: (c, e, s) => const Icon(Icons.sports_cricket, color: Colors.orange)),
            const SizedBox(width: 10),
            Text('DASHBOARD', style: GoogleFonts.bebasNeue(letterSpacing: 1.5, color: Colors.white, fontSize: 22)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white70),
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await authProvider.refreshUser();
          await ballProvider.refresh();
          await invProvider.fetchInventory(force: true);
        },
        color: Colors.orange,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('HELLO,', style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        Text(user?.name.toUpperCase() ?? 'PLAYER', style: GoogleFonts.bebasNeue(fontSize: 28, color: Colors.white, letterSpacing: 1)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.orange.withOpacity(0.5), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      backgroundImage: photoBytes != null ? MemoryImage(photoBytes) : null,
                      child: photoBytes == null
                          ? Text(user?.name[0].toUpperCase() ?? '?', style: GoogleFonts.bebasNeue(color: Colors.orange, fontSize: 28))
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              _buildStatsCard(remainingBalls, ballProvider),
              const SizedBox(height: 30),
              Text('QUICK ACTIONS', style: GoogleFonts.bebasNeue(fontSize: 18, color: Colors.orange, letterSpacing: 1)),
              const SizedBox(height: 15),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                childAspectRatio: 1.2,
                children: [
                  _buildMenuBtn(context, 'RECORDS', Icons.history_rounded, const Color(0xFF42A5F5), const RecordsScreen()),
                  _buildMenuBtn(context, 'TOP PLAYERS', Icons.leaderboard_rounded, const Color(0xFFFFA726), const LeaderboardScreen()),
                  _buildMenuBtn(context, 'INVENTORY', Icons.inventory_2_rounded, const Color(0xFF66BB6A), const InventoryScreen()),
                  _buildMenuBtn(context, 'FINANCIALS', Icons.payments_rounded, const Color(0xFFAB47BC), const ContributionScreen()),
                  if (isAdmin)
                    _buildMenuBtn(context, 'MANAGE', Icons.manage_accounts_rounded, const Color(0xFFEF5350), const ManagePlayersScreen()),
                ],
              ),
              const SizedBox(height: 40),
              Center(
                child: Opacity(
                  opacity: 0.1,
                  child: Image.asset('assets/icon/logo3.png', width: 80, errorBuilder: (c, e, s) => const SizedBox()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(int stock, BallProvider ball) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem('STOCK IN HAND', '$stock', Colors.greenAccent, Icons.inventory),
          Container(width: 1, height: 40, color: Colors.white10),
          _statItem('LOST TODAY', '${ball.todayRecords.fold(0, (sum, r) => sum + r.lostCount)}', Colors.redAccent, Icons.auto_delete),
        ],
      ),
    );
  }

  Widget _statItem(String label, String val, Color color, IconData icon) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color.withOpacity(0.5), size: 12),
            const SizedBox(width: 5),
            Text(label, style: GoogleFonts.poppins(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ],
        ),
        const SizedBox(height: 5),
        Text(val, style: GoogleFonts.bebasNeue(fontSize: 36, color: color, letterSpacing: 1)),
      ],
    );
  }

  Widget _buildMenuBtn(BuildContext context, String label, IconData icon, Color color, Widget screen) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(label, style: GoogleFonts.bebasNeue(color: Colors.white, fontSize: 16, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }
}