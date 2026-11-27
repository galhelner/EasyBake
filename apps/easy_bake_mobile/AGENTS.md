# EasyBake Mobile (`apps/easy_bake_mobile`) — Agent Instructions

Flutter cross-platform application (Android, iOS, Web, Desktop) using Dart `^3.11.1`, Material 3, Riverpod 3 (`flutter_riverpod` / `riverpod`), `dio`, and `socket_io_client`.

> **Skill Integration**: When creating, modifying, or reviewing Flutter UI widgets or pages, also follow `.agents/skills/flutter-ai-ui-skill/SKILL.md`.

---

## 1. Directory & Feature-First Architecture

```text
lib/
├─ main.dart                  # App entry point, NotificationService init, locale restore, animated splash, auth bootstrap
├─ l10n/                      # Generated localizations + ARB templates (app_en.arb, app_he.arb)
├─ core/
│  ├─ localization/           # app_locale_controller.dart (ValueNotifier<Locale?> persisted in SharedPreferences)
│  ├─ network/                # api_client.dart (dioProvider, chatServiceBaseUrlProvider, --dart-define resolution)
│  ├─ services/               # notification_service.dart (flutter_local_notifications singleton initialized once in main)
│  └─ widgets/                # app_toast.dart, skeleton.dart (reusable shimmer/skeleton loaders)
└─ features/
   ├─ ai-chat/                # Chef Pierre popup chat (SSE stream consumer, recipe preview cards, swap summaries, search results)
   ├─ auth/                   # Login & registration pages, auth_notifier.dart, token persistence in SharedPreferences
   ├─ community-chat/         # Socket.IO real-time community chat room, recipe sharing, @aichef mentions
   ├─ home/                   # HomeTabsPage (bottom navigation) & HomeDashboardPage
   ├─ profile/                # User profile, displayName updates, dietary/health preferences, language switcher
   ├─ recipes/                # Recipe list, nested folders, semantic search, manual & image-based creation, recipe details
   └─ shopping-list/          # User shopping list CRUD, ingredient check/uncheck, quantity editing
```

Each feature under `lib/features/<feature-name>/` is strictly organized into:
- `data/services/`: Dio HTTP services, Socket.IO clients, or `SharedPreferences` storage services.
- `domain/models/`: Immutable domain models and state classes.
- `presentation/providers/`: Riverpod `Notifier` / `AsyncNotifier` / `Provider` state definitions.
- `presentation/pages/`: Top-level screen widgets for the feature.
- `presentation/widgets/`: Small, modular, focused `StatelessWidget` / `ConsumerWidget` sub-components (grouped into sub-folders like `recipe_list/`, `recipe_details/`, `recipe_create/`, `home_dashboard/` when a feature has multiple screens).

---

## 2. Networking, Auth & `--dart-define` Configuration

All HTTP calls to `recipe-service` go through `dioProvider` in `lib/core/network/api_client.dart`:
- **Headers**: Automatically injects `X-App-Secret` (from `--dart-define=INTERNAL_APP_SECRET=...`) and `Authorization: Bearer <token>` (from `authTokenProvider`).
- **401 Handling**: A `401` response automatically clears auth state via `ref.read(authNotifierProvider.notifier).clear()`.
- **Environment Routing**:
  - Default (`DEV_MODE=false`): Connects to Azure production URLs (`easybake-recipe-service...` and `easybake-chat-service...`).
  - Local (`--dart-define=DEV_MODE=true`): Uses `LOCAL_API_BASE_URL` (default `http://localhost:4000` or `http://10.0.2.2:4000` on Android emulator) and `LOCAL_CHAT_BASE_URL` (default `http://localhost:4001` or `http://10.0.2.2:4001` on Android emulator).
- **SSE Streaming (`ChatService`)**:
  - `lib/features/ai-chat/data/services/chat_service.dart` streams `POST /chat` from `recipe-service` with `ResponseType.stream` and parses `data: {...}` SSE blocks into `ChatEvent` variants (`textDelta`, `metadata`, `recipeCreated`, `searchResults`, `shoppingListAdded`, `error`, `done`).

---

## 3. Localization (i18n) & RTL Support (`en` & `he`)

The app fully supports English (`en`, LTR) and Hebrew (`he`, RTL).
1. **No Hardcoded UI Strings**:
   - Every user-facing string MUST be defined in both `lib/l10n/app_en.arb` and `lib/l10n/app_he.arb`.
   - After editing `.arb` files, regenerate localization classes by running `flutter gen-l10n` from `apps/easy_bake_mobile`.
   - Access strings in `build` via `final l10n = AppLocalizations.of(context)!;`.
2. **Strict Directional Layout APIs**:
   - Always use `EdgeInsetsDirectional`, `AlignmentDirectional`, `Positioned.directional`, and `BorderDirectional` instead of `left`/`right` properties so Hebrew (RTL) layouts mirror cleanly.

---

## 4. UI/UX & Widget Conventions

- **Modular Widgets**: Never build monolithic `build()` methods. Extract visual sections into separate classes under `presentation/widgets/` and use `const` constructors wherever possible.
- **Brand Color Palette**: Do not invent arbitrary colors. Stick to the established palette:
  - Backgrounds / Surfaces: `Color(0xFFF6FAFF)`, `Color(0xFFDDEBFF)`, `Color(0xFFF5F7FA)`
  - Primary Blues / Accents: `Color(0xFF8BB3D6)`, `Color(0xFF2E4E69)`, `Color(0xFF2F5D7E)`, `Color(0xFF315C84)`
  - Headings / Dark Text: `Color(0xFF0F3559)`, `Color(0xFF17324B)`
- **8dp Grid & Material 3 Polish**: Use multiples of `8.0` (`8.0`, `16.0`, `24.0`, `32.0`) for padding/spacers (`SizedBox`), `BorderRadius.circular(16.0)` for cards, soft low-opacity `BoxShadow`s, and `Shimmer` / `Skeleton` widgets (`lib/core/widgets/skeleton.dart`) instead of raw spinners for content loading.

---

## 5. Verification & Fast Feedback Rules

- **NEVER run `flutter test`**.
- **Targeted Analysis Only**: To verify edits quickly, run `dart analyze <path/to/modified_file.dart>` from `apps/easy_bake_mobile`.
- **Full Project Analysis**: Only run `flutter analyze` when making large, cross-cutting architectural changes across many files.
