import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentacion/pantallas/inicio_pantalla.dart';

void main() => runApp(const ProviderScope(child: AplicacionNivelDigital()));

class AplicacionNivelDigital extends StatelessWidget {
  const AplicacionNivelDigital({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Nivel digital de obra',
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey)),
        home: const InicioPantalla(),
      );
}
