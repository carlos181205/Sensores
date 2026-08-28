const express = require('express');
const {
  listarPuntos,
  iniciarRonda,
  registrarMarcacion,
  consultarEstadoRonda,
  cerrarRonda,
} = require('../controladores/rondas.controller');

const router = express.Router();

router.get('/puntos', listarPuntos);
router.post('/rondas', iniciarRonda);
router.post('/rondas/:id/marcaciones', registrarMarcacion);
router.post('/marcaciones', registrarMarcacion);
router.get('/rondas/:id', consultarEstadoRonda);
router.patch('/rondas/:id/cerrar', cerrarRonda);

module.exports = router;
