const express = require('express');

const { getSalud } = require('../controllers/salud.controller');
const eventosRoutes = require('../rutas/eventos');

const router = express.Router();

router.get('/salud', getSalud);
router.use('/', eventosRoutes);

module.exports = router;
