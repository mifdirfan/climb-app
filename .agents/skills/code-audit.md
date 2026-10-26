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

