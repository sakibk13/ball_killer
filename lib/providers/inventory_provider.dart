import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/inventory.dart';
import '../models/ball_record.dart';
import '../services/database_service.dart';

class InventoryProvider with ChangeNotifier {
  List<Inventory> _inventoryList = [];
  bool _isLoading = false;

  List<Inventory> get inventoryList => _inventoryList;
  bool get isLoading => _isLoading;

  Future<void> fetchInventory({bool force = false}) async {
    if (!force && _inventoryList.isNotEmpty) return;
    
    _isLoading = true;
    notifyListeners();
    try {
      _inventoryList = await DatabaseService().getInventory();
    } catch (e) {
      debugPrint('Fetch Inventory Error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    await fetchInventory(force: true);
  }

  Future<bool> addInventory(Inventory inventory) async {
    _isLoading = true;
    notifyListeners();
    bool success = false;
    try {
      success = await DatabaseService().addInventory(inventory);
      if (success) {
        await refresh();
      }
    } catch (e) {
      debugPrint('Add Inventory Error: $e');
    }
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<void> deleteInventory(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      await DatabaseService().deleteInventory(id);
      await refresh();
    } catch (e) {
      debugPrint('Delete Inventory Error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Map<String, Map<String, int>> getMonthlyTotals() {
    Map<String, Map<String, int>> totals = {}; // { "MM-yyyy": { "bought": X, "tape": Y, "lost": Z } }
    
    for (var item in _inventoryList) {
      if (!totals.containsKey(item.monthYear)) {
        totals[item.monthYear] = {"bought": 0, "tape": 0, "lost": 0};
      }
      if (!item.isStockUpdate) {
        totals[item.monthYear]!["bought"] = totals[item.monthYear]!["bought"]! + item.ballsBrought;
        totals[item.monthYear]!["tape"] = totals[item.monthYear]!["tape"]! + item.tapesBrought;
        totals[item.monthYear]!["lost"] = totals[item.monthYear]!["lost"]! + item.ballsLost;
      }
    }
    return totals;
  }

  // Stock is now completely manual. 
  // It returns the totalStock from the LATEST 'isStockUpdate' entry.
  int getCumulativeRemaining(String upToMonthYear) {
    if (_inventoryList.isEmpty) return 0;

    // Filter list by date limit
    List<Inventory> filtered = _inventoryList;
    if (upToMonthYear != 'Overall') {
      try {
        DateTime limitDate = DateFormat('MM-yyyy').parse(upToMonthYear);
        DateTime endOfMonth = DateTime(limitDate.year, limitDate.month + 1, 0, 23, 59, 59);
        filtered = _inventoryList.where((item) => item.date.isBefore(endOfMonth)).toList();
      } catch (e) {
        debugPrint('Limit Date Parse Error: $e');
      }
    }

    if (filtered.isEmpty) return 0;

    // Find the latest manual stock update entry
    List<Inventory> stockUpdates = filtered.where((item) => item.isStockUpdate).toList();
    if (stockUpdates.isEmpty) return 0;

    // Sort by date descending to get the latest
    stockUpdates.sort((a, b) => b.date.compareTo(a.date));
    
    return stockUpdates.first.totalStock;
  }

  List<Inventory> getItemsForMonth(String monthYear) {
    if (monthYear == 'Overall') return _inventoryList;
    return _inventoryList.where((item) => item.monthYear == monthYear).toList();
  }
}
