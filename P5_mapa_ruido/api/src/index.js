const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');

const {
  probarConexion,
} = require('./config/postgres');

const muestrasRoutes = require('./rutas/muestras_routes');

dotenv.config();

const app = express();

app.use(cors());
app.use(express.json());

app.get('/health', (req, res) => {
  res.json({
    ok: true,
    servicio: 'P5 - Mapa de ruido',
  });
});

app.use('/api', muestrasRoutes);

app.use((error, req, res, next) => {
  if (error instanceof SyntaxError && error.status === 400 && 'body' in error) {
    return res.status(400).json({
      ok: false,
      mensaje: 'El cuerpo de la solicitud no es JSON válido.',
    });
  }

  console.error('Error no controlado en la API:', error);
  return res.status(500).json({
    ok: false,
    mensaje: 'Error interno del servidor.',
  });
});

const PORT = process.env.PORT || 3000;

async function iniciarServidor() {
  try {
    await probarConexion();

    app.listen(PORT, '0.0.0.0', () => {
  console.log(
    `API P5 ejecutándose en http://0.0.0.0:${PORT}`,
  );
});
  } catch (error) {
    console.error(
      'No se pudo conectar a PostgreSQL:',
      error.message,
    );

    process.exit(1);
  }
}

if (require.main === module) {
  iniciarServidor();
}

module.exports = { app, iniciarServidor };
