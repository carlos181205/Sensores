const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');

const rondasRoutes = require('./src/rutas/rondas');

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3001;

app.use(cors({ origin: true, credentials: true }));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.get('/api/salud', (req, res) => {
  res.json({ ok: true, mensaje: 'API P2 Ronda Segura activa' });
});

app.use('/api', rondasRoutes);

app.use((req, res) => {
  res.status(404).json({ ok: false, mensaje: `Ruta no encontrada: ${req.originalUrl}` });
});

app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ ok: false, mensaje: err.message || 'Error interno del servidor' });
});

if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`Servidor P2 Ronda Segura corriendo en http://localhost:${PORT}`);
  });
}

module.exports = app;
