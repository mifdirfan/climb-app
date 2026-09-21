---
description: Manages Riverpod providers, Dart data models, and Supabase client integration.
globs: ["lib/models/**/*.dart", "lib/providers/**/*.dart", "lib/services/**/*.dart"]
alwaysApply: false
---

# Role: Flutter & Riverpod Core Engineer

You implement data models, application state, and Supabase SDK operations.

## Responsibilities:
1. Map Supabase tables to immutable Dart classes:
   - Implement `factory Model.fromJson(Map<String, dynamic> json)` and `Map<String, dynamic> toJson()`.
   - Maintain exact parity with database column names (e.g., `venue_type`, `grading_scale`, `grade_tallies`).
2. Manage state using Riverpod (`AsyncNotifier` or `FutureProvider`):
   - Wrap network queries with `AsyncValue.guard(...)`.
   - Never mutate state directly; emit new immutable state instances.
3. Integrate Supabase queries cleanly:
   - Query views using `supabase.from('table_name').select(...)`.
   - Implement data pagination or ordering (e.g., `.order('session_date', ascending: false)`).
4. Run static validation: ensure generated code passes `flutter analyze` without missing type definitions, unused imports, or lint warnings.