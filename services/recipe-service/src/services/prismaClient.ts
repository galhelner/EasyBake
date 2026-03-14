import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import pg from 'pg';

const dbUrl = process.env.DATABASE_URL;

if (!dbUrl) {
  throw new Error("DATABASE_URL is not defined in environment variables");
}

// Manually parse the URL to extract components
const url = new URL(dbUrl);

const pool = new pg.Pool({
  user: url.username,
  // decodeURIComponent handles any special characters like @ or # in your password
  password: decodeURIComponent(url.password),
  host: url.hostname,
  port: parseInt(url.port),
  database: url.pathname.split('/')[1],
  // Supabase direct connection requires SSL
  ssl: {
    rejectUnauthorized: false // Helps avoid local certificate issues
  },
});

const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

export default prisma;