const express = require('express');
const {
  registrarDispositivo,
  registrarEvento,
  registrarLoteEventos,
  consultarEventos,
  consultarResumenEventos,
} = require('../controladores/eventos.controller');

const router = express.Router();

router.post('/dispositivos', registrarDispositivo);
router.post('/eventos', registrarEvento);
router.post('/eventos/lote', registrarLoteEventos);
router.get('/eventos', consultarEventos);
router.get('/eventos/resumen', consultarResumenEventos);

module.exports = router;
