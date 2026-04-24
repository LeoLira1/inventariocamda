import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../state/inventory_controller.dart';

class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key, required this.controller});

  final InventoryController controller;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.decimalPattern('pt_BR');

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Inventário CAMDA'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => _openSourceDialog(context),
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        labelText: 'Buscar por código ou descrição',
                      ),
                      onChanged: controller.updateQuery,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: controller.selectedCategory,
                            items: controller.categories
                                .map(
                                  (category) => DropdownMenuItem(
                                    value: category,
                                    child: Text(category),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) controller.updateCategory(value);
                            },
                            decoration: const InputDecoration(labelText: 'Categoria'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: controller.loading ? null : controller.sync,
                          icon: controller.loading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.sync),
                          label: const Text('Sincronizar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Itens filtrados: ${controller.filteredItems.length} • '
                        'Quantidade total: ${formatter.format(controller.totalQuantidade)}',
                      ),
                    ),
                    if (controller.lastSync != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Última sincronização: '
                          '${DateFormat('dd/MM/yyyy HH:mm').format(controller.lastSync!.toLocal())}',
                        ),
                      ),
                    if (controller.error != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          controller.error!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 0),
              Expanded(
                child: controller.filteredItems.isEmpty
                    ? const Center(
                        child: Text('Nenhum item encontrado. Toque em Sincronizar.'),
                      )
                    : ListView.separated(
                        itemCount: controller.filteredItems.length,
                        separatorBuilder: (_, __) => const Divider(height: 0),
                        itemBuilder: (context, index) {
                          final item = controller.filteredItems[index];
                          return ListTile(
                            title: Text(item.descricao),
                            subtitle: Text('${item.codigo} • ${item.categoria}'),
                            trailing: Text(
                              '${formatter.format(item.quantidade)} ${item.unidade}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openSourceDialog(BuildContext context) async {
    final textController = TextEditingController(text: controller.sourceUrl);
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Fonte de sincronização'),
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(
              labelText: 'URL de origem (JSON ou endpoint)',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                await controller.updateSourceUrl(textController.text.trim());
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }
}
