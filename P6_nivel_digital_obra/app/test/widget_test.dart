import 'package:flutter_test/flutter_test.dart';
import 'package:nivel_digital_obra/main.dart';

void main() {
  testWidgets('muestra la pantalla de inicio', (tester) async {
    await tester.pumpWidget(const AplicacionNivelDigital());

    expect(find.text('Nivel digital de obra'), findsOneWidget);
    expect(find.text('Nueva visita'), findsOneWidget);
  });
}
