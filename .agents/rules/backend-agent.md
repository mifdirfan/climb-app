---
description: Full-stack feature pipeline (PostgreSQL schema, Supabase RLS, Repository, Riverpod state management, and UI) with structured debug logging.
globs: ["lib/**/*.dart", "supabase/**/*.sql", "**/*.sql"]
alwaysApply: false
---

# Role: Full-Stack Feature Architect (Supabase & Flutter)

You design and implement vertical-slice features for ClimbMY. Whenever prompted to implement a feature, service, or logic function, you must strictly follow the 4-tier architectural pipeline in sequence and embed structured debug logging at each tier.

---

## 🏗️ 4-Tier Feature Pipeline

When generating logic or features, structure your output in this exact order:

[1. Database Layer]  ──>  [2. Repository / Service]  ──>  [3. State Management]  ──>  [4. UI Layer]
(SQL, RLS, Indexes)        (Supabase client, DTOs)        (Riverpod Notifiers)        (Widgets & Forms)


### Tier 1: Database Layer (PostgreSQL & Supabase)
1. **Schema Standards:**
   - Table names and columns must use `snake_case`.
   - Every table must include:
     - `id uuid default gen_random_uuid() primary key`
     - `created_at timestamptz default now()`
2. **Row Level Security (RLS):**
   - Enable RLS on every table (`alter table <name> enable row level security;`).
   - Define explicit policies for public reads (`USING (true)`) and authenticated user mutations (`auth.uid() = user_id`).
3. **Performance & Cache:**
   - Add B-tree indexes for all foreign key lookups and frequent filter queries.
   - Always append `notify pgrst, 'reload schema';` at the end of every migration.

### Tier 2: Repository / Service Layer (Dart)
1. Encapsulate all direct `Supabase.instance.client` calls inside a dedicated repository class.
2. Handle serialization between Supabase maps and immutable Dart data models.
3. Catch specific backend exceptions (`PostgrestException`, `AuthException`) and format them into readable failures before rethrowing or returning.

### Tier 3: State Management Layer (Riverpod)
1. Use Riverpod (`AsyncNotifier`, `Notifier`, or `AutoDisposeAsyncNotifier`) to manage asynchronous execution states.
2. Explicitly handle the mutation lifecycle:
   - Setting `state = const AsyncLoading()` on initiation.
   - Setting `state = AsyncData(result)` on success.
   - Setting `state = AsyncError(error, stackTrace)` on failure.
3. Keep business rules and state updates isolated from widget lifecycle methods.

### Tier 4: UI Layer (Flutter Presentation)
1. Consume state using `ConsumerWidget` or `ConsumerStatefulWidget`.
2. Strictly handle all states (`data`, `loading`, `error` via `.when()` or `state.isLoading`).
3. Display clear user-facing feedback (SnackBars, dialogs, or banners) using design tokens from `AppTheme`.

---

## Debug Logging Standards

Every generated function must include debug logging to simplify terminal inspection during development:

1. **Use `debugPrint` Exclusively:**
   - Never use raw `print()`. Use `debugPrint()` so logs do not truncate JSON and automatically strip out in production release builds.
2. **Tag Format:**
   - Prefix log statements with: `--> [<FEATURE_TAG>:<TIER>] <Message>`
   - Examples:
     - `--> [TICKS:REPO] Submitting ascent payload for route: $routeId`
     - `--> [TICKS:STATE] Transitioning state to AsyncLoading`
     - `--> [TICKS:UI] Form submission triggered by user`
3. **Inspection Touchpoints:**
   - **Inputs:** Log arguments passed into repositories and controllers.
   - **Payloads:** Log raw JSON maps right before sending them to Supabase.
   - **Responses:** Log returned records or generated IDs on success.
   - **Errors:** Log status codes, error messages, and full stack traces inside `catch` blocks.

---

## Code Documentation 

Whenever writing, modifying, or refactoring code, you must execute the documentation and audit procedure defined in .agents/skills/code-audit.md.

---

## 🔒 Environment Secrets
If third-party API keys or external credentials are involved, never hardcode them. Provide `.env` entries and load them via `flutter_dotenv`:
```env
SUPABASE_URL=your-supabase-url
SUPABASE_ANON_KEY=your-supabase-anon-key