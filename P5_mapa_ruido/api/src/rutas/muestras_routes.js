const express = require('express');

const {
  guardarMuestras,
  listarMuestras,
  consultarMapa,
} = require('../controladores/muestras_controller');

const router = express.Router();

router.post('/muestras', guardarMuestras);

router.get('/muestras', listarMuestras);

router.get('/mapa', consultarMapa);

module.exports = router;
