const { v4: uuidv4 } = require('uuid');
const { pool, isPostgresConfigured } = require('../config/db');

const CENTRO_SENA_CEET = {
  lat: 4.6581,
  lon: -74.0935,
  radioM: 500,
  toleranciaM: 30,
  horaInicio: '06:00',
  horaFin: '22:00',
};

function distanciaMetros(lat1, lon1, lat2, lon2) {
  const R = 6371000;
  const rad = (g) => (g * Math.PI) / 180;
  const dLat = rad(lat2 - lat1);
  const dLon = rad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(rad(lat1)) * Math.cos(rad(lat2)) * Math.sin(dLon / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function convertirHoraAMinutos(hora) {
  const [h, m] = String(hora).split(':').map(Number);
  return (Number.isFinite(h) ? h : 0) * 60 + (Number.isFinite(m) ? m : 0);
}

function esDentroHorario(timestamp, horaInicio = CENTRO_SENA_CEET.horaInicio, horaFin = CENTRO_SENA_CEET.horaFin) {
  const fecha = new Date(timestamp);
  if (Number.isNaN(fecha.getTime())) {
    return false;
  }

  const minutoActual = fecha.getHours() * 60 + fecha.getMinutes();
  const inicio = convertirHoraAMinutos(horaInicio);
  const fin = convertirHoraAMinutos(horaFin);

  if (inicio <= fin) {
    return minutoActual >= inicio && minutoActual <= fin;
  }

  return minutoActual >= inicio || minutoActual <= fin;
}

function normalizarTipo(tipo) {
  const valor = String(tipo || '').toUpperCase();
  return ['ENTRADA', 'SALIDA'].includes(valor) ? valor : 'ENTRADA';
}

const memoriaAsistencia = {
  marcaciones: [],
};

const registrarMarcacion = async (req, res, next) => {
  try {
    const usuarioId = req.usuario.id;
    const sedeId = Number(req.usuario.sedeId || req.usuario.fichaId || 1);
    const { tipo, latitud, longitud, precisionM, timestamp } = req.body;

    if (!tipo || latitud == null || longitud == null) {
      return res.status(400).json({ ok: false, mensaje: 'Faltan tipo, latitud o longitud' });
    }

    const fechaMarcacion = new Date(timestamp || Date.now());
    if (Number.isNaN(fechaMarcacion.getTime())) {
      return res.status(400).json({ ok: false, mensaje: 'El timestamp enviado no es válido' });
    }

    const lat = Number(latitud);
    const lon = Number(longitud);
    const precision = Number(precisionM || 0);
    const distancia = distanciaMetros(lat, lon, CENTRO_SENA_CEET.lat, CENTRO_SENA_CEET.lon);
    const toleranciaAplicada = Math.min(precision, CENTRO_SENA_CEET.toleranciaM);
    const dentroPerimetro = distancia <= (CENTRO_SENA_CEET.radioM + toleranciaAplicada);
    const dentroHorario = esDentroHorario(fechaMarcacion.toISOString());

    const result = {
      id: uuidv4(),
      usuarioId,
      sedeId,
      tipo: normalizarTipo(tipo),
      latitud: lat,
      longitud: lon,
      precisionM: precision,
      distanciaM: Number(distancia.toFixed(2)),
      dentroPerimetro,
      dentroHorario,
      estado: dentroPerimetro && dentroHorario ? 'ACEPTADA' : 'RECHAZADA',
      motivoRechazo: null,
      registradoEn: fechaMarcacion.toISOString(),
    };

    if (!dentroPerimetro || !dentroHorario) {
      result.motivoRechazo = !dentroPerimetro
        ? `Fuera del perímetro del centro SENA (${Math.round(distancia)} m)`
        : 'Fuera de la franja horaria permitida';

      return res.status(422).json({
        ok: false,
        codigo: !dentroPerimetro ? 'GEOCERCA_RECHAZADA' : 'HORARIO_RECHAZADO',
        mensaje: `Marcación rechazada por regla de negocio: ${result.motivoRechazo}`,
        asistencia: result,
      });
    }

    if (!isPostgresConfigured || !pool) {
      memoriaAsistencia.marcaciones.push(result);
    } else {
      await pool.query(
        `INSERT INTO marcacion_asistencia (
          id, usuario_id, ficha_id, tipo, latitud, longitud, precision_m, distancia_m, dentro_perimetro, dentro_horario, registrada_en
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11);`,
        [
          result.id,
          result.usuarioId,
          result.sedeId,
          result.tipo,
          result.latitud,
          result.longitud,
          result.precisionM,
          result.distanciaM,
          result.dentroPerimetro,
          result.dentroHorario,
          result.registradoEn,
        ]
      );
    }

    return res.status(201).json({
      ok: true,
      mensaje: 'Marcación de asistencia registrada exitosamente',
      asistencia: result,
    });
  } catch (error) {
    next(error);
  }
};

const consultarMisMarcaciones = async (req, res, next) => {
  try {
    const usuarioId = req.usuario.id;

    if (!isPostgresConfigured || !pool) {
      const misMarcaciones = memoriaAsistencia.marcaciones.filter((m) => m.usuarioId === usuarioId);
      return res.status(200).json({ ok: true, total: misMarcaciones.length, marcaciones: misMarcaciones });
    }

    const result = await pool.query(
      'SELECT * FROM marcacion_asistencia WHERE usuario_id = $1 ORDER BY registrada_en DESC;',
      [usuarioId]
    );

    return res.status(200).json({ ok: true, total: result.rows.length, marcaciones: result.rows });
  } catch (error) {
    next(error);
  }
};

const consultarConsolidadoFicha = async (req, res, next) => {
  try {
    const fichaId = Number(req.params.id || req.usuario.fichaId || 1);

    if (!isPostgresConfigured || !pool) {
      const consolidadas = memoriaAsistencia.marcaciones.filter((m) => m.sedeId === fichaId);
      return res.status(200).json({
        ok: true,
        fichaId,
        totalMarcaciones: consolidadas.length,
        consolidado: consolidadas,
      });
    }

    const result = await pool.query(
      `SELECT m.*, u.nombre AS usuario_nombre, u.documento
       FROM marcacion_asistencia m
       JOIN usuario u ON u.id = m.usuario_id
       WHERE m.ficha_id = $1 ORDER BY m.registrada_en DESC;`,
      [fichaId]
    );

    return res.status(200).json({
      ok: true,
      fichaId,
      totalMarcaciones: result.rows.length,
      consolidado: result.rows,
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  registrarMarcacion,
  consultarMisMarcaciones,
  consultarConsolidadoFicha,
};
