# Finora AI — Project Guidance

## Product Purpose

Finora AI is an AI-powered financial health advisor for small and medium-sized businesses. It will help business owners import transactions, understand their financial position, identify risks and opportunities, forecast trends, run financial simulations, and ask an AI CFO for practical guidance.

Android is the primary target. Keep Flutter code mobile-first and responsive, and avoid platform-specific decisions that unnecessarily prevent later iOS or web support.

## Current Stage and Scope

This repository currently contains only the default Flutter scaffold. Do not build mock financial features, implement Android SMS ingestion, integrate the Qoder AI API, add database tables, or add packages unless a later task explicitly requires them.

Preserve working code and make narrowly scoped changes. Inspect the affected code and configuration before changing an existing implementation.

## Technology Decisions

- Flutter and Dart for the client application.
- Material 3 for the interface.
- Supabase for PostgreSQL, Auth, Storage, and Edge Functions.
- Qoder Cloud Agents API is the only approved AI CFO provider.
- Do not introduce OpenAI, Gemini, Claude, or another AI provider without explicit approval.
- Prefer simple, maintainable architecture over speculative abstractions or unnecessary dependencies.

## Required Logical Architecture

Keep dependencies flowing in this direction:

```text
Flutter UI
  -> Application / State Layer
  -> Domain / Business Logic
  -> Data Layer
  -> Supabase
```

- UI code renders state and forwards user intent; it must not embed financial calculations, database queries, or secrets.
- The application/state layer coordinates use cases and exposes presentation-friendly state.
- The domain layer contains business rules, financial models, use cases, and interfaces needed by the application layer.
- The data layer implements repositories and manages Supabase, storage, imports, and server calls.
- Supabase-specific types and APIs must not leak into UI widgets or core financial calculations.

## Intelligence Boundaries

### 1. Financial Engine

Implement deterministic, testable calculations in application or backend code. The engine owns calculations such as:

- revenue, expenses, profit, and profit margin;
- cash flow and growth rates;
- debt ratios;
- receivables and payables; and
- other defined financial metrics.

Do not delegate basic arithmetic or authoritative metric calculation to an AI model.

### 2. Prediction and Risk Engine

Keep forecasting and detection logic distinct from the financial engine and Qoder AI layer. It will own:

- revenue, expense, and cash-flow trend analysis;
- cash-flow and revenue forecasts;
- anomaly detection;
- financial-distress indicators; and
- opportunity detection.

Predictions should be reproducible from recorded transactions, assumptions, and algorithm versions.

### 3. Qoder AI CFO

The Qoder AI layer explains deterministic results. It may answer questions, explain risks and opportunities, prioritize recommendations, create action plans, and interpret forecasts or simulations. It must consume prepared, authorized business context and must not become the source of truth for financial arithmetic.

## Recommended Flutter Structure

Introduce this structure incrementally when Stage 1 begins; do not create empty directories before they are needed.

```text
lib/
  app/
    app.dart
    bootstrap.dart
    router/
    theme/
  core/
    config/
    errors/
    utilities/
  features/
    authentication/
      application/
      domain/
      data/
      presentation/
    businesses/
    transactions/
    financial_health/
    forecasts/
    alerts/
    simulations/
    ai_cfo/
  shared/
    widgets/
```

Within each feature:

- `domain/` contains business entities, value objects, repository contracts, and use cases.
- `application/` contains state controllers/notifiers and orchestration of domain use cases.
- `data/` contains DTOs, Supabase data sources, import parsers, and repository implementations.
- `presentation/` contains pages, widgets, and view models as needed.

Place deterministic financial calculations in a dedicated `financial_health/domain/` engine or a shared domain module only when multiple features genuinely need it. Keep platform-specific integrations behind feature-level interfaces.

## Planned Data Model

Future Supabase schema work will likely include these tables:

- `businesses`
- `transactions`
- `financial_metrics`
- `alerts`
- `ai_conversations`
- `forecasts`
- `simulations`

Do not create these tables until schema requirements, ownership relationships, and access patterns have been defined. When added, migrations must be version-controlled under `supabase/migrations/`.

## Supabase and Security Rules

- Never expose a Supabase service-role key in Flutter, source control, logs, or client configuration.
- Never embed Qoder Cloud Agent API Bearer tokens in Flutter.
- Store sensitive server-side credentials in Supabase Edge Function secrets or another approved server-side secret store.
- The Flutter client may use only the Supabase project URL and publishable/anon key through non-committed environment configuration.
- Flutter reads `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` through `--dart-define-from-file=config/supabase.local.json`. Keep that local file ignored and commit only `config/supabase.example.json`.
- Route requests that require the Qoder token through Supabase Edge Functions. Validate the caller and business authorization before forwarding context to Qoder.
- Enable Row Level Security on every business-data table before exposing it to clients.
- Design RLS policies around authenticated user membership in a business; a user must not read or mutate another business's financial data.
- Validate CSV data on import, retain import provenance, and avoid logging raw sensitive transaction data.
- Keep production, staging, and local Supabase configuration separate.

## Authentication Rules

Use Supabase Auth for user identity. Model business ownership or membership separately from identity so the data model can support multiple users per business. Do not make authorization decisions solely in Flutter; enforce them through RLS and Edge Functions.

## Future Integration Rules

### CSV Imports

CSV import functionality must normalize input into a validated transaction model, record source/import metadata, and surface row-level validation errors. Do not assume one bank-specific CSV schema.

### Android SMS

Do not implement SMS access until explicitly approved. Any future SMS integration must be Android-specific, permission-minimized, transparent to the user, and isolated behind an interface so the financial engine receives normalized transactions rather than raw SMS messages.

### AI CFO

Do not implement the Qoder Cloud Agents API until explicitly approved. When implemented, invoke it only from authenticated server-side code, send the minimum necessary authorized context, and retain auditable request/response metadata without recording secrets.

## Code Quality Rules

- Use null-safe Dart, clear names, small focused classes, and immutable domain models where practical.
- Keep widgets focused on presentation and avoid business logic in `build` methods.
- Prefer explicit error states and typed failures over swallowed exceptions.
- Add unit tests for financial calculations, risk/prediction behavior, CSV normalization, and repository logic as those modules are added.
- Add integration tests for Supabase authorization paths and Edge Functions when they are introduced.
- Run formatting and relevant tests after modifying Dart code.
- Do not add a dependency until the implementation task has established a concrete need and evaluated the Flutter SDK alternative.

## Delivery Sequence

1. Establish Supabase project configuration, non-committed environment handling, and authentication foundation.
2. Define and migrate the minimum business ownership and transaction schema with RLS.
3. Implement CSV import, validation, and secure transaction persistence.
4. Implement the deterministic financial engine with test coverage.
5. Add risk/prediction logic, alerts, and forecasts.
6. Add Qoder AI CFO through secured Supabase Edge Functions.
7. Add simulations and, only after explicit approval, Android SMS ingestion.
