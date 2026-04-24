class InventoryItem {
  const InventoryItem({
    required this.codigo,
    required this.descricao,
    required this.categoria,
    required this.quantidade,
    required this.unidade,
    required this.atualizadoEm,
  });

  final String codigo;
  final String descricao;
  final String categoria;
  final double quantidade;
  final String unidade;
  final DateTime atualizadoEm;

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    final codigo = _asString(map, const ['codigo', 'cod', 'id', 'sku']);
    final descricao = _asString(
      map,
      const ['descricao', 'descricao_item', 'produto', 'nome', 'description'],
    );
    final categoria = _asString(map, const ['categoria', 'grupo', 'setor']);
    final unidade = _asString(map, const ['unidade', 'und', 'uom']);

    return InventoryItem(
      codigo: codigo.isEmpty ? 'SEM-CODIGO' : codigo,
      descricao: descricao.isEmpty ? 'Sem descrição' : descricao,
      categoria: categoria.isEmpty ? 'Não categorizado' : categoria,
      quantidade: _asDouble(map, const ['quantidade', 'qtd', 'estoque', 'saldo']),
      unidade: unidade.isEmpty ? 'UN' : unidade,
      atualizadoEm: _asDateTime(map, const ['atualizado_em', 'updated_at', 'data']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'codigo': codigo,
      'descricao': descricao,
      'categoria': categoria,
      'quantidade': quantidade,
      'unidade': unidade,
      'atualizado_em': atualizadoEm.toIso8601String(),
    };
  }

  static String _asString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value != null) {
        return value.toString().trim();
      }
    }
    return '';
  }

  static double _asDouble(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      if (value is num) return value.toDouble();
      final normalized = value.toString().replaceAll(',', '.');
      final parsed = double.tryParse(normalized);
      if (parsed != null) return parsed;
    }
    return 0;
  }

  static DateTime _asDateTime(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      if (value is DateTime) return value;
      final parsed = DateTime.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
    return DateTime.now();
  }
}
