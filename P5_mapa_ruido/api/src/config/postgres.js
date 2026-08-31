const { Pool } = require('pg');
const dotenv = require('dotenv');

dotenv.config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl:
    process.env.DATABASE_SSL === 'true'
      ? { rejectUnauthorized: false }
      : false,
  max: 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 10000,
});

pool.on('error', (error) => {
  console.error(
    'Error inesperado del pool de PostgreSQL:',
    error
  );
});

async function probarConexion() {
  const client = await pool.connect();

  try {
    await client.query('SELECT 1');

    console.log('Conexión a PostgreSQL exitosa');
  } finally {
    client.release();
  }
}

module.exports = {
  pool,
  probarConexion,
};