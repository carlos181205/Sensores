const { pool } = require('../config/postgres');
const { randomUUID } = require('crypto');

async function crearMuestras(muestras) {
  const client = await pool.connect();
  const sesionId = randomUUID();

  try {
    await client.query('BEGIN');

    for (const muestra of muestras) {
      await client.query(
        `
        INSERT INTO muestras_ruido (
          id,
          sesion_id,
          nivel_db,
          latitud,
          longitud,
          precision_m,
          medido_en
        )
        VALUES (
          gen_random_uuid(),
          $1,
          $2,
          $3,
          $4,
          $5
        )
        `,
        [
          sesionId,
          muestra.nivelDb,
          muestra.latitud,
          muestra.longitud,
          muestra.precisionM,
          muestra.medidoEn,
        ]
      );
    }

    await client.query('COMMIT');

    return muestras.length;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

async function obtenerMuestras() {
  const resultado = await pool.query(
    `
    SELECT
      id,
      nivel_db,
      latitud,
      longitud,
      precision_m,
      medido_en,
      creado_en
    FROM muestras_ruido
    ORDER BY medido_en DESC
    `
  );

  return resultado.rows;
}

async function obtenerMapa() {
  const resultado = await pool.query(
    `
    SELECT
      celda_lat,
      celda_lon,
      promedio_db,
      maximo_db,
      muestras
    FROM mapa_ruido
    ORDER BY celda_lat, celda_lon
    `,
  );

  return resultado.rows.map((fila) => ({
    celdaLat: Number(fila.celda_lat),
    celdaLon: Number(fila.celda_lon),
    promedioDb: Number(fila.promedio_db),
    maximoDb: Number(fila.maximo_db),
    muestras: Number(fila.muestras),
  }));
}

module.exports = {
  crearMuestras,
  obtenerMuestras,
  obtenerMapa,
};
