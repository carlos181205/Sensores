const { Pool } = require('pg');
const dotenv = require('dotenv');

dotenv.config();

const isPostgresConfigured = Boolean(process.env.DATABASE_URL);

const pool = isPostgresConfigured
  ? new Pool({
      connectionString: process.env.DATABASE_URL,
      ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
    })
  : null;

module.exports = {
  pool,
  isPostgresConfigured,
};
