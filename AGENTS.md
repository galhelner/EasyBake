# EasyBake — Monorepo Agent Instructions

EasyBake is an AI-powered culinary companion platform consisting of a Flutter mobile application (`apps/easy_bake_mobile`) and three backend microservices (`services/recipe-service`, `services/chat-service`, `services/ai-service`) backed by Supabase (Auth, PostgreSQL, Storage, and `pgvector`) and Google Gemini / Google ADK.

---

## 1. Repository Map & Module Overview

| Path | Stack | Port | Responsibility |
| :--- | :--- | :--- | :--- |
| `apps/easy_bake_mobile` | Flutter (Dart ^3.11.1, Riverpod 3, Dio, Socket.IO) | — | Cross-platform user experience (Android, iOS, Web, Desktop), RTL/LTR localized (`en`, `he`). |
| `services/recipe-service` | Node.js 22, TypeScript, Express, Prisma 7, Multer | `4000` | Main REST API gateway: auth, recipes, folders, shopping list, image uploads, pgvector search, and private Chef Pierre SSE proxy. |
| `services/chat-service` | Node.js 22, TypeScript, Express, Socket.IO, Prisma 7 | `4001` | Real-time community chat (`community-chat` room), user profile updates, and `@aichef` community mentions. |
| `services/ai-service` | Python 3.12, FastAPI, Google GenAI, Google ADK | `8000` | Multi-agent AI orchestrator (`root_router_agent` + 3 specialists), recipe generation from text/image, health score analysis, and 768-dim embeddings. |
| `dev/` | PowerShell (`run_local.ps1`, `run_cloud.ps1`) | — | Developer launchers that start Docker services, resolve host IP, and run Flutter with `--dart-define` flags. |
| `scripts/` | PowerShell (`windows/`) & Bash (`linux/`) | — | `start-services` (`docker compose up -d --build`) and `stop-services` (`docker compose down`). |
| `.github/workflows/` | GitHub Actions | — | Reusable CI/CD template (`ci-cd_pipeline_template.yml`) deploying services to Azure Web Apps + iOS build workflow. |

> **Hierarchical `AGENTS.md` Files**: Each sub-project has its own `AGENTS.md` with deep technical specifics:
> - `apps/easy_bake_mobile/AGENTS.md`
> - `services/recipe-service/AGENTS.md`
> - `services/chat-service/AGENTS.md`
> - `services/ai-service/AGENTS.md`

---

## 2. Inter-Service Architecture & Request Flows

1. **Mobile App -> Recipe Service (`http://localhost:4000`)**:
   - All requests (except `/health`) **require** header `X-App-Secret: <INTERNAL_APP_SECRET>`.
   - Protected routes (`/recipes`, `/chat`, `/shopping-list`) also require `Authorization: Bearer <supabase_access_token>`.
2. **Mobile App -> Chat Service (`http://localhost:4001`)**:
   - WebSocket connection via Socket.IO passes `{ auth: { token: <supabase_access_token> } }`.
   - REST endpoints (`GET /messages`, `GET /profile`, `PATCH /profile`) require `Authorization: Bearer <supabase_access_token>`.
3. **Recipe Service <-> AI Service (`http://localhost:8000/api`)**:
   - `POST /chat` on `recipe-service` loads the last 10 `ChefChatMessage` records and proxies an SSE stream from `POST /api/agent/chat` on `ai-service`, persisting streamed text and tool events (`recipeCreated`, `searchResults`, `shoppingListAdded`, `metadata` swaps) to PostgreSQL.
   - **Callback Loop**: During an `/api/agent/chat` session, `ai-service` ADK tools call back into `recipe-service` internal endpoints (`/chat/internal/recipes/search`, `/chat/internal/shopping-list/add`, `/chat/internal/shopping-list/add-recipe`) forwarding the user's `Authorization` header and `X-App-Secret`.
   - `recipe-service` also calls `ai-service` directly for `POST /api/embeddings` (`gemini-embedding-001`, 768 dimensions), `POST /api/analyze-health-score`, `POST /api/generate-recipe-from-image`, and `POST /api/generate-ingredients`.
4. **Chat Service -> AI Service (`http://localhost:8000/api`)**:
   - When a community chat message has `messageType: 'ai-assistant'` (or `@aichef` mention), `chat-service` calls `POST /api/agent/chat` with `session_id: "community-chat-${userId}"` and broadcasts the resulting text and `recipePreview` card to the `community-chat` Socket.IO room as system user `ai-chef`.

---

## 3. Shared Database & Prisma Schema Sync Rule

- **Database**: Supabase PostgreSQL with `pgvector` (`vector(768)` on `Recipe.embedding`).
- **Dual Prisma Clients**: Both `services/recipe-service/prisma/schema.prisma` and `services/chat-service/prisma/schema.prisma` connect to the **same** PostgreSQL database and define the shared models (`User`, `Recipe`, `Folder`, `Ingredient`, `RecipeIngredient`, `ShoppingListItem`, `CommunityChatMessage`, `ChefChatMessage`).
- **CRITICAL RULE**: Whenever you modify the database schema or add a migration in `recipe-service` or `chat-service`:
  1. Keep `services/recipe-service/prisma/schema.prisma` and `services/chat-service/prisma/schema.prisma` **in sync**.
  2. Run `npx prisma generate` in **both** services after any schema change.
  3. Notice that `User.authId` is the Supabase Auth UUID (`req.user.id` in `recipe-service`), whereas `User.id` is the internal Prisma UUID used as foreign key (`authorId`, `userId`). Always map `authId -> User.id` before querying user relations.

---

## 4. Local Development & Verification Commands

### Docker & Full-Stack Launch
- **Start all backend containers**: `docker compose up -d --build` (or `./scripts/windows/start-services.ps1`)
- **Stop all backend containers**: `docker compose down` (or `./scripts/windows/stop-services.ps1`)
- **Launch local stack + Flutter app**: `./dev/run_local.ps1` (requires `$env:INTERNAL_APP_SECRET` set in PowerShell)
- **Launch Flutter app against Azure Cloud**: `./dev/run_cloud.ps1` (requires `$env:INTERNAL_APP_SECRET` set in PowerShell)

### Per-Module Fast Verification
- **`services/recipe-service`**:
  - Lint: `npm run lint` (ESLint with `--max-warnings=0`)
  - Unit tests: `npm run test:unit` (Jest in `src/tests/unit`)
  - Build: `npm run build` (`tsc`)
- **`services/chat-service`**:
  - Lint: `npm run lint` (ESLint with `--max-warnings=0`)
  - Unit tests: `npm run test:unit` (Jest in `src/tests/unit`)
  - Build: `npm run build` (`tsc`)
- **`services/ai-service`**:
  - Syntax / compile check: `.\venv\Scripts\python.exe -m py_compile app/main.py` (or target modified Python files)
  - Run locally: `.\venv\Scripts\uvicorn.exe app.main:app --reload --port 8000`
- **`apps/easy_bake_mobile`**:
  - **NEVER** run `flutter test`.
  - For targeted Dart changes, run `dart analyze <modified_file_path>` from `apps/easy_bake_mobile`. Only run full `flutter analyze` for sweeping cross-app refactors.

---

## 5. Global Guardrails for Agents

1. **Git Safety**: Never run state-modifying git commands (`git add`, `git commit`, `git push`, `git checkout`, `git reset`) unless explicitly asked by the user.
2. **Environment & Secrets**: Never hardcode or commit API keys, Supabase credentials, or `INTERNAL_APP_SECRET`. Each service loads its own `.env` file (`services/*/.env`), and Flutter receives secrets via `--dart-define`.
3. **CI/CD Awareness**: Push to `main` in `services/<service-name>/**` triggers `.github/workflows/main_easybake-<service-name>.yml`. For Node services, CI enforces `npm run lint` (`--max-warnings=0`), `npm run test:unit`, and `npm run build` on Node 22.x before deploying. Always ensure lint and unit tests pass when touching Node services.
