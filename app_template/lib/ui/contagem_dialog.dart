import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/item_ciclo.dart';
import '../models/produto_estoque.dart';

class ContagemDialog extends StatefulWidget {
  const ContagemDialog({
    super.key,
    required this.produto,
    this.cicloAtual,
    required this.onSalvar,
  });

  final ProdutoEstoque produto;
  final ItemCiclo? cicloAtual;
  final Future<void> Function(double qtd, String obs) onSalvar;

  @override
  State<ContagemDialog> createState() => _ContagemDialogState();
}

class _ContagemDialogState extends State<ContagemDialog> {
  late final TextEditingController _qtdController;
  late final TextEditingController _obsController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final prev = widget.cicloAtual?.qtdContada;
    _qtdController = TextEditingController(
      text: prev != null ? _fmt(prev) : '',
    );
    _obsController = TextEditingController(
      text: widget.cicloAtual?.observacao ?? '',
    );
  }

  @override
  void dispose() {
    _qtdController.dispose();
    _obsController.dispose();
    super.dispose();
  }

  String _fmt(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toString();

  Future<void> _submit() async {
    final raw = _qtdController.text.trim().replaceAll(',', '.');
    final qtd = double.tryParse(raw);
    if (qtd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite uma quantidade válida.')),
      );
      return;
    }
    setState(() => _saving = true);
    await widget.onSalvar(qtd, _obsController.text.trim());
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = widget.produto;
    final prev = widget.cicloAtual;

    return AlertDialog(
      title: Text(p.produto, style: const TextStyle(fontSize: 16)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${p.codigo}  •  ${p.categoria}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            _InfoRow(label: 'Qtd. sistema', value: p.qtdSistema.toString()),
            if (prev != null) ...[
              _InfoRow(
                label: 'Última contagem',
                value: _fmt(prev.qtdContada ?? 0),
              ),
              _InfoRow(
                label: 'Divergência anterior',
                value: _fmt(prev.divergencia ?? 0),
                valueColor: (prev.divergencia ?? 0) != 0
                    ? Colors.orange
                    : Colors.green,
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _qtdController,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
              ],
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                labelText: 'Quantidade contada',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _obsController,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Observação (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Salvar'),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
