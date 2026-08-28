const { v4: uuidv4 } = require('uuid');
const { pool, isPostgresConfigured } = require('../config/db');
const { evaluarGeocerca } = require('../servicios/geocerca');

// Puntos de control por defecto del centro CEET (Sensores y laboratorios)
const PUNTOS_DEFAULT = [
  { id: 1, codigo: 'PUNTO-01', nombre: 'Entrada Principal CEET', latitud: 4.6581, longitud: -74.0935, radio_m: 40, orden: 1 },
  { id: 2, codigo: 'PUNTO-02', nombre: 'Laboratorio de Telecomunicaciones', latitud: 4.6585, longitud: -74.0932, radio_m: 35, orden: 2 },
  { id: 3, codigo: 'PUNTO-03', nombre: 'Ambiente de Software ADSO', latitud: 4.6589, longitud: -74.0928, radio_m: 40, orden: 3 },
  { id: 4, codigo: 'PUNTO-04', nombre: 'Almacén de Electrónica', latitud: 4.6592, longitud: -74.0925, radio_m: 30, orden: 4 },
];

const memoria = {
  puntos: [...PUNTOS_DEFAULT],
  rondas: new Map(),
  marcaciones: [],
};

const listarPuntos = async (req, res, next) => {
  try {
    if (!isPostgresConfigured || !pool) {
      return res.status(200).json({ ok: true, puntos: memoria.puntos });
    }
    const result = await pool.query('SELECT * FROM punto_control ORDER BY orden ASC;');
    if (result.rows.length === 0) {
      // Auto seed if empty
      for (const p of PUNTOS_DEFAULT) {
        await pool.query(
          `INSERT INTO punto_control (codigo, nombre, latitud, longitud, radio_m, orden)
           VALUES ($1, $2, $3, $4, $5, $6) ON CONFLICT (codigo) DO NOTHING;`,
          [p.codigo, p.nombre, p.latitud, p.longitud, p.radio_m, p.orden]
        );
      }
      const seeded = await pool.query('SELECT * FROM punto_control ORDER BY orden ASC;');
      return res.status(200).json({ ok: true, puntos: seeded.rows });
    }
    return res.status(200).json({ ok: true, puntos: result.rows });
  } catch (error) {
    next(error);
  }
};

const iniciarRonda = async (req, res, next) => {
  try {
    const usuarioId = Number(req.body.usuarioId || req.body.usuario_id || 1);
    const id = uuidv4();
    const iniciaEn = new Date();
    const venceEn = new Date(Date.now() + 45 * 60 * 1000); // 45 minutos de ventana

    if (!isPostgresConfigured || !pool) {
      const ronda = { id, usuario_id: usuarioId, inicia_en: iniciaEn.toISOString(), vence_en: venceEn.toISOString(), estado: 'en_curso' };
      memoria.rondas.set(id, ronda);
      return res.status(201).json({ ok: true, mensaje: 'Ronda iniciada (Modo Local)', ronda });
    }

    const result = await pool.query(
      `INSERT INTO ronda (id, usuario_id, inicia_en, vence_en, estado)
       VALUES ($1, $2, $3, $4, 'en_curso') RETURNING *;`,
      [id, usuarioId, iniciaEn, venceEn]
    );

    return res.status(201).json({ ok: true, mensaje: 'Ronda iniciada correctamente', ronda: result.rows[0] });
  } catch (error) {
    next(error);
  }
};

const registrarMarcacion = async (req, res, next) => {
  try {
    const { rondaId, codigo, latitud, longitud, precisionM, escaneadaEn } = req.body;
    const rId = rondaId || req.params.id;

    if (!rId || !codigo || latitud == null || longitud == null) {
      return res.status(400).json({ ok: false, mensaje: 'Faltan datos obligatorios para la marcación' });
    }

    // 1. Buscar punto por código QR
    let punto = null;
    if (!isPostgresConfigured || !pool) {
      punto = memoria.puntos.find((p) => p.codigo === codigo);
    } else {
      const pRes = await pool.query('SELECT * FROM punto_control WHERE codigo = $1;', [codigo]);
      punto = pRes.rows[0];
    }

    if (!punto) {
      return res.status(404).json({ ok: false, mensaje: `Punto de control no reconocido: ${codigo}` });
    }

    // 2. Validación de geocerca en el servidor con fórmula Haversine
    const evaluacion = evaluarGeocerca({
      latitud: Number(latitud),
      longitud: Number(longitud),
      precisionM: Number(precisionM || 0),
      puntoLat: Number(punto.latitud),
      puntoLon: Number(punto.longitud),
      radioM: Number(punto.radio_m || 40),
    });

    const marcacionData = {
      id: uuidv4(),
      rondaId: rId,
      puntoId: punto.id,
      latitud: Number(latitud),
      longitud: Number(longitud),
      precisionM: Number(precisionM || 0),
      distanciaM: evaluacion.distancia,
      aceptada: evaluacion.aceptada,
      motivoRechazo: evaluacion.motivoRechazo,
      escaneadaEn: escaneadaEn || new Date().toISOString(),
    };

    if (!isPostgresConfigured || !pool) {
      memoria.marcaciones.push(marcacionData);
      const statusCode = evaluacion.aceptada ? 201 : 422;
      return res.status(statusCode).json({
        ok: evaluacion.aceptada,
        mensaje: evaluacion.aceptada ? 'Marcación aceptada' : 'Marcación rechazada por geocerca',
        marcacion: marcacionData,
      });
    }

    const result = await pool.query(
      `INSERT INTO marcacion (
        id, ronda_id, punto_id, latitud, longitud, precision_m, distancia_m, aceptada, motivo_rechazo, escaneada_en
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
      ON CONFLICT (ronda_id, punto_id)
      DO UPDATE SET
        latitud = EXCLUDED.latitud,
        longitud = EXCLUDED.longitud,
        precision_m = EXCLUDED.precision_m,
        distancia_m = EXCLUDED.distancia_m,
        aceptada = EXCLUDED.aceptada,
        motivo_rechazo = EXCLUDED.motivo_rechazo,
        escaneada_en = EXCLUDED.escaneada_en
      RETURNING *;`,
      [
        marcacionData.id,
        marcacionData.rondaId,
        marcacionData.puntoId,
        marcacionData.latitud,
        marcacionData.longitud,
        marcacionData.precisionM,
        marcacionData.distanciaM,
        marcacionData.aceptada,
        marcacionData.motivoRechazo,
        marcacionData.escaneadaEn,
      ]
    );

    const statusCode = evaluacion.aceptada ? 201 : 422;
    return res.status(statusCode).json({
      ok: evaluacion.aceptada,
      mensaje: evaluacion.aceptada ? 'Marcación aceptada por el servidor' : 'Marcación rechazada por geocerca',
      marcacion: result.rows[0],
    });
  } catch (error) {
    next(error);
  }
};

const consultarEstadoRonda = async (req, res, next) => {
  try {
    const rondaId = req.params.id;

    let puntos = [];
    let marcaciones = [];

    if (!isPostgresConfigured || !pool) {
      puntos = memoria.puntos;
      marcaciones = memoria.marcaciones.filter((m) => m.rondaId === rondaId);
    } else {
      const pRes = await pool.query('SELECT * FROM punto_control ORDER BY orden ASC;');
      puntos = pRes.rows;
      const mRes = await pool.query('SELECT * FROM marcacion WHERE ronda_id = $1;', [rondaId]);
      marcaciones = mRes.rows;
    }

    const visitadosIds = new Set(marcaciones.filter((m) => m.aceptada).map((m) => m.punto_id || m.puntoId));
    const avance = {
      totalPuntos: puntos.length,
      puntosVisitados: visitadosIds.size,
      puntosPendientes: puntos.length - visitadosIds.size,
      completada: visitadosIds.size === puntos.length,
    };

    return res.status(200).json({ ok: true, avance, puntos, marcaciones });
  } catch (error) {
    next(error);
  }
};

const cerrarRonda = async (req, res, next) => {
  try {
    const rondaId = req.params.id;
    if (!isPostgresConfigured || !pool) {
      const ronda = memoria.rondas.get(rondaId);
      if (ronda) ronda.estado = 'finalizada';
      return res.status(200).json({ ok: true, mensaje: 'Ronda cerrada' });
    }
    await pool.query("UPDATE ronda SET estado = 'finalizada' WHERE id = $1;", [rondaId]);
    return res.status(200).json({ ok: true, mensaje: 'Ronda cerrada correctamente' });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  listarPuntos,
  iniciarRonda,
  registrarMarcacion,
  consultarEstadoRonda,
  cerrarRonda,
};
