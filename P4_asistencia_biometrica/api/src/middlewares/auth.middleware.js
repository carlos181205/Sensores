const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'secreto_super_seguro_ceet_2026';

function autenticarToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ ok: false, mensaje: 'Token de acceso no proporcionado (401)' });
  }

  try {
    const usuario = jwt.verify(token, JWT_SECRET);
    req.usuario = usuario;
    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ ok: false, mensaje: 'Access Token expirado', codigo: 'TOKEN_EXPIRED' });
    }
    return res.status(403).json({ ok: false, mensaje: 'Token de acceso inválido' });
  }
}

function requerirRol(...rolesPermitidos) {
  return (req, res, next) => {
    if (!req.usuario || !rolesPermitidos.includes(req.usuario.rol)) {
      return res.status(403).json({
        ok: false,
        mensaje: `Acceso prohibido (403): Se requiere rol ${rolesPermitidos.join(' o ')}`,
      });
    }
    next();
  };
}

module.exports = {
  JWT_SECRET,
  autenticarToken,
  requerirRol,
};
