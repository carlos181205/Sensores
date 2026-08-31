import 'muestra_ruido.dart';

class LoteMuestras {
  static const int capacidad = 20;

  final List<MuestraRuido> _muestras = [];

  List<MuestraRuido> get muestras => List.unmodifiable(_muestras);

  int get cantidad => _muestras.length;

  bool get estaCompleto => _muestras.length >= capacidad;

  void agregar(MuestraRuido muestra) {
    if (estaCompleto) {
      return;
    }

    _muestras.add(muestra);
  }

  List<MuestraRuido> extraer() {
    final lote = List<MuestraRuido>.from(_muestras);

    _muestras.clear();

    return lote;
  }

  void limpiar() {
    _muestras.clear();
  }
}
