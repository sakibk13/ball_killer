import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/player.dart';
import '../models/ball_record.dart';
import '../services/database_service.dart';

class BallProvider with ChangeNotifier {
  List<Player> _players = [];
  List<BallRecord> _allRecords = [];
  List<BallRecord> _todayRecords = [];
  bool _isLoading = false;

  BallProvider() {
    init();
  }

  Future<void> init({bool force = false}) async {
    if (!force && _players.isNotEmpty) return;
    
    _isLoading = true;
    notifyListeners();
    try {
      await Future.wait([
        _fetchPlayersNoNotify(),
        _fetchTodayRecordsNoNotify(),
        _fetchAllRecordsNoNotify(),
      ]);
    } catch (e) {
      debugPrint('Init Error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    await init(force: true);
  }

  Future<void> _fetchPlayersNoNotify() async {
    try {
      _players = await DatabaseService().getPlayers();
      _players.sort((a, b) => b.totalLost.compareTo(a.totalLost)); 
    } catch (e) {
      debugPrint('Fetch Players Error: $e');
    }
  }

  Future<void> _fetchAllRecordsNoNotify() async {
    try {
      _allRecords = await DatabaseService().getRecords();
    } catch (e) {
      debugPrint('Fetch All Records Error: $e');
    }
  }

  Future<void> _fetchTodayRecordsNoNotify() async {
    try {
      _todayRecords = await DatabaseService().getTodayRecords();
    } catch (e) {
      debugPrint('Fetch Today Records Error: $e');
    }
  }

  List<Player> get players => _players;
  List<BallRecord> get allRecords => _allRecords;
  List<BallRecord> get todayRecords => _todayRecords;
  bool get isLoading => _isLoading;

  List<Map<String, dynamic>> getPlayersWithTotals({String? monthYear}) {
    if (monthYear == null || monthYear == 'Overall') {
      return _players.map((p) => {
        'id': p.id,
        'name': p.name,
        'phone': p.phone,
        'photoUrl': p.photoUrl,
        'password': p.password,
        'total': p.totalLost,
      }).toList();
    }

    Map<String, int> monthlyTotals = {};
    for (var record in _allRecords) {
      if (record.monthYear == monthYear) {
        monthlyTotals[record.playerId] = (monthlyTotals[record.playerId] ?? 0) + record.lostCount;
      }
    }

    return _players.map((p) => {
      'id': p.id,
      'name': p.name,
      'phone': p.phone,
      'photoUrl': p.photoUrl,
      'password': p.password,
      'total': monthlyTotals[p.id!] ?? 0,
    }).toList()..sort((a, b) => (b['total'] as num).compareTo(a['total'] as num));
  }

  List<Map<String, dynamic>> getMonthlyLeaderboard(String monthYear) {
    List<Map<String, dynamic>> playersWithData = getPlayersWithTotals(monthYear: monthYear);
    return playersWithData.map((p) => {
      'name': p['name'],
      'total': p['total'],
      'photoUrl': p['photoUrl'],
    }).toList();
  }

  Future<void> fetchPlayers() async {
    _isLoading = true;
    notifyListeners();
    await _fetchPlayersNoNotify();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchAllRecords() async {
    _isLoading = true;
    notifyListeners();
    await _fetchAllRecordsNoNotify();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchTodayRecords() async {
    _isLoading = true;
    notifyListeners();
    await _fetchTodayRecordsNoNotify();
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addPlayer({
    required String name,
    required String phone,
    int initialLoss = 0,
    required String recordedBy,
  }) async {
    _isLoading = true;
    notifyListeners();
    bool success = false;
    try {
      final player = Player(name: name, phone: phone, totalLost: 0); 
      final insertedPlayer = await DatabaseService().addOrUpdatePlayer(player);
      
      if (insertedPlayer != null) {
        success = true;
        if (initialLoss > 0) {
          final now = DateTime.now();
          final record = BallRecord(
            playerId: insertedPlayer.id!,
            playerName: insertedPlayer.name,
            lostCount: initialLoss,
            date: now,
            recordedBy: recordedBy,
            monthYear: DateFormat('MM-yyyy').format(now),
          );
          await DatabaseService().addRecord(record);
        }
      }
      
      await fetchPlayers();
      await fetchTodayRecords();
      await fetchAllRecords();
    } catch (e) {
      debugPrint('Add Player Error: $e');
    }
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<void> addBallRecordWithDate({
    required String playerId,
    required String playerName,
    required int lostCount,
    required DateTime date,
    required String recordedBy,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final record = BallRecord(
        playerId: playerId,
        playerName: playerName,
        lostCount: lostCount,
        date: date,
        recordedBy: recordedBy,
        monthYear: DateFormat('MM-yyyy').format(date),
      );

      await DatabaseService().addRecord(record);
      await fetchPlayers();
      await fetchTodayRecords();
      await fetchAllRecords();
    } catch (e) {
      debugPrint('Force Entry Error: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updatePlayerLoss(String playerId, int change, String recordedBy, {String? monthYear}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final player = _players.firstWhere((p) => p.id == playerId);
      DateTime now = DateTime.now();
      if (monthYear != null && monthYear != 'Overall' && monthYear != DateFormat('MM-yyyy').format(now)) {
        try {
          now = DateFormat('MM-yyyy').parse(monthYear);
        } catch (e) {
          debugPrint('Date Parse Error: $e');
        }
      }

      final record = BallRecord(
        playerId: playerId,
        playerName: player.name,
        lostCount: change,
        date: now,
        recordedBy: recordedBy,
        monthYear: monthYear ?? DateFormat('MM-yyyy').format(now),
      );

      await DatabaseService().addRecord(record);
      await fetchPlayers();
      await fetchTodayRecords();
      await fetchAllRecords();
    } catch (e) {
      debugPrint('Update Error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addBallRecord({
    required String playerName,
    required int lostCount,
    required String recordedBy,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      Player? player = await DatabaseService().getPlayerByName(playerName);
      if (player == null) {
        player = Player(name: playerName, phone: 'Unknown');
        player = await DatabaseService().addOrUpdatePlayer(player);
      }

      final now = DateTime.now();
      final record = BallRecord(
        playerId: player!.id!,
        playerName: player.name,
        lostCount: lostCount,
        date: now,
        recordedBy: recordedBy,
        monthYear: DateFormat('MM-yyyy').format(now),
      );

      await DatabaseService().addRecord(record);
      await fetchPlayers();
      await fetchTodayRecords();
      await fetchAllRecords();
    } catch (e) {
      debugPrint('Error: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }

  int getTotalLostForMonth(String monthYear) {
    if (monthYear == 'Overall') {
      return _players.fold(0, (sum, p) => sum + p.totalLost);
    }
    
    int total = 0;
    for (var record in _allRecords) {
      if (record.monthYear == monthYear) {
        total += record.lostCount;
      }
    }
    return total;
  }

  Future<bool> updatePlayer(Player player) async {
    _isLoading = true;
    notifyListeners();
    bool success = false;
    try {
      success = await DatabaseService().updatePlayer(player);
      if (success) {
        await fetchPlayers();
      }
    } catch (e) {
      debugPrint('Update Player Error: $e');
    }
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<void> addPlayerDirect(Player player) async {
    _isLoading = true;
    notifyListeners();
    try {
      await DatabaseService().addOrUpdatePlayer(player);
      await fetchPlayers();
    } catch (e) {
      debugPrint('Add Player Error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteRecord(String recordId, String playerId, int lostCount) async {
    _isLoading = true;
    notifyListeners();
    await DatabaseService().deleteRecord(recordId, playerId, lostCount);
    await fetchPlayers();
    await fetchTodayRecords();
    await fetchAllRecords();
    _isLoading = false;
    notifyListeners();
  }
}
