const {
  crearMuestras,
  obtenerMuestras,
  obtenerMapa,
} = require('../repositorios/muestras_repository');
const { validarLote } = require('../validacion/lote_validator');

async function guardarMuestras(req, res) {
  try {
    const muestras = req.body?.muestras;
    const error = validarLote(muestras);

    if (error) {
      return res.status(error.status).json({
        ok: false,
        mensaje: error.mensaje,
        ...(Array.isArray(muestras) ? { cantidad: muestras.length } : {}),
      });
    }

    const cantidad = await crearMuestras(muestras);

    return res.status(201).json({
      ok: true,
      mensaje:
        'Lote de muestras guardado correctamente.',
      cantidad,
    });
  } catch (error) {
    console.error(
      'Error guardando muestras:',
      error
    );

    return res.status(500).json({
      ok: false,
      mensaje: 'Error interno del servidor.',
    });
  }
}

async function consultarMapa(req, res) {
  try {
    const datos = await obtenerMapa();
    return res.json({ ok: true, datos });
  } catch (error) {
    console.error('Error obteniendo mapa:', error);
    return res.status(500).json({
      ok: false,
      mensaje: 'No se pudo obtener el mapa de ruido.',
    });
  }
}

async function listarMuestras(req, res) {
  try {
    const muestras = await obtenerMuestras();

    return res.json({
      ok: true,
      cantidad: muestras.length,
      muestras,
    });
  } catch (error) {
    console.error(
      'Error obteniendo muestras:',
      error
    );

    return res.status(500).json({
      ok: false,
      mensaje: 'Error interno del servidor.',
    });
  }
}

module.exports = {
  guardarMuestras,
  listarMuestras,
  consultarMapa,
};
