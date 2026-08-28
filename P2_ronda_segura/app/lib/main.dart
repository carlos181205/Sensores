import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentacion/paginas/estado_ronda_page.dart';

void main() {
  runApp(const ProviderScope(child: MyAppRonda()));
}

class MyAppRonda extends StatelessWidget {
  const MyAppRonda({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'P2 · Ronda Segura',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const EstadoRondaPage(),
    );
  }
}
