const { Pool } = require('pg');
const dotenv = require('dotenv');

dotenv.config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});

pool.on('error', (err) => {
  console.error('Error inesperado del pool de PostgreSQL:', err);
});

async function testConnection() {
  try {
    const client = await pool.connect();
    await client.query('SELECT 1');
    client.release();
    console.log('Conexión a PostgreSQL exitosa');
  } catch (error) {
    console.error('No se pudo conectar a PostgreSQL:', error.message);
  }
}

module.exports = {
  pool,
  testConnection,
};
