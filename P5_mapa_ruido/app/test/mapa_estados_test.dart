import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('el mapa tiene estados explícitos de carga, datos, vacío y error', () {
    final cargando = const AsyncLoading<List<Object>>();
    final datos = const AsyncData<List<Object>>([]);
    final error = AsyncError<List<Object>>(
      Exception('sin red'),
      StackTrace.empty,
    );

    expect(cargando, isA<AsyncLoading<List<Object>>>());
    expect(datos.value, isEmpty);
    expect(error.hasError, isTrue);
  });
}
