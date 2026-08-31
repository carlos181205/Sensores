import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/pantalla_prueba.dart';

void main() {
  testWidgets('La pantalla de P5 inicia correctamente', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PantallaPrueba()));

    expect(find.text('Mapa colaborativo de ruido'), findsOneWidget);
  });
}
