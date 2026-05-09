import { existsSync, mkdirSync } from 'fs';
import { resolve } from 'path';
import { createLogger, format, transports } from 'winston';

const logsDir = resolve(process.cwd(), 'logs');

if (!existsSync(logsDir)) {
  mkdirSync(logsDir, { recursive: true });
}

const baseFormat = format.printf(({ timestamp, level, message }) => {
  return `${timestamp} [${level.toUpperCase()}] ${message}`;
});

const consoleFormat = process.env.NODE_ENV === 'production'
  ? format.combine(
      format.timestamp(),
      baseFormat,
    )
  : format.combine(
      format.timestamp(),
      format.colorize({ all: true }),
      baseFormat,
    );

const logger = createLogger({
  level: process.env.LOG_LEVEL ?? 'info',
  transports: [
    new transports.Console({
      format: consoleFormat,
    }),
    new transports.File({
      filename: resolve(logsDir, 'recipe-service.log'),
      format: format.combine(
        format.timestamp(),
        baseFormat,
      ),
    }),
  ],
});

export default logger;