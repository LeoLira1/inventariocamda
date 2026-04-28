import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/produto_estoque.dart';
import '../state/ciclo_controller.dart';
import 'contagem_dialog.dart';

class CicloPage extends StatelessWidget {
  const CicloPage({super.key, required this.controller});

  final CicloController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Inventário Cíclico'),
            actions: [
              IconButton(
                icon: const Icon(Icons.calendar_today),
                tooltip: 'Data da contagem',
                onPressed: () => _pickDate(context),
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'Configurações',
                onPressed: () => _openConfig(context),
              ),
            ],
          ),
          body: Column(
            children: [
              _SummaryBar(controller: controller),
              _FilterBar(controller: controller),
              const Divider(height: 0),
              Expanded(child: _ProductList(controller: controller)),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final current = DateFormat('yyyy-MM-dd').parse(controller.dataContagem);
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      controller.updateDataContagem(DateFormat('yyyy-MM-dd').format(picked));
      if (context.mounted) {
        controller.sync();
      }
    }
  }

  Future<void> _openConfig(BuildContext context) async {
    final urlCtrl = TextEditingController(text: controller.dbUrl);
    final tokenCtrl = TextEditingController(text: controller.authToken);

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Configuração do banco'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                labelText: 'URL do banco Turso',
                hintText: 'https://camda-estoque-xxx.turso.io',
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tokenCtrl,
              decoration: const InputDecoration(
                labelText: 'Token de autenticação',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              await controller.updateConfig(
                urlCtrl.text.trim(),
                tokenCtrl.text.trim(),
              );
              if (ctx.mounted) Navigator.pop(ctx);
              controller.sync();
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}

// ── summary bar ────────────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.controller});
  final CicloController controller;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('dd/MM/yyyy').format(
      DateFormat('yyyy-MM-dd').parse(controller.dataContagem),
    );

    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Contagem: $dateLabel',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              FilledButton.icon(
                onPressed: controller.loading ? null : controller.sync,
                icon: controller.loading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync, size: 16),
                label: const Text('Sincronizar'),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _Chip(
                label: '${controller.totalContados}/${controller.totalProdutos}',
                sublabel: 'contados',
                color: Colors.green,
              ),
              const SizedBox(width: 8),
              _Chip(
                label: controller.totalNaoContados.toString(),
                sublabel: 'pendentes',
                color: Colors.grey,
              ),
              const SizedBox(width: 8),
              _Chip(
                label: controller.totalDivergencias.toString(),
                sublabel: 'divergências',
                color: Colors.orange,
              ),
            ],
          ),
          if (controller.error != null) ...[
            const SizedBox(height: 6),
            Text(
              controller.error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.sublabel,
    required this.color,
  });
  final String label;
  final String sublabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            sublabel,
            style: TextStyle(fontSize: 11, color: color),
          ),
        ],
      ),
    );
  }
}

// ── filter bar ─────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.controller});
  final CicloController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Buscar produto ou código',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: controller.updateQuery,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: controller.selectedCategory,
                  isDense: true,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: controller.categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) controller.updateCategory(v);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<FiltroStatus>(
                  value: controller.filtroStatus,
                  isDense: true,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: FiltroStatus.todos,
                      child: Text('Todos'),
                    ),
                    DropdownMenuItem(
                      value: FiltroStatus.naoContados,
                      child: Text('Pendentes'),
                    ),
                    DropdownMenuItem(
                      value: FiltroStatus.contados,
                      child: Text('Contados'),
                    ),
                    DropdownMenuItem(
                      value: FiltroStatus.comDivergencia,
                      child: Text('Divergências'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) controller.updateFiltroStatus(v);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${controller.filteredProdutos.length} produtos exibidos',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

// ── product list ───────────────────────────────────────────────────────────────

class _ProductList extends StatelessWidget {
  const _ProductList({required this.controller});
  final CicloController controller;

  @override
  Widget build(BuildContext context) {
    final items = controller.filteredProdutos;

    if (!controller.configured) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Configure a URL do banco e o token\nnas configurações (ícone de engrenagem).',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (items.isEmpty && !controller.loading) {
      return const Center(child: Text('Nenhum produto encontrado.'));
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 0),
      itemBuilder: (context, index) {
        final produto = items[index];
        return _ProdutoTile(
          produto: produto,
          controller: controller,
        );
      },
    );
  }
}

class _ProdutoTile extends StatelessWidget {
  const _ProdutoTile({required this.produto, required this.controller});
  final ProdutoEstoque produto;
  final CicloController controller;

  @override
  Widget build(BuildContext context) {
    final cicloItem = controller.ciclo[produto.codigo];
    final contado = cicloItem != null;
    final divergencia = cicloItem?.divergencia ?? 0;
    final temDivergencia = contado && divergencia != 0;

    final statusColor = contado
        ? (temDivergencia ? Colors.orange : Colors.green)
        : Colors.grey.shade400;

    final statusIcon = contado
        ? (temDivergencia ? Icons.warning_amber_rounded : Icons.check_circle)
        : Icons.radio_button_unchecked;

    return ListTile(
      leading: Icon(statusIcon, color: statusColor, size: 28),
      title: Text(
        produto.produto,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${produto.codigo}  •  ${produto.categoria}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: contado
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Contado: ${_fmt(cicloItem!.qtdContada ?? 0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Sistema: ${produto.qtdSistema}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                if (temDivergencia)
                  Text(
                    'Dif: ${_fmt(divergencia)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            )
          : Text(
              'Sistema: ${produto.qtdSistema}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
      onTap: controller.saving ? null : () => _openContagem(context, produto),
    );
  }

  String _fmt(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  Future<void> _openContagem(
    BuildContext context,
    ProdutoEstoque produto,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (_) => ContagemDialog(
        produto: produto,
        cicloAtual: controller.ciclo[produto.codigo],
        onSalvar: (qtd, obs) => controller.salvarContagem(
          produto: produto,
          qtdContada: qtd,
          observacao: obs,
        ),
      ),
    );
  }
}
