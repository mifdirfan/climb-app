# ClimbMY — Master AI Agent Rules & Engineering Standards 🧗‍♂️🇲🇾

This document contains the mandatory rules, multi-model execution guidelines, architectural constraints, and workflow commands for all AI agents working on the ClimbMY codebase.

---

## 1. Multi-Model Agent Task Matrix

To optimize quality, performance, and token usage, tasks must be routed according to model capabilities:

| Model Tier | Primary Tasks & Responsibilities |
| :--- | :--- |
| **Claude Haiku**<br>*(Search & Scaffolding)* | • Searching files, grepping codebase, mapping directory structures.<br>• Generating simple DTO boilerplate, serialization (`fromJson`/`toJson`), and raw utility getters.<br>• Formatting imports, linting fixes, and basic error logs. |
| **Claude Sonnet**<br>*(Planning & Building)* | • Feature planning, database schema design (PostgreSQL/Supabase migrations, RLS policies).<br>• Building Tier 2 Data Repositories and Tier 3 Riverpod State Notifiers.<br>• End-to-end feature pipelines, business logic, and API route integration. |
| **Claude Opus**<br>*(UI/UX & Testing)* | • Pixel-perfect Material 3 Flutter widget generation adhering to `AppTheme`.<br>• Fine-tuning UI layouts, custom animations, canvas painting, and complex gestures.<br>• Generating full unit, repository, Riverpod container, and widget integration tests (`flutter test`). |

---

## 2. Mandatory 4-Tier Feature Pipeline

All new features, bug fixes, and data mutations **MUST** follow this vertical 4-Tier pipeline sequence. **NEVER skip tiers or call Supabase directly from UI widgets.**

```text
[Tier 1: Supabase DB] ──► [Tier 2: Repository] ──► [Tier 3: Riverpod State] ──► [Tier 4: UI Widget]
```

### Tier 1 — Database Layer (PostgreSQL / Supabase)
- All tables and columns must use `snake_case`.
- Primary keys must use `id uuid default gen_random_uuid() primary key`.
- Timestamps must default to `created_at timestamptz default now()`.
- Enable explicit Row Level Security: `alter table public.<table_name> enable row level security;`.
- Add B-tree indexes for all foreign key columns: `create index idx_<table_name>_<col> on public.<table_name>(<col>);`.
- End all migration scripts with: `notify pgrst, 'reload schema';`.

### Tier 2 — Repository / Service Layer (`lib/repositories/`)
- Isolate all `Supabase.instance.client` calls inside repository classes.
- Explicitly catch and handle `PostgrestException` and `AuthException`.
- Parse raw JSON responses into typed, immutable DTO models (`lib/models/`).
- Log database calls: `debugPrint('--> [<FEATURE>:REPO] <Action description>');`.

### Tier 3 — State Management Layer (`lib/providers/`)
- Manage domain logic via Riverpod `Notifier`, `AsyncNotifier`, `FutureProvider`, or `StateProvider`.
- Handle lifecycle state transitions cleanly (`AsyncLoading`, `AsyncData`, `AsyncError`).
- Invalidate dependent streams on user auth state changes using `ref.invalidate()`.
- Log state mutations: `debugPrint('--> [<FEATURE>:STATE] <Action description>');`.

### Tier 4 — UI Layer (`lib/screens/` & `lib/widgets/`)
- **STRICT RULE:** Zero direct `Supabase.instance.client` calls inside UI files.
- UI components must inherit from `ConsumerWidget` or `ConsumerStatefulWidget`.
- Safely resolve state using `.when()` or `state.isLoading`.
- Log user interactions: `debugPrint('--> [<FEATURE>:UI] <Action description>');`.

---

## 3. UI/UX & Design Tokens Rules

- **Brand Colors:** Centralized around `#CFFF74` Electric Lime (`AppColors.primary`). High-contrast dark text/icon on filled buttons uses `AppColors.onPrimary` (`#11140E`).
- **Surface & Borders:** Flat solid dark cards (`AppColors.surface` `#1A1A1A`) with 1.0px solid borders (`AppColors.borderSubtle` `#242424`). **NO multi-color background gradients.**
- **Typography:** Headings/display fonts use `Space Grotesk`. Body, technical metrics, and metadata use `JetBrains Mono` via `AppTextStyles`.
- **Dynamic Gym Grading:** Indoor tally components (`IndoorTallyCounter`) must dynamically render color tags and labels derived from the selected gym's `grading_scale` JSON array (`hex`, `label`, `v_min`, `v_max`).
- **Video Link Validation:** All user-submitted video beta links in outdoor forms must pass URL regex validation supporting YouTube (`youtube.com`, `youtu.be`), Instagram Reels (`instagram.com`), and TikTok (`tiktok.com`, `vm.tiktok.com`).

---

## 4. Code Quality & Diagnostic Standards

- **No Raw Prints:** Never use `print()`. Use Flutter's `debugPrint()` with structured feature tags:
  ```dart
  debugPrint('--> [<FEATURE_TAG>:<TIER>] <Descriptive action/payload message>');
  ```
- **File Paths:** Keep project structure flat and feature-oriented under `lib/`.
- **Quality Gates:** Always run `flutter analyze` and `flutter test` to verify code health before completing tasks.

---

## 5. Available Agent Skills (`.claude/skills/`)

Invoke or reference these custom commands during feature development:

- `/audit-pipeline`: Scans code changes to enforce 4-Tier architectural boundaries and prevent UI-to-DB leakages.
- `/generate-migration`: Creates production-grade Supabase SQL migration files with UUIDs, RLS, indexes, and schema reload triggers.
- `/build-widget`: Builds theme-compliant Flutter UI components adhering to ClimbMY Material 3 design tokens.
- `/test-generator`: Automatically generates unit, repository, Riverpod notifier, and widget integration tests.

---

## 6. Useful Terminal Commands

```bash
# Quality Gates
flutter analyze
flutter test

# Code Generation / Dependencies
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# Local Supabase Operations
supabase status
supabase db reset
supabase migration new <migration_name>
```