import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/ball_provider.dart';
import '../providers/inventory_provider.dart';
import 'manage_players_screen.dart';
import 'player_ball_loss_screen.dart';
import 'records_screen.dart';
import 'inventory_screen.dart';
import 'contribution_screen.dart';
import 'leaderboard_screen.dart';
import 'fine_screen.dart';
import '../utils/status_dialog.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fadeController.forward();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BallProvider>(context, listen: false).init();
      Provider.of<InventoryProvider>(context, listen: false).fetchInventory();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Uint8List? _safeDecode(String? base64String) {
    if (base64String == null || base64String.trim().isEmpty) return null;
    try {
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF020C3B), Color(0xFF051970), Color(0xFF0A2A99)],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              await authProvider.refreshUser();
              await ballProvider.refresh();
              await invProvider.fetchInventory(force: true);
            },
            color: Colors.orange,
            child: FadeTransition(
              opacity: _fadeController,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildHeader(user, photoBytes, authProvider),
                    const SizedBox(height: 30),
                    _buildStatsGrid(remainingBalls, ballProvider, invProvider, isAdmin),
                    const SizedBox(height: 35),
                    Row(
                      children: [
                        Container(width: 4, height: 20, decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 10),
                        Text('QUICK ACTIONS', style: GoogleFonts.bebasNeue(fontSize: 20, color: Colors.white, letterSpacing: 1.5)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildActionGrid(context, isAdmin),
                    const SizedBox(height: 40),
                    Center(
                      child: Opacity(
                        opacity: 0.05,
                        child: Image.asset('assets/icon/logo3.png', width: 100, errorBuilder: (c, e, s) => const SizedBox()),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(user, photoBytes, authProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('WELCOME BACK,', style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            Text(user?.name.toUpperCase() ?? 'PLAYER', style: GoogleFonts.bebasNeue(fontSize: 32, color: Colors.white, letterSpacing: 1.2)),
          ],
        ),
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 15, spreadRadius: 2)],
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white.withOpacity(0.1),
                backgroundImage: photoBytes != null ? MemoryImage(photoBytes) : null,
                child: photoBytes == null
                    ? Text(user?.name[0].toUpperCase() ?? '?', style: GoogleFonts.bebasNeue(color: Colors.orange, fontSize: 24))
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              icon: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent, size: 28),
              onPressed: () => authProvider.logout(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsGrid(int stock, BallProvider ball, InventoryProvider inv, bool isAdmin) {
    int lostToday = ball.todayRecords.fold(0, (sum, r) => sum + r.lostCount);
    
    // Top player fine calculation for current month
    final currentMonth = DateFormat('MM-yyyy').format(DateTime.now());
    final playersWithTotals = ball.getPlayersWithTotals(monthYear: currentMonth);
    final sortedPlayers = List<Map<String, dynamic>>.from(playersWithTotals)
      ..sort((a, b) => (b['total'] as int).compareTo(a['total'] as int));
    
    final topLost = sortedPlayers.isNotEmpty ? (sortedPlayers.first['total'] as int) : 0;
    final fine = topLost * 50;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildModernStatCard('STOCK COUNT', '$stock', Colors.greenAccent, Icons.inventory_2_outlined)),
            const SizedBox(width: 15),
            Expanded(child: _buildModernStatCard('LOST TODAY', '$lostToday', Colors.redAccent, Icons.running_with_errors_outlined)),
          ],
        ),
        if (isAdmin) ...[
          const SizedBox(height: 15),
          InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FineScreen())),
            borderRadius: BorderRadius.circular(28),
            child: _buildModernStatCard(
              'MONTHLY TOP FINE', 
              '$fine ৳', 
              Colors.orangeAccent, 
              Icons.monetization_on_outlined, 
              fullWidth: true,
              subtitle: 'Top Loser: ${sortedPlayers.isNotEmpty ? sortedPlayers.first['name'] : "None"}'
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildModernStatCard(String label, String val, Color color, IconData icon, {bool fullWidth = false, String? subtitle}) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.02)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 20),
              ),
              if (subtitle != null)
                Text(subtitle, style: GoogleFonts.poppins(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 15),
          Text(val, style: GoogleFonts.bebasNeue(fontSize: 32, color: Colors.white, letterSpacing: 1)),
          Text(label, style: GoogleFonts.poppins(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context, bool isAdmin) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      childAspectRatio: 1.1,
      children: [
        _buildActionCard(context, 'TRACK OVERVIEW', 'Professional history', Icons.auto_graph_rounded, const Color(0xFF42A5F5), const RecordsScreen()),
        _buildActionCard(context, 'LEADERBOARD', 'Top ball killers', Icons.emoji_events_outlined, const Color(0xFFFFA726), const LeaderboardScreen()),
        _buildActionCard(context, 'STOCK LOG', 'Manage inventory', Icons.analytics_outlined, const Color(0xFF66BB6A), const InventoryScreen()),
        _buildActionCard(context, 'FINANCIALS', 'Club collections', Icons.account_balance_wallet_outlined, const Color(0xFFAB47BC), const ContributionScreen()),
        if (isAdmin) ...[
          _buildActionCard(context, 'RECORD LOSS', 'Log, Manage & Track', Icons.add_moderator_outlined, Colors.redAccent, const PlayerBallLossScreen()),
          _buildActionCard(context, 'ADMIN PANEL', 'System management', Icons.admin_panel_settings_outlined, const Color(0xFFEF5350), const ManagePlayersScreen()),
        ],
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, String title, String subtitle, IconData icon, Color color, Widget screen) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8))],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [color.withOpacity(0.25), color.withOpacity(0.05)],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: color.withOpacity(0.2), width: 1),
                      ),
                      child: Icon(icon, color: color, size: 30),
                    ),
                    const SizedBox(height: 12),
                    Text(title, style: GoogleFonts.bebasNeue(color: Colors.white, fontSize: 18, letterSpacing: 1.2)),
                    Text(subtitle, style: GoogleFonts.poppins(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
