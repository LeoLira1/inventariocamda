import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_camda/models/inventory_item.dart';

void main() {
  test('InventoryItem mapeia campos alternativos', () {
    final item = InventoryItem.fromMap({
      'id': '123',
      'produto': 'Milho',
      'grupo': 'Rações',
      'saldo': '10,5',
      'und': 'KG',
    });

    expect(item.codigo, '123');
    expect(item.descricao, 'Milho');
    expect(item.categoria, 'Rações');
    expect(item.quantidade, 10.5);
    expect(item.unidade, 'KG');
  });
}
