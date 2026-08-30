const express = require('express');
const {
  registrarMarcacion,
  consultarMisMarcaciones,
  consultarConsolidadoFicha,
} = require('../controladores/asistencia.controller');
const { autenticarToken, requerirRol } = require('../middlewares/auth.middleware');

const router = express.Router();

router.use(autenticarToken);

router.post('/asistencia/marcacion', registrarMarcacion);
router.get('/asistencia/mias', consultarMisMarcaciones);
router.get('/fichas/:id/consolidado', requerirRol('instructor'), consultarConsolidadoFicha);

module.exports = router;
