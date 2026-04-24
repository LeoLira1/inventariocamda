import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/inventory_item.dart';

class LocalCacheService {
  static const sourceUrlKey = 'inventory_source_url';
  static const inventoryDataKey = 'inventory_data';
  static const syncDateKey = 'inventory_last_sync';

  Future<String> getSourceUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(sourceUrlKey) ??
        'https://raw.githubusercontent.com/LeoLira1/camda-estoque/refs/heads/main/inventario_ciclico_tab.py';
  }

  Future<void> saveSourceUrl(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(sourceUrlKey, value);
  }

  Future<void> saveInventory(List<InventoryItem> items, DateTime syncDate) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = items.map((item) => item.toMap()).toList();
    await prefs.setString(inventoryDataKey, jsonEncode(payload));
    await prefs.setString(syncDateKey, syncDate.toIso8601String());
  }

  Future<List<InventoryItem>> readInventory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(inventoryDataKey);
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }

    final dynamic decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }

    return decoded
        .whereType<Map>()
        .map((item) => InventoryItem.fromMap(item.cast<String, dynamic>()))
        .toList();
  }

  Future<DateTime?> readLastSyncDate() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(syncDateKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }
}
