import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentacion/pantallas/inicio_page.dart';

void main() {
  runApp(const ProviderScope(child: MapaRuidoApp()));
}

class MapaRuidoApp extends StatelessWidget {
  const MapaRuidoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mapa colaborativo de ruido',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const InicioPage(),
    );
  }
}
