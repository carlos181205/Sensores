import 'package:flutter_test/flutter_test.dart';
import 'package:nivel_digital_obra/dominio/entidades/medicion_snapshot.dart';
import 'package:nivel_digital_obra/dominio/servicios/calculadora_azimut.dart';
import 'package:nivel_digital_obra/dominio/servicios/calculadora_inclinacion.dart';
import 'package:nivel_digital_obra/dominio/servicios/filtro_complementario.dart';
import 'package:nivel_digital_obra/dominio/servicios/regla_cumplimiento.dart';

void main() {
  group('FiltroComplementario', () {
    test('usa acelerómetro como primer valor sin salto', () {
      final filtro = FiltroComplementario();
      expect(filtro.actualizar(anguloAcelerometro: 10, velocidadAngular: 8, deltaSegundos: 0.1), 10);
    });
    test('integra velocidad angular y corrige con acelerómetro', () {
      final filtro = FiltroComplementario(peso: 0.5);
      filtro.actualizar(anguloAcelerometro: 0, velocidadAngular: 0, deltaSegundos: 0);
      expect(filtro.actualizar(anguloAcelerometro: 0, velocidadAngular: 10, deltaSegundos: 1), 5);
    });
    test('rechaza dt y datos inválidos', () {
      final filtro = FiltroComplementario();
      expect(() => filtro.actualizar(anguloAcelerometro: 0, velocidadAngular: 0, deltaSegundos: -0.1), throwsArgumentError);
      expect(() => filtro.actualizar(anguloAcelerometro: double.nan, velocidadAngular: 0, deltaSegundos: 0), throwsArgumentError);
    });
  });

  test('calcula inclinación X/Y en reposo', () {
    const calculadora = CalculadoraInclinacion();
    final valor = calculadora.desdeAcelerometro(x: 0, y: 0, z: 9.81);
    expect(valor.x, closeTo(0, 0.0001));
    expect(valor.y, closeTo(0, 0.0001));
  });

  group('CalculadoraAzimut', () {
    const calculadora = CalculadoraAzimut();
    test('normaliza 0 y 360', () => expect(calculadora.normalizar(360), 0));
    test('calcula diferencia circular 1/359', () => expect(calculadora.desviacionCircular(1, 359), 2));
    test('maneja 180 y coincidencia', () {
      expect(calculadora.desviacionCircular(180, 0), 180);
      expect(calculadora.desviacionCircular(20, 20), 0);
    });
  });

  test('aplica la regla de cumplimiento', () {
    const regla = ReglaCumplimiento();
    expect(regla.evaluar(inclinacionX: 1.5, inclinacionY: -1.5, azimut: 1, azimutObjetivo: 359), isTrue);
    expect(regla.evaluar(inclinacionX: 1.6, inclinacionY: 0, azimut: 0, azimutObjetivo: 0), isFalse);
  });

  test('serializa el snapshot sin recalcular valores', () {
    final snapshot = MedicionSnapshot(inclinacionX: 0.1, inclinacionY: -0.2, azimut: 359, azimutObjetivo: 1, desviacionAzimut: -2, latitud: 4.6, longitud: -74.1, cumple: true, medidoEn: DateTime.utc(2026));
    expect(snapshot.toMultipartFields()['desviacionAzimut'], '-2.0');
    expect(snapshot.toMultipartFields()['cumple'], 'true');
  });
}
