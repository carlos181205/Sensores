const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');

const inventarioRoutes = require('./src/rutas/inventario');

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3002;

app.use(cors({ origin: true, credentials: true }));
app.use(express.json({ limit: '10mb' })); // Límite para fotos en Base64
app.use(express.urlencoded({ extended: true }));

app.get('/api/salud', (req, res) => {
  res.json({ ok: true, mensaje: 'API P3 Inventario Offline activa' });
});

app.use('/api', inventarioRoutes);

app.use((req, res) => {
  res.status(404).json({ ok: false, mensaje: `Ruta no encontrada: ${req.originalUrl}` });
});

app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ ok: false, mensaje: err.message || 'Error interno del servidor' });
});

if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`Servidor P3 Inventario Offline corriendo en http://localhost:${PORT}`);
  });
}

module.exports = app;
