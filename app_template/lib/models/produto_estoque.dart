class ProdutoEstoque {
  const ProdutoEstoque({
    required this.codigo,
    required this.produto,
    required this.categoria,
    required this.qtdSistema,
    this.qtdFisica = 0,
    this.diferenca = 0,
    this.nota = '',
    this.status = 'ok',
    this.ultimaContagem = '',
    this.criadoEm = '',
    this.observacoes = '',
    this.statusCiclo = '',
    this.qtdContadaCiclo,
    this.qtdSistemaNaContagem,
    this.contadoCicloEm = '',
  });

  final String codigo;
  final String produto;
  final String categoria;
  final int qtdSistema;
  final int qtdFisica;
  final int diferenca;
  final String nota;
  final String status;
  final String ultimaContagem;
  final String criadoEm;
  final String observacoes;
  final String statusCiclo;
  final int? qtdContadaCiclo;
  final int? qtdSistemaNaContagem;
  final String contadoCicloEm;

  factory ProdutoEstoque.fromTursoRow(List<dynamic> cols, List<dynamic> row) {
    final map = <String, dynamic>{};
    for (var i = 0; i < cols.length; i++) {
      final name = (cols[i] as Map)['name'] as String;
      map[name] = _cell(row[i]);
    }
    return ProdutoEstoque(
      codigo: _str(map, 'codigo'),
      produto: _str(map, 'produto'),
      categoria: _str(map, 'categoria'),
      qtdSistema: _int(map, 'qtd_sistema'),
      qtdFisica: _int(map, 'qtd_fisica'),
      diferenca: _int(map, 'diferenca'),
      nota: _str(map, 'nota'),
      status: _str(map, 'status', fallback: 'ok'),
      ultimaContagem: _str(map, 'ultima_contagem'),
      criadoEm: _str(map, 'criado_em'),
      observacoes: _str(map, 'observacoes'),
      statusCiclo: _str(map, 'status_ciclo'),
      qtdContadaCiclo: _intOrNull(map, 'qtd_contada_ciclo'),
      qtdSistemaNaContagem: _intOrNull(map, 'qtd_sistema_na_contagem'),
      contadoCicloEm: _str(map, 'contado_ciclo_em'),
    );
  }

  static dynamic _cell(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map) {
      final type = raw['type'] as String?;
      if (type == 'null') return null;
      return raw['value'];
    }
    return raw;
  }

  static String _str(Map<String, dynamic> m, String k, {String fallback = ''}) {
    final v = m[k];
    if (v == null) return fallback;
    return v.toString();
  }

  static int _int(Map<String, dynamic> m, String k) {
    final v = m[k];
    if (v == null) return 0;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static int? _intOrNull(Map<String, dynamic> m, String k) {
    final v = m[k];
    if (v == null) return null;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }
}
