import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_camda/models/item_ciclo.dart';

void main() {
  test('ItemCiclo indica corretamente se foi contado', () {
    const naoContado = ItemCiclo(
      dataContagem: '2026-04-28',
      produtoId: 'P001',
    );
    expect(naoContado.foiContado, isFalse);
    expect(naoContado.temDivergencia, isFalse);

    const contadoSemDivergencia = ItemCiclo(
      dataContagem: '2026-04-28',
      produtoId: 'P001',
      qtdSistema: 10,
      qtdContada: 10,
      divergencia: 0,
    );
    expect(contadoSemDivergencia.foiContado, isTrue);
    expect(contadoSemDivergencia.temDivergencia, isFalse);

    const contadoComDivergencia = ItemCiclo(
      dataContagem: '2026-04-28',
      produtoId: 'P001',
      qtdSistema: 10,
      qtdContada: 8,
      divergencia: -2,
    );
    expect(contadoComDivergencia.foiContado, isTrue);
    expect(contadoComDivergencia.temDivergencia, isTrue);
  });
}
