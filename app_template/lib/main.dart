import 'package:flutter/material.dart';

import 'services/local_cache_service.dart';
import 'state/ciclo_controller.dart';
import 'ui/ciclo_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final controller = CicloController(cacheService: LocalCacheService());
  await controller.initialize();

  runApp(InventarioCiclicoApp(controller: controller));
}

class InventarioCiclicoApp extends StatelessWidget {
  const InventarioCiclicoApp({super.key, required this.controller});

  final CicloController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Inventário Cíclico CAMDA',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: CicloPage(controller: controller),
    );
  }
}
