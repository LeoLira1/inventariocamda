import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/inventory_item.dart';
import '../services/inventory_api_service.dart';
import '../services/local_cache_service.dart';

class InventoryController extends ChangeNotifier {
  InventoryController({
    required InventoryApiService apiService,
    required LocalCacheService cacheService,
  })  : _apiService = apiService,
        _cacheService = cacheService;

  final InventoryApiService _apiService;
  final LocalCacheService _cacheService;

  List<InventoryItem> _items = const [];
  bool _loading = false;
  String _query = '';
  String _selectedCategory = 'Todas';
  String? _error;
  DateTime? _lastSync;
  late String _sourceUrl;

  List<InventoryItem> get items => _items;
  bool get loading => _loading;
  String get query => _query;
  String get selectedCategory => _selectedCategory;
  String? get error => _error;
  DateTime? get lastSync => _lastSync;
  String get sourceUrl => _sourceUrl;

  List<String> get categories {
    final values = _items.map((e) => e.categoria).toSet().toList()..sort();
    return ['Todas', ...values];
  }

  List<InventoryItem> get filteredItems {
    return _items.where((item) {
      final queryMatch = _query.isEmpty ||
          item.codigo.toLowerCase().contains(_query.toLowerCase()) ||
          item.descricao.toLowerCase().contains(_query.toLowerCase());
      final categoryMatch = _selectedCategory == 'Todas' ||
          item.categoria == _selectedCategory;
      return queryMatch && categoryMatch;
    }).toList();
  }

  double get totalQuantidade {
    return filteredItems.fold(0, (sum, item) => sum + item.quantidade);
  }

  Future<void> initialize() async {
    _sourceUrl = await _cacheService.getSourceUrl();
    _items = await _cacheService.readInventory();
    _lastSync = await _cacheService.readLastSyncDate();
    notifyListeners();
  }

  Future<void> sync() async {
    if (_sourceUrl.trim().isEmpty) {
      _error = 'Configure a URL de origem nas configurações (ícone de engrenagem).';
      notifyListeners();
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiService.fetchFromSource(_sourceUrl);
      _items = data;
      _lastSync = DateTime.now();
      await _cacheService.saveInventory(data, _lastSync!);
    } catch (e) {
      if (e is SocketException ||
          (e is http.ClientException && e.message.contains('SocketException')) ||
          e.toString().contains('Failed host lookup')) {
        _error = 'Sem conexão com a internet. Verifique sua conexão e tente novamente.';
      } else {
        _error = e.toString();
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateSourceUrl(String value) async {
    _sourceUrl = value;
    await _cacheService.saveSourceUrl(value);
    notifyListeners();
  }

  void updateQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void updateCategory(String value) {
    _selectedCategory = value;
    notifyListeners();
  }
}
