const { normalizarAzimut } = require('../utilidades/azimut');

function numeroRequerido(valor, campo) {
  if (valor === undefined || valor === null || valor === '' || !Number.isFinite(Number(valor))) {
    throw new Error(`${campo} debe ser un número válido.`);
  }
  return Number(valor);
}

function validarVisita(cuerpo) {
  const identificador = String(cuerpo.identificador || '').trim();
  if (!identificador) throw new Error('identificador es obligatorio.');
  const azimutObjetivo = numeroRequerido(cuerpo.azimutObjetivo, 'azimutObjetivo');
  if (azimutObjetivo < 0 || azimutObjetivo >= 360) throw new Error('azimutObjetivo debe estar entre 0 y menor que 360.');
  return { identificador, azimutObjetivo: normalizarAzimut(azimutObjetivo) };
}

function validarMedicion(cuerpo, archivo) {
  if (!archivo) throw new Error('foto es obligatoria.');
  const inclinacionX = numeroRequerido(cuerpo.inclinacionX, 'inclinacionX');
  const inclinacionY = numeroRequerido(cuerpo.inclinacionY, 'inclinacionY');
  const azimut = normalizarAzimut(numeroRequerido(cuerpo.azimut, 'azimut'));
  const azimutObjetivo = normalizarAzimut(numeroRequerido(cuerpo.azimutObjetivo, 'azimutObjetivo'));
  const medidoEn = new Date(cuerpo.medidoEn);
  if (Number.isNaN(medidoEn.valueOf())) throw new Error('medidoEn debe ser una fecha ISO válida.');
  const latitud = cuerpo.latitud === '' || cuerpo.latitud === undefined ? null : numeroRequerido(cuerpo.latitud, 'latitud');
  const longitud = cuerpo.longitud === '' || cuerpo.longitud === undefined ? null : numeroRequerido(cuerpo.longitud, 'longitud');
  if (latitud !== null && (latitud < -90 || latitud > 90)) throw new Error('latitud está fuera de rango.');
  if (longitud !== null && (longitud < -180 || longitud > 180)) throw new Error('longitud está fuera de rango.');
  return { inclinacionX, inclinacionY, azimut, azimutObjetivo, latitud, longitud, medidoEn };
}

module.exports = { validarVisita, validarMedicion };
