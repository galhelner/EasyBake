# AI Service (`services/ai-service`) — Agent Instructions

`ai-service` (port `8000`) is EasyBake's Python FastAPI microservice powering Chef Pierre's multi-agent system (via **Google ADK**) and direct LLM utilities (via **Google GenAI SDK**).

---

## 1. Directory Structure

```text
services/ai-service/
├─ app/
│  ├─ main.py                # FastAPI app entry point, loads .env, pops GOOGLE_API_KEY, mounts /api router and /health
│  ├─ api/
│  │  └─ endpoints.py        # FastAPI endpoints under /api (/agent/chat, /generate-recipe-from-image, /embeddings, etc.)
│  ├─ agents/                # Google ADK multi-agent hierarchy & callback tools
│  │  ├─ tools.py            # ADK function tools + ContextVars (auth_token_var, stream_queue_var, recipe_id_var)
│  │  ├─ root_router/        # Coordinator agent (agent.py + instructions.md)
│  │  ├─ recipe_specialist/  # Recipe creation & semantic search specialist (agent.py, instructions.md, recipe_creator.md)
│  │  ├─ shopping_list_specialist/ # Shopping list management specialist (agent.py + instructions.md)
│  │  └─ kitchen_assistant/  # Culinary advice, substitutions/swaps & health audit specialist (agent.py + instructions.md)
│  ├─ instructions/          # System prompts for standalone LLM calls (image_recipe_creator.md, ingredient_generator.md)
│  ├─ schemas/               # Pydantic v2 models (recipe.py, ingredient.py, router.py)
│  ├─ services/
│  │  ├─ agent_service.py    # AgentService singleton wrapping Google ADK Runner & InMemorySessionService
│  │  └─ llm_service.py      # Direct google-genai calls (generate_recipe, embeddings, health score, image recipe extraction)
│  ├─ core/
│  │  └─ logger.py           # Logging configuration
│  └─ utils/
│     └─ helpers.py          # SSE streaming wrappers, JSON fence stripping, HTTP error mappers
├─ evals/                    # Evaluation datasets, prompts, and results
├─ tests/                    # Unit and integration test directories
└─ requirements.txt          # Python dependencies (fastapi, uvicorn, python-dotenv, google-genai, pydantic, gunicorn, google-adk)
```

---

## 2. Environment & Google API Key Rule

- **API Key**: `ai-service` uses `GEMINI_API_KEY` from `services/ai-service/.env`.
- **Important (`app/main.py`)**: `os.environ.pop("GOOGLE_API_KEY", None)` is executed immediately after `load_dotenv()` so that `google-genai` and `google-adk` consistently use `GEMINI_API_KEY` without conflicts.
- **Model Configuration (`app/services/llm_service.py`)**:
  - Generative model: `MODEL_NAME = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")`
  - Embeddings model: `"gemini-embedding-001"` with `EMBEDDING_DIM = int(os.getenv("GEMINI_EMBEDDING_DIM", "768"))`
- **Service Callbacks (`app/agents/tools.py`)**:
  - `RECIPE_SERVICE_URL` defaults to `http://localhost:4000` (or `http://recipe-service:4000` in Docker).
  - `INTERNAL_APP_SECRET` is sent in the `X-App-Secret` header on all callbacks to `recipe-service`.

---

## 3. Google ADK Multi-Agent Architecture & SSE Streaming

### Agent Hierarchy (`app/agents/`)
`AgentService` (`app/services/agent_service.py`) runs an `InMemorySessionService` and a root `Runner` configured with `root_router_agent`:
1. **`root_router_agent`** (`app/agents/root_router/`): Inspects `Page Context`, `Recipe Context`, and `User message` to delegate to one of three sub-agents:
2. **`recipe_specialist_agent`** (`app/agents/recipe_specialist/`):
   - Tools: `search_user_recipes(query)`, `display_recipes(recipes)`, `create_recipe(prompt)`.
   - Workflow for search: Calls `search_user_recipes` (which computes a 768-dim embedding locally and calls `POST /chat/internal/recipes/search` on `recipe-service`), filters candidates for relevance, and calls `display_recipes` to push a `{"type": "searchResults", "recipes": [...]}` SSE event.
   - Workflow for creation: Calls `create_recipe` (which runs structured output generation against `RecipeSchema` + calculates `healthScore` via `calculate_health_score`) and pushes a `{"type": "recipeCreated", "recipe": {...}}` SSE event.
3. **`shopping_list_specialist_agent`** (`app/agents/shopping_list_specialist/`):
   - Tools: `add_to_shopping_list(items)`, `add_recipe_to_shopping_list(recipe_name)`.
   - Calls `recipe-service` internal shopping-list endpoints and pushes `{"type": "shoppingListAdded", "items": [...]}` to the SSE stream queue.
4. **`kitchen_assistant_agent`** (`app/agents/kitchen_assistant/`):
   - Answers culinary questions, performs recipe health audits, and suggests ingredient substitutions.
   - When suggesting ingredient swaps, appends a `---METADATA---` delimiter followed by a JSON object at the end of its response. `agent_chat_endpoint` (`app/api/endpoints.py`) intercepts `---METADATA---` using a lookback buffer so raw JSON is never streamed as chat text, emitting it instead as `{"type": "metadata", ...}`.

### ContextVars & Thread/Async Isolation
- `auth_token_var`, `recipe_id_var`, and `stream_queue_var` in `app/agents/tools.py` are `contextvars.ContextVar` instances initialized per request in `AgentService.chat_stream()` before spawning `asyncio.create_task(run_agent())`.
- Whenever adding a new ADK tool in `app/agents/tools.py` that needs to emit a structured UI card to the mobile app or `recipe-service`, push the event dict to `stream_queue_var.get()` using `q.put_nowait({"type": "<eventType>", ...})`.

---

## 4. FastAPI Endpoints (`app/api/endpoints.py`)

All routes are mounted under `/api` (except `GET /health` at root):
- `POST /api/agent/chat`: SSE stream (`text/event-stream`) running the ADK multi-agent pipeline. Seeds new sessions with `payload.history` if the session does not yet exist in `InMemorySessionService`.
- `POST /api/generate-recipe-from-image`: Decodes base64 image payload, runs multimodal structured extraction (`ImageRecipeExtractionSchema` with `image_recipe_creator.md`), returns `RecipeSchema` or `422` if `can_create` is false.
- `POST /api/embeddings`: Generates a 768-float vector using `gemini-embedding-001`.
- `POST /api/analyze-health-score`: Returns `{"health_score": 0..100}` for a recipe title, ingredients, and instructions.
- `POST /api/generate-ingredients`: Generates a 150+ item ingredient archive (`list[IngredientSchema]`) with emojis.
- `POST /api/stream-assistant`: Legacy specialist SSE stream endpoint.

---

## 5. Development & Verification Commands

- **Use the local virtual environment** (`services/ai-service/venv`):
  - Windows Python binary: `.\venv\Scripts\python.exe`
  - Compile / syntax verification: `.\venv\Scripts\python.exe -m py_compile app/main.py app/api/endpoints.py app/services/agent_service.py app/services/llm_service.py app/agents/tools.py`
  - Run local dev server: `.\venv\Scripts\uvicorn.exe app.main:app --host 0.0.0.0 --port 8000 --reload`
- **Blocking SDK Calls**: Because `client.models.generate_content` and `client.models.embed_content` in `google-genai` are synchronous, always wrap them in `await asyncio.to_thread(...)` when calling from `async def` functions or ADK tools so the FastAPI event loop is never blocked.
