import 'package:flutter_test/flutter_test.dart';

import 'package:app/datos/modelos/celda_ruido.dart';
import 'package:app/datos/modelos/lote_muestras.dart';
import 'package:app/datos/modelos/muestra_ruido.dart';
import 'package:app/dominio/servicios/nivel_ruido_service.dart';

MuestraRuido muestraDePrueba([int indice = 0]) {
  return MuestraRuido(
    nivelDb: 60.0 + indice,
    latitud: 4.61,
    longitud: -74.08,
    precisionM: 8,
    medidoEn: DateTime.utc(2026, 8, 30, 18, 30),
  );
}

void main() {
  test('MuestraRuido serializa y deserializa su contrato', () {
    final original = muestraDePrueba();
    final json = original.toJson();
    final reconstruida = MuestraRuido.fromJson(json);

    expect(json['nivelDb'], 60.0);
    expect(json['latitud'], 4.61);
    expect(json['longitud'], -74.08);
    expect(json['precisionM'], 8.0);
    expect(reconstruida.medidoEn, original.medidoEn);
  });

  test('LoteMuestras conserva como máximo 20 y extrae el lote', () {
    final lote = LoteMuestras();
    for (var indice = 0; indice < 21; indice++) {
      lote.agregar(muestraDePrueba(indice));
    }

    expect(lote.cantidad, LoteMuestras.capacidad);
    expect(lote.estaCompleto, isTrue);
    expect(lote.extraer(), hasLength(20));
    expect(lote.cantidad, 0);
  });

  test('NivelRuidoService limita la escala relativa de 0 a 100', () {
    final servicio = NivelRuidoService();

    expect(servicio.convertir(-120), 0);
    expect(servicio.convertir(-40), 60);
    expect(servicio.convertir(10), 100);
  });

  test('CeldaRuido.fromJson convierte los tipos numéricos', () {
    final celda = CeldaRuido.fromJson({
      'celdaLat': 4.610,
      'celdaLon': -74.082,
      'promedioDb': 61.4,
      'maximoDb': 73.2,
      'muestras': 23,
    });

    expect(celda.celdaLat, 4.61);
    expect(celda.celdaLon, -74.082);
    expect(celda.promedioDb, 61.4);
    expect(celda.maximoDb, 73.2);
    expect(celda.muestras, 23);
  });
}
