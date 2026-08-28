const express = require('express');
const {
  listarItems,
  sincronizarDelta,
  resolverConflicto,
} = require('../controladores/inventario.controller');

const router = express.Router();

router.get('/items', listarItems);
router.post('/sync', sincronizarDelta);
router.post('/items/resolver-conflicto', resolverConflicto);

module.exports = router;
