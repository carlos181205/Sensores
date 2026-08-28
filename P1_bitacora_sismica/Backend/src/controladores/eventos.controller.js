const { v4: uuidv4 } = require('uuid');
const { pool, isPostgresConfigured } = require('../config/db');

const memoria = {
  dispositivos: new Map(),
  eventos: [],
};

const severidadPorIntensidad = (valor) => {
  const intensidad = Number(valor ?? 0);
  if (intensidad <= 18) return 'leve';
  if (intensidad <= 35) return 'moderado';
  return 'fuerte';
};

const normalizarDispositivo = (payload = {}) => ({
  dispositivoId: payload.dispositivoId || payload.dispositivo_id || payload.id || uuidv4(),
  nombre: payload.nombre || 'Dispositivo CEET',
  modelo: payload.modelo || 'Sin modelo',
  versionFirmware: payload.versionFirmware || payload.version_firmware || '1.0.0',
});

const normalizarEvento = (payload = {}) => ({
  dispositivoId: payload.dispositivoId || payload.dispositivo_id,
  claveCliente: payload.claveCliente || payload.clave_cliente || uuidv4(),
  intensidad: Number(payload.intensidad ?? 0),
  latitud: Number(payload.latitud ?? 0),
  longitud: Number(payload.longitud ?? 0),
  descripcion: payload.descripcion || 'Impacto registrado',
  fechaEvento: payload.fechaEvento || payload.fecha_evento || new Date().toISOString(),
});

const registrarDispositivo = async (req, res, next) => {
  try {
    const data = normalizarDispositivo(req.body);

    if (!isPostgresConfigured || !pool) {
      const key = data.dispositivoId;
      memoria.dispositivos.set(key, {
        ...data,
        fechaRegistro: new Date().toISOString(),
      });

      return res.status(201).json({
        ok: true,
        mensaje: 'Dispositivo registrado localmente',
        dispositivo: memoria.dispositivos.get(key),
      });
    }

    const result = await pool.query(
      `INSERT INTO dispositivo (dispositivo_id, nombre, modelo, version_firmware)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (dispositivo_id)
       DO UPDATE SET nombre = EXCLUDED.nombre, modelo = EXCLUDED.modelo, version_firmware = EXCLUDED.version_firmware
       RETURNING *;`,
      [data.dispositivoId, data.nombre, data.modelo, data.versionFirmware]
    );

    return res.status(201).json({
      ok: true,
      mensaje: 'Dispositivo registrado correctamente',
      dispositivo: result.rows[0],
    });
  } catch (error) {
    next(error);
  }
};

const registrarEvento = async (req, res, next) => {
  try {
    const data = normalizarEvento(req.body);

    if (!data.dispositivoId || !data.claveCliente) {
      return res.status(400).json({
        ok: false,
        mensaje: 'Faltan dispositivoId o claveCliente',
      });
    }

    if (!isPostgresConfigured || !pool) {
      const existe = memoria.eventos.find(
        (item) => item.dispositivoId === data.dispositivoId && item.claveCliente === data.claveCliente
      );

      const evento = {
        id: existe?.id || uuidv4(),
        ...data,
        severidad: severidadPorIntensidad(data.intensidad),
        fechaEvento: data.fechaEvento,
      };

      if (existe) {
        Object.assign(existe, evento);
      } else {
        memoria.eventos.push(evento);
      }

      return res.status(200).json({
        ok: true,
        mensaje: 'Evento registrado en modo local',
        evento,
        idempotente: true,
      });
    }

    const existeDispositivo = await pool.query(
      'SELECT id FROM dispositivo WHERE dispositivo_id = $1;',
      [data.dispositivoId]
    );

    if (existeDispositivo.rowCount === 0) {
      await pool.query(
        `INSERT INTO dispositivo (dispositivo_id, nombre, modelo, version_firmware)
         VALUES ($1, $2, $3, $4)
         ON CONFLICT (dispositivo_id) DO NOTHING;`,
        [data.dispositivoId, 'Dispositivo CEET', 'Sin modelo', '1.0.0']
      );
    }

    const result = await pool.query(
      `INSERT INTO evento_impacto (
        dispositivo_id,
        clave_cliente,
        intensidad,
        latitud,
        longitud,
        descripcion,
        fecha_evento
      ) VALUES ($1, $2, $3, $4, $5, $6, $7)
      ON CONFLICT (dispositivo_id, clave_cliente)
      DO UPDATE SET
        intensidad = EXCLUDED.intensidad,
        latitud = EXCLUDED.latitud,
        longitud = EXCLUDED.longitud,
        descripcion = EXCLUDED.descripcion,
        fecha_evento = EXCLUDED.fecha_evento
      RETURNING *;`,
      [
        data.dispositivoId,
        data.claveCliente,
        data.intensidad,
        data.latitud,
        data.longitud,
        data.descripcion,
        data.fechaEvento,
      ]
    );

    return res.status(201).json({
      ok: true,
      mensaje: 'Evento registrado correctamente',
      evento: {
        ...result.rows[0],
        severidad: severidadPorIntensidad(result.rows[0].intensidad),
      },
      idempotente: true,
    });
  } catch (error) {
    next(error);
  }
};

const registrarLoteEventos = async (req, res, next) => {
  try {
    const lote = Array.isArray(req.body) ? req.body : req.body?.eventos || [];

    if (!lote.length) {
      return res.status(400).json({
        ok: false,
        mensaje: 'No se recibieron eventos para sincronizar',
      });
    }

    const resultados = [];

    for (const item of lote) {
      const evento = normalizarEvento(item);
      const respuesta = await registrarEvento({ body: evento }, {
        status: () => ({ json: (payload) => payload }),
        json: (payload) => payload,
      }, next);
      resultados.push(respuesta || evento);
    }

    return res.status(200).json({
      ok: true,
      mensaje: 'Lote sincronizado',
      total: resultados.length,
      resultados,
    });
  } catch (error) {
    next(error);
  }
};

const consultarEventos = async (req, res, next) => {
  try {
    const {
      dispositivoId,
      desde,
      hasta,
      severidad,
      pagina = '1',
      limite = '20',
    } = req.query;

    const pageNumber = Number(pagina) || 1;
    const pageSize = Math.min(Number(limite) || 20, 100);
    const offset = (pageNumber - 1) * pageSize;

    if (!isPostgresConfigured || !pool) {
      let eventos = [...memoria.eventos];

      if (dispositivoId) {
        eventos = eventos.filter((item) => item.dispositivoId === dispositivoId);
      }
      if (desde) {
        eventos = eventos.filter((item) => new Date(item.fechaEvento) >= new Date(desde));
      }
      if (hasta) {
        eventos = eventos.filter((item) => new Date(item.fechaEvento) <= new Date(hasta));
      }
      if (severidad) {
        eventos = eventos.filter((item) => severidadPorIntensidad(item.intensidad) === String(severidad).toLowerCase());
      }

      const total = eventos.length;
      const paginados = eventos.slice(offset, offset + pageSize);

      return res.status(200).json({
        ok: true,
        total,
        pagina: pageNumber,
        limite: pageSize,
        eventos: paginados,
      });
    }

    const conditions = [];
    const values = [];
    let index = 1;

    if (dispositivoId) {
      conditions.push(`dispositivo_id = $${index}`);
      values.push(dispositivoId);
      index += 1;
    }

    if (desde) {
      conditions.push(`fecha_evento >= $${index}`);
      values.push(new Date(desde).toISOString());
      index += 1;
    }

    if (hasta) {
      conditions.push(`fecha_evento <= $${index}`);
      values.push(new Date(hasta).toISOString());
      index += 1;
    }

    if (severidad) {
      conditions.push(`CASE WHEN intensidad <= 18 THEN 'leve' WHEN intensidad <= 35 THEN 'moderado' ELSE 'fuerte' END = $${index}`);
      values.push(String(severidad).toLowerCase());
      index += 1;
    }

    const whereClause = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
    const countResult = await pool.query(`SELECT COUNT(*)::int AS total FROM evento_impacto ${whereClause};`, values);
    const query = `SELECT * FROM evento_impacto ${whereClause} ORDER BY fecha_evento DESC LIMIT $${index} OFFSET $${index + 1};`;
    const result = await pool.query(query, [...values, pageSize, offset]);

    return res.status(200).json({
      ok: true,
      total: countResult.rows[0].total,
      pagina: pageNumber,
      limite: pageSize,
      eventos: result.rows.map((evento) => ({
        ...evento,
        severidad: severidadPorIntensidad(evento.intensidad),
      })),
    });
  } catch (error) {
    next(error);
  }
};

const consultarResumenEventos = async (req, res, next) => {
  try {
    const { desde, hasta, severidad } = req.query;

    if (!isPostgresConfigured || !pool) {
      const eventos = [...memoria.eventos].filter((item) => {
        if (desde && new Date(item.fechaEvento) < new Date(desde)) return false;
        if (hasta && new Date(item.fechaEvento) > new Date(hasta)) return false;
        if (severidad && severidadPorIntensidad(item.intensidad) !== String(severidad).toLowerCase()) return false;
        return true;
      });

      const resumen = {
        leve: eventos.filter((item) => severidadPorIntensidad(item.intensidad) === 'leve').length,
        moderado: eventos.filter((item) => severidadPorIntensidad(item.intensidad) === 'moderado').length,
        fuerte: eventos.filter((item) => severidadPorIntensidad(item.intensidad) === 'fuerte').length,
      };

      return res.status(200).json({
        ok: true,
        total: eventos.length,
        resumen,
      });
    }

    const conditions = [];
    const values = [];
    let index = 1;

    if (desde) {
      conditions.push(`fecha_evento >= $${index}`);
      values.push(new Date(desde).toISOString());
      index += 1;
    }

    if (hasta) {
      conditions.push(`fecha_evento <= $${index}`);
      values.push(new Date(hasta).toISOString());
      index += 1;
    }

    if (severidad) {
      conditions.push(`CASE WHEN intensidad <= 18 THEN 'leve' WHEN intensidad <= 35 THEN 'moderado' ELSE 'fuerte' END = $${index}`);
      values.push(String(severidad).toLowerCase());
      index += 1;
    }

    const whereClause = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
    const query = `
      SELECT
        SUM(CASE WHEN intensidad <= 18 THEN 1 ELSE 0 END) AS leve,
        SUM(CASE WHEN intensidad > 18 AND intensidad <= 35 THEN 1 ELSE 0 END) AS moderado,
        SUM(CASE WHEN intensidad > 35 THEN 1 ELSE 0 END) AS fuerte
      FROM evento_impacto
      ${whereClause};
    `;

    const result = await pool.query(query, values);
    const row = result.rows[0];
    const resumen = {
      leve: Number(row.leve || 0),
      moderado: Number(row.moderado || 0),
      fuerte: Number(row.fuerte || 0),
    };

    return res.status(200).json({
      ok: true,
      total: Object.values(resumen).reduce((acc, val) => acc + val, 0),
      resumen,
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  registrarDispositivo,
  registrarEvento,
  registrarLoteEventos,
  consultarEventos,
  consultarResumenEventos,
};
