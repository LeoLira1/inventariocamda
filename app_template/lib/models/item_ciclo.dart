class ItemCiclo {
  const ItemCiclo({
    this.id,
    required this.dataContagem,
    required this.produtoId,
    this.produtoNome = '',
    this.categoriaId = '',
    this.categoriaLabel = '',
    this.categoriaCor = '#888888',
    this.qtdSistema = 0,
    this.qtdContada,
    this.divergencia,
    this.score = 0,
    this.contadoEm = '',
    this.observacao = '',
  });

  final int? id;
  final String dataContagem;
  final String produtoId;
  final String produtoNome;
  final String categoriaId;
  final String categoriaLabel;
  final String categoriaCor;
  final double qtdSistema;
  final double? qtdContada;
  final double? divergencia;
  final double score;
  final String contadoEm;
  final String observacao;

  bool get foiContado => qtdContada != null;
  bool get temDivergencia => foiContado && (divergencia ?? 0) != 0;

  factory ItemCiclo.fromTursoRow(List<dynamic> cols, List<dynamic> row) {
    final map = <String, dynamic>{};
    for (var i = 0; i < cols.length; i++) {
      final name = (cols[i] as Map)['name'] as String;
      map[name] = _cell(row[i]);
    }
    return ItemCiclo(
      id: _intOrNull(map, 'id'),
      dataContagem: _str(map, 'data_contagem'),
      produtoId: _str(map, 'produto_id'),
      produtoNome: _str(map, 'produto_nome'),
      categoriaId: _str(map, 'categoria_id'),
      categoriaLabel: _str(map, 'categoria_label'),
      categoriaCor: _str(map, 'categoria_cor', fallback: '#888888'),
      qtdSistema: _double(map, 'qtd_sistema'),
      qtdContada: _doubleOrNull(map, 'qtd_contada'),
      divergencia: _doubleOrNull(map, 'divergencia'),
      score: _double(map, 'score'),
      contadoEm: _str(map, 'contado_em'),
      observacao: _str(map, 'observacao'),
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

  static double _double(Map<String, dynamic> m, String k) {
    final v = m[k];
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static double? _doubleOrNull(Map<String, dynamic> m, String k) {
    final v = m[k];
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static int? _intOrNull(Map<String, dynamic> m, String k) {
    final v = m[k];
    if (v == null) return null;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }
}
