FROM node:22-bookworm-slim

WORKDIR /usr/src/app

RUN apt-get update \
	&& apt-get install -y --no-install-recommends openssl \
	&& rm -rf /var/lib/apt/lists/*

# Prisma reads DATABASE_URL at generate time during image build.
ARG DATABASE_URL="postgresql://postgres:postgres@localhost:5432/postgres"
ENV DATABASE_URL=${DATABASE_URL}

COPY package*.json ./
RUN npm ci

COPY prisma ./prisma
COPY tsconfig.json prisma.config.ts ./
COPY src ./src

RUN npx prisma generate && npm run build && npm prune --omit=dev

EXPOSE 4000

CMD ["npm", "run", "start"]
