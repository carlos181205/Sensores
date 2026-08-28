const { Pool } = require('pg');
const dotenv = require('dotenv');

dotenv.config();

const isPostgresConfigured = Boolean(process.env.DATABASE_URL);
const useSsl = process.env.DATABASE_SSL === 'true' || process.env.NODE_ENV === 'production';

const pool = isPostgresConfigured
  ? new Pool({
      connectionString: process.env.DATABASE_URL,
      ssl: useSsl ? { rejectUnauthorized: false } : false,
    })
  : null;

module.exports = {
  pool,
  isPostgresConfigured,
};
