import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/item_ciclo.dart';
import '../models/produto_estoque.dart';

class TursoService {
  TursoService({
    required this.dbUrl,
    required this.authToken,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String dbUrl;
  final String authToken;
  final http.Client _client;

  // ── low-level helpers ──────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _query(
    String sql,
    List<Map<String, dynamic>> args,
  ) async {
    final uri = Uri.parse('$dbUrl/v2/pipeline');
    final body = jsonEncode({
      'requests': [
        {
          'type': 'execute',
          'stmt': {'sql': sql, 'args': args},
        },
        {'type': 'close'},
      ],
    });

    final response = await _client.post(
      uri,
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode < 200 || response.statusCode > 299) {
      throw Exception('Turso ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final results = decoded['results'] as List;
    final first = results[0] as Map<String, dynamic>;

    if (first['type'] == 'error') {
      final msg = (first['error'] as Map?)?['message'] ?? 'Erro desconhecido';
      throw Exception('Turso query error: $msg');
    }

    final execResult =
        (first['response'] as Map)['result'] as Map<String, dynamic>;
    final cols = execResult['cols'] as List;
    final rows = execResult['rows'] as List;

    return rows
        .map((row) => _rowToMap(cols, row as List))
        .toList();
  }

  Future<void> _execute(String sql, List<Map<String, dynamic>> args) async {
    await _query(sql, args);
  }

  Map<String, dynamic> _rowToMap(List cols, List row) {
    final map = <String, dynamic>{};
    for (var i = 0; i < cols.length; i++) {
      final name = (cols[i] as Map)['name'] as String;
      final cell = row[i];
      if (cell == null) {
        map[name] = null;
      } else if (cell is Map) {
        final type = cell['type'] as String?;
        map[name] = (type == 'null') ? null : cell['value'];
      } else {
        map[name] = cell;
      }
    }
    return map;
  }

  // ── public API ─────────────────────────────────────────────────────────────

  Future<List<ProdutoEstoque>> fetchProdutos() async {
    final rows = await _query(
      'SELECT * FROM estoque_mestre ORDER BY produto',
      [],
    );
    return rows.map(_mapToProduto).toList();
  }

  Future<void> ensureInventarioCicliExists() async {
    await _execute(
      'CREATE TABLE IF NOT EXISTS inventario_cicli ('
      '  id INTEGER PRIMARY KEY AUTOINCREMENT,'
      '  data_contagem TEXT NOT NULL,'
      '  produto_id TEXT NOT NULL,'
      '  produto_nome TEXT NOT NULL DEFAULT \'\','
      '  categoria_id TEXT NOT NULL DEFAULT \'\','
      '  categoria_label TEXT NOT NULL DEFAULT \'\','
      '  categoria_cor TEXT NOT NULL DEFAULT \'#888888\','
      '  qtd_sistema REAL NOT NULL DEFAULT 0,'
      '  qtd_contada REAL,'
      '  divergencia REAL,'
      '  score REAL NOT NULL DEFAULT 0,'
      '  contado_em TEXT DEFAULT \'\','
      '  observacao TEXT DEFAULT \'\''
      ')',
      [],
    );
  }

  Future<List<ItemCiclo>> fetchCiclo(String dataContagem) async {
    await ensureInventarioCicliExists();
    final rows = await _query(
      'SELECT * FROM inventario_cicli WHERE data_contagem = ?',
      [_text(dataContagem)],
    );
    return rows.map(_mapToItemCiclo).toList();
  }

  Future<void> salvarContagem({
    required String dataContagem,
    required String produtoId,
    required String produtoNome,
    required String categoriaId,
    required String categoriaLabel,
    required String categoriaCor,
    required double qtdSistema,
    required double qtdContada,
    required String observacao,
  }) async {
    final contadoEm = DateTime.now().toIso8601String();
    final divergencia = qtdContada - qtdSistema;

    final existing = await _query(
      'SELECT id FROM inventario_cicli WHERE data_contagem = ? AND produto_id = ?',
      [_text(dataContagem), _text(produtoId)],
    );

    if (existing.isEmpty) {
      await _execute(
        'INSERT INTO inventario_cicli '
        '(data_contagem, produto_id, produto_nome, categoria_id, categoria_label, '
        'categoria_cor, qtd_sistema, qtd_contada, divergencia, contado_em, observacao) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          _text(dataContagem),
          _text(produtoId),
          _text(produtoNome),
          _text(categoriaId),
          _text(categoriaLabel),
          _text(categoriaCor),
          _float(qtdSistema),
          _float(qtdContada),
          _float(divergencia),
          _text(contadoEm),
          _text(observacao),
        ],
      );
    } else {
      await _execute(
        'UPDATE inventario_cicli SET '
        'qtd_contada = ?, divergencia = ?, contado_em = ?, observacao = ?, '
        'produto_nome = ?, qtd_sistema = ? '
        'WHERE data_contagem = ? AND produto_id = ?',
        [
          _float(qtdContada),
          _float(divergencia),
          _text(contadoEm),
          _text(observacao),
          _text(produtoNome),
          _float(qtdSistema),
          _text(dataContagem),
          _text(produtoId),
        ],
      );
    }

    // Keep estoque_mestre in sync
    await _execute(
      'UPDATE estoque_mestre SET '
      'status_ciclo = ?, qtd_contada_ciclo = ?, '
      'qtd_sistema_na_contagem = qtd_sistema, contado_ciclo_em = ? '
      'WHERE codigo = ?',
      [
        _text('contado'),
        _int(qtdContada.round()),
        _text(contadoEm),
        _text(produtoId),
      ],
    );
  }

  // ── type helpers ───────────────────────────────────────────────────────────

  static Map<String, dynamic> _text(String v) =>
      {'type': 'text', 'value': v};

  static Map<String, dynamic> _float(double v) =>
      {'type': 'float', 'value': v};

  static Map<String, dynamic> _int(int v) =>
      {'type': 'integer', 'value': v.toString()};

  // ── row mappers ────────────────────────────────────────────────────────────

  static ProdutoEstoque _mapToProduto(Map<String, dynamic> m) {
    return ProdutoEstoque(
      codigo: _s(m, 'codigo'),
      produto: _s(m, 'produto'),
      categoria: _s(m, 'categoria'),
      qtdSistema: _i(m, 'qtd_sistema'),
      qtdFisica: _i(m, 'qtd_fisica'),
      diferenca: _i(m, 'diferenca'),
      nota: _s(m, 'nota'),
      status: _s(m, 'status', fallback: 'ok'),
      ultimaContagem: _s(m, 'ultima_contagem'),
      criadoEm: _s(m, 'criado_em'),
      observacoes: _s(m, 'observacoes'),
      statusCiclo: _s(m, 'status_ciclo'),
      qtdContadaCiclo: _iOrNull(m, 'qtd_contada_ciclo'),
      qtdSistemaNaContagem: _iOrNull(m, 'qtd_sistema_na_contagem'),
      contadoCicloEm: _s(m, 'contado_ciclo_em'),
    );
  }

  static ItemCiclo _mapToItemCiclo(Map<String, dynamic> m) {
    return ItemCiclo(
      id: _iOrNull(m, 'id'),
      dataContagem: _s(m, 'data_contagem'),
      produtoId: _s(m, 'produto_id'),
      produtoNome: _s(m, 'produto_nome'),
      categoriaId: _s(m, 'categoria_id'),
      categoriaLabel: _s(m, 'categoria_label'),
      categoriaCor: _s(m, 'categoria_cor', fallback: '#888888'),
      qtdSistema: _d(m, 'qtd_sistema'),
      qtdContada: _dOrNull(m, 'qtd_contada'),
      divergencia: _dOrNull(m, 'divergencia'),
      score: _d(m, 'score'),
      contadoEm: _s(m, 'contado_em'),
      observacao: _s(m, 'observacao'),
    );
  }

  static String _s(Map<String, dynamic> m, String k, {String fallback = ''}) {
    final v = m[k];
    return v == null ? fallback : v.toString();
  }

  static int _i(Map<String, dynamic> m, String k) {
    final v = m[k];
    if (v == null) return 0;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static int? _iOrNull(Map<String, dynamic> m, String k) {
    final v = m[k];
    if (v == null) return null;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static double _d(Map<String, dynamic> m, String k) {
    final v = m[k];
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static double? _dOrNull(Map<String, dynamic> m, String k) {
    final v = m[k];
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
