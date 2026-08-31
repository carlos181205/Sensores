const express = require('express');
const fs = require('node:fs');
const cors = require('cors');
const multer = require('multer');
const { crearSubidaFoto } = require('./middleware/subida_foto');
const { crearControladorVisitas } = require('./controladores/controlador_visitas');
const { crearRutasVisitas } = require('./rutas/rutas_visitas');

function crearApp({ servicioVisitas, servicioReporte, configuracion }) {
  const app = express();
  app.use(cors());
  app.use(express.json());
  app.get('/health', (_, res) => res.json({ estado: 'ok' }));
  const controlador = crearControladorVisitas(servicioVisitas, servicioReporte);
  app.use('/api/visitas', crearRutasVisitas(controlador, crearSubidaFoto(configuracion)));
  app.use((_, res) => res.status(404).json({ error: 'Ruta no encontrada.' }));
  app.use((error, req, res, _) => {
    if (req.file?.path) fs.unlink(req.file.path, () => {});
    if (error instanceof multer.MulterError && error.code === 'LIMIT_FILE_SIZE') return res.status(413).json({ error: 'La fotografía supera el límite de 4 MB.' });
    const estado = error.estado || 400;
    return res.status(estado).json({ error: error.message || 'Solicitud inválida.' });
  });
  return app;
}

module.exports = { crearApp };
