const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { pool, isPostgresConfigured } = require('../config/db');
const { JWT_SECRET } = require('../middlewares/auth.middleware');

const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'secreto_refresh_seguro_ceet_2026';

const USUARIOS_SEED = [
  {
    id: 1,
    documento: '1010123456',
    nombre: 'Carlos Aprendiz ADSO',
    email: 'carlos.aprendiz@sena.edu.co',
    password: bcrypt.hashSync('123456', 8),
    rol: 'aprendiz',
    ficha_id: 1,
  },
  {
    id: 2,
    documento: '2020987654',
    nombre: 'Ing. Maria Instructora',
    email: 'maria.instructor@sena.edu.co',
    password: bcrypt.hashSync('123456', 8),
    rol: 'instructor',
    ficha_id: 1,
  },
];

const memoriaAuth = {
  usuarios: new Map(USUARIOS_SEED.map((u) => [u.documento, { ...u }])),
  refreshTokens: new Map(),
};

function normalizarUsuario(usuario) {
  if (!usuario) return null;

  return {
    id: usuario.id,
    documento: usuario.documento,
    nombre: usuario.nombre,
    rol: usuario.rol,
    fichaId: usuario.ficha_id || usuario.fichaId || 1,
    sedeId: usuario.sede_id || usuario.sedeId || 1,
  };
}

function generarTokens(usuario) {
  const payload = {
    id: usuario.id,
    documento: usuario.documento,
    nombre: usuario.nombre,
    rol: usuario.rol,
    fichaId: usuario.ficha_id || usuario.fichaId || 1,
    sedeId: usuario.sede_id || usuario.sedeId || 1,
  };

  const accessToken = jwt.sign(payload, JWT_SECRET, { expiresIn: '15m' });
  const refreshToken = jwt.sign({ ...payload, type: 'refresh' }, JWT_REFRESH_SECRET, { expiresIn: '7d' });

  return { accessToken, refreshToken };
}

const login = async (req, res, next) => {
  try {
    const { documento, password } = req.body;
    if (!documento || !password) {
      return res.status(400).json({ ok: false, mensaje: 'Faltan documento y contraseña' });
    }

    let usuario = null;
    if (!isPostgresConfigured || !pool) {
      usuario = memoriaAuth.usuarios.get(documento);
    } else {
      const uRes = await pool.query('SELECT * FROM usuario WHERE documento = $1;', [documento]);
      usuario = uRes.rows[0];
    }

    if (!usuario || !bcrypt.compareSync(password, usuario.password)) {
      return res.status(401).json({ ok: false, mensaje: 'Credenciales inválidas' });
    }

    const usuarioNormalizado = normalizarUsuario(usuario);
    const { accessToken, refreshToken } = generarTokens(usuario);

    if (!isPostgresConfigured || !pool) {
      memoriaAuth.refreshTokens.set(refreshToken, {
        usuarioId: usuario.id,
        expiraEn: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
        revocado: false,
      });
    } else {
      await pool.query(
        `INSERT INTO refresh_token (usuario_id, token, expira_en, revocado)
         VALUES ($1, $2, $3, false);`,
        [usuario.id, refreshToken, new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)]
      );
    }

    return res.status(200).json({
      ok: true,
      mensaje: 'Autenticación exitosa',
      tokens: { accessToken, refreshToken },
      usuario: usuarioNormalizado,
    });
  } catch (error) {
    next(error);
  }
};

const refreshToken = async (req, res, next) => {
  try {
    const { refreshToken: tokenEnviado } = req.body;
    if (!tokenEnviado) {
      return res.status(400).json({ ok: false, mensaje: 'Refresh token no proporcionado' });
    }

    let payload = null;
    try {
      payload = jwt.verify(tokenEnviado, JWT_REFRESH_SECRET);
    } catch (_) {
      return res.status(401).json({ ok: false, mensaje: 'Refresh token inválido o expirado', codigo: 'REFRESH_TOKEN_INVALID' });
    }

    if (payload.type !== 'refresh') {
      return res.status(401).json({ ok: false, mensaje: 'Refresh token no válido para rotación', codigo: 'REFRESH_TOKEN_INVALID' });
    }

    let valido = false;
    const usuarioId = payload.id;

    if (!isPostgresConfigured || !pool) {
      const reg = memoriaAuth.refreshTokens.get(tokenEnviado);
      if (reg && !reg.revocado) {
        valido = true;
        reg.revocado = true;
      }
    } else {
      const tRes = await pool.query(
        'SELECT * FROM refresh_token WHERE token = $1 AND revocado = false;',
        [tokenEnviado]
      );
      if (tRes.rows.length > 0) {
        valido = true;
        await pool.query('UPDATE refresh_token SET revocado = true WHERE token = $1;', [tokenEnviado]);
      }
    }

    if (!valido) {
      return res.status(401).json({ ok: false, mensaje: 'Refresh token revocado o ya utilizado', codigo: 'REFRESH_TOKEN_REVOKED' });
    }

    let usuario = null;
    if (!isPostgresConfigured || !pool) {
      usuario = [...memoriaAuth.usuarios.values()].find((u) => u.id === usuarioId);
    } else {
      const uRes = await pool.query('SELECT * FROM usuario WHERE id = $1;', [usuarioId]);
      usuario = uRes.rows[0];
    }

    if (!usuario) {
      return res.status(404).json({ ok: false, mensaje: 'Usuario no encontrado para renovar sesión' });
    }

    const nuevosTokens = generarTokens(usuario);

    if (!isPostgresConfigured || !pool) {
      memoriaAuth.refreshTokens.set(nuevosTokens.refreshToken, {
        usuarioId,
        expiraEn: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
        revocado: false,
      });
    } else {
      await pool.query(
        `INSERT INTO refresh_token (usuario_id, token, expira_en, revocado)
         VALUES ($1, $2, $3, false);`,
        [usuarioId, nuevosTokens.refreshToken, new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)]
      );
    }

    return res.status(200).json({
      ok: true,
      mensaje: 'Tokens renovados correctamente (rotación transparente)',
      tokens: nuevosTokens,
    });
  } catch (error) {
    next(error);
  }
};

const logout = async (req, res, next) => {
  try {
    const { refreshToken: tokenEnviado } = req.body;

    if (tokenEnviado) {
      if (!isPostgresConfigured || !pool) {
        const reg = memoriaAuth.refreshTokens.get(tokenEnviado);
        if (reg) reg.revocado = true;
      } else {
        await pool.query('UPDATE refresh_token SET revocado = true WHERE token = $1;', [tokenEnviado]);
      }
    }

    return res.status(200).json({ ok: true, mensaje: 'Sesión cerrada correctamente' });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  login,
  refreshToken,
  logout,
  USUARIOS_SEED,
};
