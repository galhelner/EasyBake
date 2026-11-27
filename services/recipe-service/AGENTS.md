# Recipe Service (`services/recipe-service`) — Agent Instructions

`recipe-service` (port `4000`) is EasyBake's primary REST API and orchestration gateway. Built with Node.js 22, TypeScript, Express, Prisma 7 (`@prisma/adapter-pg`), Supabase Auth & Storage, Multer, Zod, and Winston.

---

## 1. Directory Structure

```text
services/recipe-service/
├─ prisma/
│  ├─ schema.prisma          # PostgreSQL + pgvector schema (MUST stay in sync with chat-service)
│  └─ migrations/            # SQL migration history
├─ src/
│  ├─ index.ts               # Express app setup, CORS, X-App-Secret middleware, route mounting, graceful tmp/ cleanup
│  ├─ controllers/
│  │  ├─ auth.controller.ts         # Register, login, email-exists via Supabase Auth + Prisma User sync
│  │  ├─ recipe.controller.ts       # Recipe CRUD, image upload, AI image-to-recipe, pgvector search, ingredient search
│  │  ├─ folder.controller.ts       # Nested user recipe folders CRUD
│  │  ├─ shoppingList.controller.ts # User shopping list CRUD
│  │  └─ chat.controller.ts         # Private Chef Pierre SSE proxy + internal callback endpoints for ai-service tools
│  ├─ middleware/
│  │  └─ authMiddleware.ts          # Validates Bearer token via Supabase auth.getUser() -> sets req.user.id (Supabase authId)
│  ├─ routes/                # Express routers: /auth, /recipes, /chat, /shopping-list
│  ├─ services/
│  │  ├─ prismaClient.ts     # PrismaClient singleton using @prisma/adapter-pg and pg.Pool (SSL enabled for Supabase)
│  │  ├─ supabaseClient.ts   # Supabase client singleton
│  │  ├─ storageService.ts   # Uploads/deletes recipe images in Supabase Storage bucket `recipe-images`
│  │  ├─ ingredientArchiveService.ts # Ingredient archive seeding helper
│  │  └─ logger.ts           # Winston logger
│  ├─ scripts/               # CLI utilities (loadIngredientsArchive.ts)
│  └─ tests/unit/            # Jest unit test suites mirroring controllers/, middleware/, and services/
```

---

## 2. Authentication & Security Layers

1. **Global App Secret (`enforceInternalAppSecret` in `src/index.ts`)**:
   - Every endpoint except `GET /health` requires the header `X-App-Secret` matching `process.env.INTERNAL_APP_SECRET`.
2. **User JWT Authentication (`authMiddleware` in `src/middleware/authMiddleware.ts`)**:
   - Applied to `/recipes`, `/chat`, and `/shopping-list`.
   - Validates `Authorization: Bearer <token>` against Supabase (`client.auth.getUser(token)`).
   - **Important ID Distinction**: `req.user.id` is the **Supabase Auth UUID** (`User.authId` in Prisma), **NOT** `User.id` (the internal Prisma UUID). When querying or mutating records (`Recipe.authorId`, `Folder.userId`, `ShoppingListItem.userId`, `ChefChatMessage.userId`), always resolve the Prisma `User` record via `where: { authId: req.user.id }` (or `author: { authId: req.user.id }`).

---

## 3. API Routes & AI Service Integration

### Routes Summary
- **`/auth`**: `POST /register`, `POST /login`, `POST /email-exists`
- **`/recipes`**:
  - Folders (declared before `/:id`): `POST /folders`, `GET /folders`, `PUT /folders/:id`, `DELETE /folders/:id`
  - Recipes: `GET /`, `POST /` (multipart `image`), `POST /create-from-image` (multipart `image`), `POST /search` (semantic pgvector search), `GET /ingredients/search?q=...`, `GET /:id`, `PUT /:id` (multipart `image`), `PUT /:id/move`, `DELETE /:id`
  - **Note on `GET /recipes/:id`**: Any authenticated user may read a recipe by ID (so recipes shared in community chat can be viewed by anyone), while `PUT` and `DELETE` verify `author: { authId: req.user.id }`.
- **`/shopping-list`**: `GET /`, `POST /`, `PATCH /:id`, `DELETE /:id`
- **`/chat`**:
  - Mobile endpoints: `POST /` (streams SSE from `ai-service` `/api/agent/chat` and saves `ChefChatMessage` records), `GET /history`, `DELETE /history`
  - Internal callback endpoints called by `ai-service` ADK tools:
    - `POST /chat/internal/recipes/search` (accepts pre-computed 768-dim `embedding` array, queries pgvector with cosine distance `<= 0.85`)
    - `POST /chat/internal/shopping-list/add` (upserts normalized lowercase ingredient names and adds/updates `ShoppingListItem`s)
    - `POST /chat/internal/shopping-list/add-recipe` (adds all ingredients of a user's recipe by `recipeId` or case-insensitive `recipeName` to their shopping list)

### Pgvector & Embeddings
- `Recipe.embedding` is `Unsupported("vector(768)")?`.
- Prisma cannot read or write `vector(768)` directly via standard CRUD methods; always use `prisma.$executeRaw` / `prisma.$queryRaw` with `CAST(${vectorLiteral} AS vector)` and cosine distance operator `<=>`.

---

## 4. Prisma & Testing Conventions

- **Schema Sync**: If you edit `prisma/schema.prisma`, you **must** apply the exact same change to `services/chat-service/prisma/schema.prisma` and run `npx prisma generate` in both directories.
- **Validation**: Use `zod` (`safeParse`) in controllers for request body and query validation, returning `400` with `{ error: 'Validation error', details: parsed.error.flatten() }`.
- **Temporary Uploads**: Multer stores uploads in `tmp/uploads`. Always clean up `req.file` in a `finally` block using `cleanupTempUpload(req.file)`.
- **Unit Tests (`src/tests/unit/`)**:
  - Mock external dependencies (`prismaClient`, `supabaseClient`, `axios`, `storageService`, `logger`) in unit tests so tests run offline without a live database.
  - Run `npm run test:unit` and `npm run lint` (`--max-warnings=0`) before finishing any task in `recipe-service`.

---

## 5. Key Commands

- **Install & generate Prisma client**: `npm install && npx prisma generate`
- **Dev server (hot reload)**: `npm run dev`
- **Linter (CI enforced, 0 warnings allowed)**: `npm run lint`
- **Unit tests (CI enforced)**: `npm run test:unit`
- **TypeScript build (CI enforced)**: `npm run build`
