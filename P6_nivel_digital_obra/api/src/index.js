require('dotenv').config();

const fs = require('node:fs');
const { Pool } = require('pg');
const { crearConfiguracion } = require('./config/configuracion');
const { crearApp } = require('./app');
const { RepositorioVisitasPg } = require('./repositorios/repositorio_visitas_pg');
const { ServicioVisitas } = require('./servicios/servicio_visitas');
const { ServicioReporte } = require('./servicios/servicio_reporte');

function construirAplicacion() {
  const configuracion = crearConfiguracion();
  if (!configuracion.baseDatosUrl) throw new Error('DATABASE_URL es obligatoria. Configure api/.env a partir de .env.example.');
  fs.mkdirSync(configuracion.almacenDir, { recursive: true });
  const pool = new Pool({ connectionString: configuracion.baseDatosUrl });
  const repositorio = new RepositorioVisitasPg(pool);
  const servicioVisitas = new ServicioVisitas({ repositorio, configuracion, almacenDir: configuracion.almacenDir });
  const servicioReporte = new ServicioReporte({ servicioVisitas, almacenDir: configuracion.almacenDir });
  return { app: crearApp({ servicioVisitas, servicioReporte, configuracion }), configuracion };
}

if (require.main === module) {
  const { app, configuracion } = construirAplicacion();
  app.listen(configuracion.puerto, () => console.log(`API disponible en puerto ${configuracion.puerto}`));
}

module.exports = { construirAplicacion };
