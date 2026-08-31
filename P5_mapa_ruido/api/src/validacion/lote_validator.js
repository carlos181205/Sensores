const LOTE_CAPACIDAD = 20;
const NIVEL_MINIMO = 0;
const NIVEL_MAXIMO = 100;
const PRECISION_MAXIMA_METROS = 100000;
const FECHA_MINIMA_MS = Date.parse('2000-01-01T00:00:00.000Z');
const TOLERANCIA_FUTURA_MS = 5 * 60 * 1000;

function errorValidacion(mensaje, status = 400) {
  return { mensaje, status };
}

function esNumeroFinito(valor) {
  return typeof valor === 'number' && Number.isFinite(valor);
}

function validarMuestra(muestra, indice) {
  if (!muestra || typeof muestra !== 'object' || Array.isArray(muestra)) {
    return errorValidacion(`La muestra ${indice + 1} debe ser un objeto.`);
  }

  const campos = [
    'nivelDb',
    'latitud',
    'longitud',
    'precisionM',
    'medidoEn',
  ];

  for (const campo of campos) {
    if (!(campo in muestra)) {
      return errorValidacion(
        `Falta el campo ${campo} en la muestra ${indice + 1}.`,
      );
    }
  }

  if (
    !esNumeroFinito(muestra.nivelDb) ||
    !esNumeroFinito(muestra.latitud) ||
    !esNumeroFinito(muestra.longitud) ||
    !esNumeroFinito(muestra.precisionM) ||
    typeof muestra.medidoEn !== 'string'
  ) {
    return errorValidacion(
      `Los tipos de la muestra ${indice + 1} no son válidos.`,
    );
  }

  if (
    muestra.latitud < -90 ||
    muestra.latitud > 90 ||
    muestra.longitud < -180 ||
    muestra.longitud > 180
  ) {
    return errorValidacion(
      `Las coordenadas de la muestra ${indice + 1} están fuera de rango.`,
      422,
    );
  }

  if (muestra.precisionM < 0 || muestra.precisionM > PRECISION_MAXIMA_METROS) {
    return errorValidacion(
      `La precisión de la muestra ${indice + 1} no es razonable.`,
      422,
    );
  }

  if (muestra.nivelDb < NIVEL_MINIMO || muestra.nivelDb > NIVEL_MAXIMO) {
    return errorValidacion(
      `El nivel de la muestra ${indice + 1} debe estar entre 0 y 100.`,
      422,
    );
  }

  const fechaMs = Date.parse(muestra.medidoEn);
  if (
    Number.isNaN(fechaMs) ||
    fechaMs < FECHA_MINIMA_MS ||
    fechaMs > Date.now() + TOLERANCIA_FUTURA_MS
  ) {
    return errorValidacion(
      `La fecha de la muestra ${indice + 1} no es válida o es futura.`,
      422,
    );
  }

  return null;
}

function validarLote(muestras) {
  if (!Array.isArray(muestras)) {
    return errorValidacion('El campo muestras debe ser un arreglo.');
  }

  if (muestras.length !== LOTE_CAPACIDAD) {
    return errorValidacion(
      `El lote debe contener exactamente ${LOTE_CAPACIDAD} muestras.`,
    );
  }

  for (let indice = 0; indice < muestras.length; indice += 1) {
    const error = validarMuestra(muestras[indice], indice);
    if (error) {
      return error;
    }
  }

  return null;
}

module.exports = {
  LOTE_CAPACIDAD,
  validarLote,
};
