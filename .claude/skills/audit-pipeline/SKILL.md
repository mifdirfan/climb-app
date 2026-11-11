---
name: audit-pipeline
description: Audits Flutter and Supabase code against ClimbMY's mandatory 4-Tier Feature Pipeline. Triggers when checking PRs, reviewing code changes, or enforcing architecture boundaries.
---

# Skill: Universal Code Documentation & Change Audit

## Description
Standardizes how the agent documents newly written or modified source code and maintains an indexed changelog audit trail. This skill ensures all code modifications include language-native docstrings with data lineage (source/sink) and generates a structured audit report with line numbers, verification commands, and rollback instructions for human review.

---

## Trigger Conditions
Execute this skill whenever:
- The user requests a new feature, bug fix, or refactor across any codebase.
- The user explicitly calls `/audit`, `/document`, or requests a review log of recent changes.
- Any file containing logic, schema, or configuration is added or modified.

---

## Workflow Instructions

### Phase 1: In-File Code Annotation
Before completing changes to any source file, add or update docstrings and inline comments according to the following conventions:

1. **Auto-Detect Native Docstring Convention**:
   - **Python**: Google-style or Sphinx docstrings (`"""..."""`)
   - **TypeScript / JavaScript**: JSDoc/TSDoc (`/** ... */`)
   - **Go**: GoDoc comments (`// FunctionName ...`)
   - **Java / C#**: Javadoc / XML Documentation (`/** ... */` or `/// <summary>`)
   - **Rust**: Outer doc comments (`/// ...`)

2. **Mandatory Comment Metadata**:
   Every new or modified function/method must include:
   - **Intent & Rationale ("Why")**: One to two sentences explaining *why* this logic exists or why a specific architectural pattern was selected over alternatives.
   - **Data Flow Lineage**:
     - `@source`: Origin of input data (e.g., `HTTP POST /users`, `PostgreSQL:orders`, `Redis:session_cache`, `ENV:PORT`).
     - `@sink`: Destination where output or side-effects are transmitted (e.g., `PostgreSQL:orders`, `Kafka:order_created_events`, `Response JSON`).
   - **Side Effects**: Disk I/O, external network calls, mutated global/shared memory, or cache invalidations.
   - **Breaking Change Warning**: Marked explicitly with `@breaking` if API contracts, schemas, or function signatures changed.

---

# Change Audit: [Brief Task Title]

- **Date / Time:** YYYY-MM-DD HH:MM
- **Trigger Prompt:** "[Exact or summarized user prompt]"
- **Primary Goal:** [1-2 sentences on what was accomplished]

---

## 1. Index of Modified Files

| File Path | Lines Affected | Action | Change Summary |
| :--- | :--- | :--- | :--- |
| `src/services/auth.py` | L42-L78 | Modified | Added OAuth token refresh and validation logic |
| `src/models/user.py` | L12-L28 | Modified | Added `is_verified` column to schema definition |
| `src/utils/crypto.py` | L1-L45 | Added | Helper module for RSA key verification |

---

## 2. Data Flow & Dependencies

- **Data Sources:** [External APIs, databases, message queues touched]
- **Data Sinks:** [Databases written to, webhooks triggered, caches updated]
- **New Environment Variables:**
  - `KEY_NAME`: Description of purpose and default value (or `None`).
- **New Third-Party Dependencies:**
  - `package_name@version`: Why it was added (or `None`).

---

## 4-Tier Enforcement Checklist

### Tier 1 — Database Layer (PostgreSQL / Supabase)
- [ ] Primary keys use `id uuid default gen_random_uuid() primary key`.
- [ ] Table names and columns use `snake_case`.
- [ ] Timestamps use `created_at timestamptz default now()`.
- [ ] Explicit RLS is enabled (`alter table ... enable row level security;`).
- [ ] Foreign keys have explicit B-tree indexes (`create index on <table> (<fk_col>);`).
- [ ] Schema reloads end with `notify pgrst, 'reload schema';`.

### Tier 2 — Repository / Service Layer (Dart)
- [ ] All `Supabase.instance.client` calls are strictly contained inside `lib/repositories/`.
- [ ] Every query catches `PostgrestException` and `AuthException` explicitly.
- [ ] Returns typed immutable DTO models or domain entities.
- [ ] Logs errors via `debugPrint('--> [<FEATURE>:REPO] ...')`.

### Tier 3 — State Management Layer (Riverpod)
- [ ] State logic is isolated in `AsyncNotifier` or `Notifier` classes in `lib/providers/`.
- [ ] State transitions properly use `AsyncLoading`, `AsyncData`, and `AsyncError`.
- [ ] Stream providers auto-dispose or re-evaluate upon auth state changes (`ref.invalidate()`).
- [ ] Logs state transitions via `debugPrint('--> [<FEATURE>:STATE] ...')`.

### Tier 4 — UI Layer (Flutter)
- [ ] NO direct `Supabase.instance.client` calls or SQL table names in widgets.
- [ ] Consumes state via `ConsumerWidget` or `ConsumerStatefulWidget`.
- [ ] Uses `.when()` or `state.isLoading` for state rendering.
- [ ] Styling strictly pulls from `Theme.of(context)` or `AppTheme` design tokens (`AppColors`, `AppRadius`).
- [ ] Flat surfaces only (NO multi-color background gradients).
- [ ] Uses `debugPrint('--> [<FEATURE>:UI] ...')` instead of `print()`.

## Output Report Format
Always format the audit result as:
1. **Pipeline Compliance Score:** PASS / FAIL
2. **Violations List:** File path, line number, tier violation, and concrete fix snippet.
3. **Refactored Code:** Clean replacement code for any failing component.