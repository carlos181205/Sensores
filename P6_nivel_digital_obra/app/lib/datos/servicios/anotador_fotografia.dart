import 'dart:io';

import 'package:image/image.dart' as image;
import 'package:path_provider/path_provider.dart';

import '../../dominio/entidades/medicion_snapshot.dart';

class AnotadorFotografia {
  const AnotadorFotografia();

  Future<File> anotar({
    required String rutaOriginal,
    required String identificadorVisita,
    required MedicionSnapshot snapshot,
  }) async {
    final bytes = await File(rutaOriginal).readAsBytes();
    final foto = image.decodeImage(bytes);
    if (foto == null) {
      throw const FileSystemException('No se pudo leer la fotografía capturada.');
    }
    final panelAlto = (foto.height * 0.34).round();
    final anotada = image.Image(width: foto.width, height: foto.height + panelAlto);
    image.fill(anotada, color: image.ColorRgb8(16, 24, 32));
    image.compositeImage(anotada, foto, dstX: 0, dstY: 0);
    final lineas = [
      'VISITA: $identificadorVisita',
      'X: ${snapshot.inclinacionX.toStringAsFixed(1)}°  Y: ${snapshot.inclinacionY.toStringAsFixed(1)}°',
      'Azimut: ${snapshot.azimut.toStringAsFixed(1)}°  Objetivo: ${snapshot.azimutObjetivo.toStringAsFixed(1)}°',
      'Desviación: ${snapshot.desviacionAzimut.toStringAsFixed(1)}°',
      'GPS: ${snapshot.latitud?.toStringAsFixed(6) ?? 'sin dato'}, ${snapshot.longitud?.toStringAsFixed(6) ?? 'sin dato'}',
      '${snapshot.medidoEn.toLocal().toIso8601String()}  ${snapshot.cumple ? 'CUMPLE' : 'NO CUMPLE'}',
    ];
    var y = foto.height + 12;
    for (final linea in lineas) {
      image.drawString(
        anotada,
        linea,
        font: image.arial24,
        x: 16,
        y: y,
        color: image.ColorRgb8(255, 255, 255),
      );
      y += 30;
    }
    final directorio = await getTemporaryDirectory();
    final archivo = File('${directorio.path}/medicion_${snapshot.medidoEn.millisecondsSinceEpoch}.jpg');
    await archivo.writeAsBytes(image.encodeJpg(anotada, quality: 92));
    return archivo;
  }
}
