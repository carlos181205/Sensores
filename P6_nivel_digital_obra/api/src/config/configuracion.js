const path = require('node:path');

function crearConfiguracion(entorno = process.env) {
  return {
    puerto: Number(entorno.PORT || 3000),
    baseDatosUrl: entorno.DATABASE_URL,
    almacenDir: path.resolve(entorno.ALMACEN_DIR || path.join(process.cwd(), 'almacen')),
    maxFotoBytes: 4 * 1024 * 1024,
    maxInclinacion: 1.5,
    maxDesviacionAzimut: 5,
  };
}

module.exports = { crearConfiguracion };
