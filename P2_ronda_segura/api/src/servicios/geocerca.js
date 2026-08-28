// Fórmula del semiverseno (Haversine): distancia sobre la superficie terrestre en metros.
function distanciaMetros(lat1, lon1, lat2, lon2) {
  const R = 6371000; // Radio de la Tierra en metros
  const rad = (g) => (g * Math.PI) / 180;
  const dLat = rad(lat2 - lat1);
  const dLon = rad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(rad(lat1)) * Math.cos(rad(lat2)) * Math.sin(dLon / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function evaluarGeocerca({ latitud, longitud, precisionM, puntoLat, puntoLon, radioM }) {
  const distancia = distanciaMetros(latitud, longitud, puntoLat, puntoLon);
  // Se suma la incertidumbre del GPS (máximo 30m) al radio del punto de control
  const tolerancia = Number(radioM || 40) + Math.min(Number(precisionM || 0), 30);
  const aceptada = distancia <= tolerancia;

  const motivoRechazo = aceptada
    ? null
    : `Fuera de rango: ${Math.round(distancia)} m (Tolerancia: ${Math.round(tolerancia)} m)`;

  return {
    distancia: Math.round(distancia * 100) / 100,
    tolerancia,
    aceptada,
    motivoRechazo,
  };
}

module.exports = {
  distanciaMetros,
  evaluarGeocerca,
};
