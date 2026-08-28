import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentacion/paginas/inventario_home_page.dart';

void main() {
  runApp(const ProviderScope(child: MyAppInventario()));
}

class MyAppInventario extends StatelessWidget {
  const MyAppInventario({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'P3 · Inventario CEET',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.amber,
        useMaterial3: true,
      ),
      home: const InventarioHomePage(),
    );
  }
}
