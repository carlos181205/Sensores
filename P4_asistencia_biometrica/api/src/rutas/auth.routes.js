const express = require('express');
const { login, refreshToken, logout } = require('../controladores/auth.controller');

const router = express.Router();

router.post('/login', login);
router.post('/refresh', refreshToken);
router.post('/logout', logout);

module.exports = router;
