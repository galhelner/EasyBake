# Chat Service (`services/chat-service`) — Agent Instructions

`chat-service` (port `4001`) provides real-time community chat via Socket.IO and Express, user profile display name management, and `@aichef` community AI assistant integration. Built with Node.js 22, TypeScript, Express, Socket.IO, Prisma 7 (`@prisma/adapter-pg`), Supabase Auth, and Winston.

---

## 1. Directory Structure

```text
services/chat-service/
├─ prisma/
│  ├─ schema.prisma          # PostgreSQL schema (MUST stay in sync with recipe-service)
│  └─ migrations/            # SQL migration history
├─ src/
│  ├─ index.ts               # Express + HTTP Server + Socket.IO server setup, REST routes, socket event handlers
│  ├─ middleware/
│  │  └─ socketAuth.ts       # Supabase JWT verification for both REST endpoints and Socket.IO handshake
│  ├─ services/
│  │  ├─ chatService.ts      # Message persistence (CommunityChatMessage), history retrieval, AI service SSE consumer
│  │  ├─ prismaClient.ts     # Lazy singleton getPrismaClient() using @prisma/adapter-pg and pg.Pool
│  │  └─ logger.ts           # Winston logger
│  └─ tests/unit/
│     └─ services/chatService.test.ts # Jest unit tests for chatService
```

---

## 2. Authentication & User Resolution (`socketAuth.ts`)

- Both REST routes (`GET /messages`, `GET /profile`, `PATCH /profile`) and Socket.IO connections (`socket.handshake.auth.token`) authenticate via `authenticateToken(token)` in `src/middleware/socketAuth.ts`.
- `authenticateToken` verifies the Bearer JWT with Supabase (`client.auth.getUser(token)`), then looks up the Prisma `User` record via `where: { authId: data.user.id }`.
- Unlike `recipe-service`, `authenticatedUser.userId` (and `authSocket.userId`) in `chat-service` is **already resolved to the internal Prisma `User.id`**.

---

## 3. REST Endpoints & Socket.IO Protocol

### REST Endpoints (`src/index.ts`)
- `GET /health`: Healthcheck returning `{ status: 'ok', service: 'chat-service' }`.
- `GET /messages?limit=50`: Returns recent `CommunityChatMessage` items (capped at 100, ordered oldest-to-newest).
- `GET /profile`: Returns `{ id, email, displayName, fullName }` for the authenticated user.
- `PATCH /profile`: Updates `User.displayName` in Prisma and broadcasts `user_updated` (`{ userId, displayName }`) to the `community-chat` room.

### Socket.IO Room & Events (`COMMUNITY_ROOM = 'community-chat'`)
- **On Connection**:
  - Verifies auth via `verifySocketAuth(authSocket)`; disconnects immediately if unauthorized.
  - Joins `community-chat`, emits `message_history` (last 50 messages) to the connecting socket, and broadcasts `user_joined` (`{ userId, email, timestamp }`) to the room.
- **Incoming `send_message` Event**:
  - Validates message length (`<= 500` chars) and normalizes `messageType` (`text`, `recipe`, or `ai-assistant`).
  - **`text` / `recipe`**: Persists to `CommunityChatMessage` via `saveMessage` and broadcasts `new_message` to `community-chat`. (`recipe` messages require a non-empty `recipeId`).
  - **`ai-assistant`**: Strips `@aichef` mentions, loads the last 10 community messages as history, and calls `generateAssistantReply(question, userId)` in `src/services/chatService.ts`, which sends a `POST` request to `ai-service` (`/api/agent/chat` with `session_id: "community-chat-${userId}"`).
  - System AI replies are saved and broadcasted under the upserted system user `id: 'ai-chef'` (`authId: 'system:ai-chef'`, `displayName: 'AI Chef'`) as:
    1. A `new_message` with `messageType: 'ai-assistant'` for the text reply.
    2. If a recipe was generated (`recipeCreated` SSE chunk), a second `new_message` with `messageType: 'recipePreview'` and `metadata: recipe`.
- **On Disconnect**: Broadcasts `user_left` (`{ userId, timestamp }`) to `community-chat`.

---

## 4. Prisma & Testing Conventions

- **Schema Sync**: Keep `prisma/schema.prisma` identical to `services/recipe-service/prisma/schema.prisma` and run `npx prisma generate` after any changes.
- **Prisma Access Pattern**: In `chat-service`, `prismaClient.ts` exports a factory function `getPrismaClient()` (default export) rather than an eager instance. Always call `getPrismaClient()` to obtain the client.
- **Unit Tests & Linting**:
  - Unit tests live in `src/tests/unit/`. Mock `getPrismaClient`, `logger`, and `fetch` when testing `chatService.ts`.
  - CI enforces `npm run lint` (`--max-warnings=0`), `npm run test:unit`, and `npm run build` on Node 22.x.

---

## 5. Key Commands

- **Install & generate Prisma client**: `npm install && npx prisma generate`
- **Dev server (hot reload)**: `npm run dev`
- **Linter (CI enforced, 0 warnings allowed)**: `npm run lint`
- **Unit tests (CI enforced)**: `npm run test:unit`
- **TypeScript build (CI enforced)**: `npm run build`
