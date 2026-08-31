function normalizarAzimut(grados) {
  const valor = Number(grados);
  if (!Number.isFinite(valor)) throw new Error('El azimut debe ser numérico.');
  return ((valor % 360) + 360) % 360;
}

// Positivo: giro horario desde el objetivo hasta el rumbo actual.
function desviacionCircular(actual, objetivo) {
  const diferencia = ((normalizarAzimut(actual) - normalizarAzimut(objetivo) + 540) % 360) - 180;
  return diferencia === -180 ? 180 : diferencia;
}

function cumpleMedicion({ inclinacionX, inclinacionY, azimut, azimutObjetivo }, configuracion) {
  return Math.abs(inclinacionX) <= configuracion.maxInclinacion &&
    Math.abs(inclinacionY) <= configuracion.maxInclinacion &&
    Math.abs(desviacionCircular(azimut, azimutObjetivo)) <= configuracion.maxDesviacionAzimut;
}

module.exports = { normalizarAzimut, desviacionCircular, cumpleMedicion };
