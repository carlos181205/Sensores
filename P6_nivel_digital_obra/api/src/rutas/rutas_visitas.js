const { Router } = require('express');

function crearRutasVisitas(controlador, subidaFoto) {
  const rutas = Router();
  rutas.post('/', controlador.crear);
  rutas.get('/', controlador.listar);
  rutas.get('/:id', controlador.obtener);
  rutas.post('/:id/mediciones', subidaFoto, controlador.crearMedicion);
  rutas.get('/:id/mediciones', controlador.listarMediciones);
  rutas.get('/:id/reporte', controlador.reporte);
  return rutas;
}

module.exports = { crearRutasVisitas };
