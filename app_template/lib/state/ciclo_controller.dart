import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../models/item_ciclo.dart';
import '../models/produto_estoque.dart';
import '../services/local_cache_service.dart';
import '../services/turso_service.dart';

enum FiltroStatus { todos, naoContados, contados, comDivergencia }

class CicloController extends ChangeNotifier {
  CicloController({required LocalCacheService cacheService})
      : _cacheService = cacheService;

  final LocalCacheService _cacheService;
  TursoService? _turso;

  List<ProdutoEstoque> _produtos = [];
  // keyed by produto codigo
  Map<String, ItemCiclo> _ciclo = {};

  bool _loading = false;
  bool _saving = false;
  String? _error;

  String _query = '';
  String _selectedCategory = 'Todas';
  FiltroStatus _filtroStatus = FiltroStatus.todos;
  String _dataContagem = DateFormat('yyyy-MM-dd').format(DateTime.now());

  String _dbUrl = '';
  String _authToken = '';

  // ── getters ────────────────────────────────────────────────────────────────

  bool get loading => _loading;
  bool get saving => _saving;
  String? get error => _error;
  String get query => _query;
  String get selectedCategory => _selectedCategory;
  FiltroStatus get filtroStatus => _filtroStatus;
  String get dataContagem => _dataContagem;
  String get dbUrl => _dbUrl;
  String get authToken => _authToken;
  bool get configured => _dbUrl.isNotEmpty && _authToken.isNotEmpty;
  Map<String, ItemCiclo> get ciclo => _ciclo;

  List<String> get categories {
    final cats = _produtos.map((p) => p.categoria).toSet().toList()..sort();
    return ['Todas', ...cats];
  }

  List<ProdutoEstoque> get filteredProdutos {
    return _produtos.where((p) {
      final qMatch = _query.isEmpty ||
          p.produto.toLowerCase().contains(_query.toLowerCase()) ||
          p.codigo.toLowerCase().contains(_query.toLowerCase());
      final cMatch =
          _selectedCategory == 'Todas' || p.categoria == _selectedCategory;
      final item = _ciclo[p.codigo];
      final sMatch = switch (_filtroStatus) {
        FiltroStatus.todos => true,
        FiltroStatus.naoContados => item == null,
        FiltroStatus.contados => item != null,
        FiltroStatus.comDivergencia =>
          item != null && item.temDivergencia,
      };
      return qMatch && cMatch && sMatch;
    }).toList();
  }

  int get totalProdutos => _produtos.length;
  int get totalContados => _ciclo.length;
  int get totalNaoContados => totalProdutos - totalContados;
  int get totalDivergencias =>
      _ciclo.values.where((c) => c.temDivergencia).length;

  // ── init ───────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    _dbUrl = await _cacheService.getDbUrl();
    _authToken = await _cacheService.getAuthToken();
    _buildTurso();
    notifyListeners();
  }

  void _buildTurso() {
    if (_dbUrl.isNotEmpty && _authToken.isNotEmpty) {
      _turso = TursoService(dbUrl: _dbUrl, authToken: _authToken);
    } else {
      _turso = null;
    }
  }

  // ── config ─────────────────────────────────────────────────────────────────

  Future<void> updateConfig(String dbUrl, String authToken) async {
    _dbUrl = dbUrl.trim();
    _authToken = authToken.trim();
    await _cacheService.saveDbUrl(_dbUrl);
    await _cacheService.saveAuthToken(_authToken);
    _buildTurso();
    notifyListeners();
  }

  // ── sync ───────────────────────────────────────────────────────────────────

  Future<void> sync() async {
    if (!configured) {
      _error = 'Configure a URL do banco e o token de autenticação.';
      notifyListeners();
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final produtos = await _turso!.fetchProdutos();
      final cicloItems = await _turso!.fetchCiclo(_dataContagem);

      _produtos = produtos;
      _ciclo = {for (final item in cicloItems) item.produtoId: item};
    } catch (e) {
      _error = _friendlyError(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── count ──────────────────────────────────────────────────────────────────

  Future<void> salvarContagem({
    required ProdutoEstoque produto,
    required double qtdContada,
    required String observacao,
  }) async {
    _saving = true;
    _error = null;
    notifyListeners();

    try {
      await _turso!.salvarContagem(
        dataContagem: _dataContagem,
        produtoId: produto.codigo,
        produtoNome: produto.produto,
        categoriaId: produto.categoria,
        categoriaLabel: produto.categoria,
        categoriaCor: '#888888',
        qtdSistema: produto.qtdSistema.toDouble(),
        qtdContada: qtdContada,
        observacao: observacao,
      );

      // optimistic local update
      _ciclo[produto.codigo] = ItemCiclo(
        dataContagem: _dataContagem,
        produtoId: produto.codigo,
        produtoNome: produto.produto,
        categoriaId: produto.categoria,
        categoriaLabel: produto.categoria,
        qtdSistema: produto.qtdSistema.toDouble(),
        qtdContada: qtdContada,
        divergencia: qtdContada - produto.qtdSistema,
        contadoEm: DateTime.now().toIso8601String(),
        observacao: observacao,
      );
    } catch (e) {
      _error = _friendlyError(e);
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  // ── filters ────────────────────────────────────────────────────────────────

  void updateQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void updateCategory(String value) {
    _selectedCategory = value;
    notifyListeners();
  }

  void updateFiltroStatus(FiltroStatus value) {
    _filtroStatus = value;
    notifyListeners();
  }

  void updateDataContagem(String value) {
    _dataContagem = value;
    _ciclo.clear();
    notifyListeners();
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  String _friendlyError(Object e) {
    if (e is SocketException ||
        (e is http.ClientException &&
            e.message.contains('SocketException')) ||
        e.toString().contains('Failed host lookup')) {
      return 'Sem conexão com a internet.';
    }
    return e.toString();
  }
}
