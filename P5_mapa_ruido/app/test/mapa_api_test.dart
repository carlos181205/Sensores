import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/datos/fuentes/mapa_ruido_api.dart';

class RespuestaFalsaAdapter implements HttpClientAdapter {
  RespuestaFalsaAdapter(this.respuesta);

  final Object respuesta;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(respuesta),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('MapaRuidoApi procesa una respuesta agregada', () async {
    final dio = Dio()
      ..httpClientAdapter = RespuestaFalsaAdapter({
        'ok': true,
        'datos': [
          {
            'celdaLat': 4.610,
            'celdaLon': -74.082,
            'promedioDb': 61.4,
            'maximoDb': 73.2,
            'muestras': 23,
          },
        ],
      });

    final celdas = await MapaRuidoApi(dio: dio).obtenerCeldas();

    expect(celdas, hasLength(1));
    expect(celdas.single.muestras, 23);
  });

  test('MapaRuidoApi rechaza una respuesta con contrato inválido', () {
    final dio = Dio()
      ..httpClientAdapter = RespuestaFalsaAdapter({
        'ok': true,
        'datos': {'no': 'es una lista'},
      });

    expect(
      MapaRuidoApi(dio: dio).obtenerCeldas(),
      throwsA(isA<FormatException>()),
    );
  });
}
