import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

dotenv.config({ path: path.join(__dirname, '.env') });

const dbConfig = {
  client: 'pg',
  connection: {
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'trustuser',
    password: process.env.DB_PASS || 'trustpass',
    database: process.env.DB_NAME || 'trustprism',
    port: process.env.DB_PORT || 5432
  },
  pool: {
    min: 2,
    max: 10
  },
  migrations: {
    tableName: 'knex_migrations',
    directory: './migrations'
  }
};

export default {
  development: dbConfig,
  staging: dbConfig,
  production: dbConfig
};
