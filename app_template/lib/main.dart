import 'package:flutter/material.dart';

import 'services/inventory_api_service.dart';
import 'services/local_cache_service.dart';
import 'state/inventory_controller.dart';
import 'ui/inventory_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final controller = InventoryController(
    apiService: InventoryApiService(),
    cacheService: LocalCacheService(),
  );
  await controller.initialize();

  runApp(InventarioApp(controller: controller));
}

class InventarioApp extends StatelessWidget {
  const InventarioApp({super.key, required this.controller});

  final InventoryController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Inventário CAMDA',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: InventoryPage(controller: controller),
    );
  }
}
