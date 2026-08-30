const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');

const authRoutes = require('./src/rutas/auth.routes');
const asistenciaRoutes = require('./src/rutas/asistencia.routes');

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3003;

app.use(cors({ origin: true, credentials: true }));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.get('/api/salud', (req, res) => {
  res.json({ ok: true, mensaje: 'API P4 Asistencia Biométrica activa' });
});

app.use('/api/auth', authRoutes);
app.use('/api', asistenciaRoutes);

app.use((req, res) => {
  res.status(404).json({ ok: false, mensaje: `Ruta no encontrada: ${req.originalUrl}` });
});

app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ ok: false, mensaje: err.message || 'Error interno del servidor' });
});

if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`Servidor P4 Asistencia Biométrica corriendo en http://localhost:${PORT}`);
  });
}

module.exports = app;
