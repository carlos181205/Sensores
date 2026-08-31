import '../../core/constantes/configuracion.dart';
import 'calculadora_azimut.dart';

class ReglaCumplimiento {
  const ReglaCumplimiento({
    this.maxInclinacion = ConfiguracionApp.maxInclinacionPermitida,
    this.maxDesviacionAzimut = ConfiguracionApp.maxDesviacionAzimutPermitida,
    this.calculadoraAzimut = const CalculadoraAzimut(),
  });

  final double maxInclinacion;
  final double maxDesviacionAzimut;
  final CalculadoraAzimut calculadoraAzimut;

  bool evaluar({
    required double inclinacionX,
    required double inclinacionY,
    required double azimut,
    required double azimutObjetivo,
  }) =>
      inclinacionX.abs() <= maxInclinacion &&
      inclinacionY.abs() <= maxInclinacion &&
      calculadoraAzimut.desviacionCircular(azimut, azimutObjetivo).abs() <=
          maxDesviacionAzimut;
}
