# Finora AI — Database Schema Documentation

This document describes the PostgreSQL database architecture, schema design, security model, and table relationships for **Finora AI** built on Supabase.

---

## 1. Security Architecture & RLS Model

Finora AI implements Row-Level Security (RLS) across all business data tables.

```text
auth.users (authenticated user)
    └── businesses (owner_id = auth.uid())
            ├── transactions (business_id)
            ├── financial_metrics (business_id)
            ├── forecasts (business_id)
            ├── alerts (business_id)
            ├── ai_conversations (business_id & user_id = auth.uid())
            └── simulations (business_id & user_id = auth.uid())
```

### Security Principles:
- **No Direct Cross-Tenant Access**: A business owner can only read or mutate records associated with businesses they own (`businesses.owner_id = auth.uid()`).
- **PostgreSQL Helper Function**: `public.is_business_owner(b_id)` verifies business ownership in sub-table policies cleanly and securely.
- **Service Role Isolation**: Flutter client applications consume only publishable keys (`SUPABASE_PUBLISHABLE_KEY`). Server-side Edge Functions handle Qoder AI integrations securely without exposing bearer tokens or service keys.

---

## 2. Table Definitions & Specifications

### 2.1 `businesses`
Stores business profile parameters and ownership data.

| Field | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PRIMARY KEY`, `DEFAULT gen_random_uuid()` | Unique business identifier |
| `owner_id` | `UUID` | `NOT NULL`, `REFERENCES auth.users(id) ON DELETE CASCADE` | Business owner user ID |
| `name` | `TEXT` | `NOT NULL` | Registered business name |
| `industry` | `TEXT` | Optional | Business industry sector |
| `country` | `TEXT` | Optional | Operating country |
| `currency` | `TEXT` | `DEFAULT 'USD'` | Base reporting currency |
| `fiscal_year_start_month` | `INTEGER` | `CHECK (1..12)` | Fiscal year start month |
| `starting_cash` | `NUMERIC(15, 2)` | `DEFAULT 0.00` | Initial cash balance |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT now()` | Record creation timestamp |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT now()` | Auto-updated timestamp |

---

### 2.2 `transactions`
Authoritative ledger storing normalized income, expense, and transfer records.

| Field | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PRIMARY KEY`, `DEFAULT gen_random_uuid()` | Transaction identifier |
| `business_id` | `UUID` | `NOT NULL`, `REFERENCES public.businesses(id)` | Parent business reference |
| `transaction_date` | `TIMESTAMPTZ` | `NOT NULL` | Date/time of transaction |
| `transaction_type` | `TEXT` | `NOT NULL`, `CHECK ('income', 'expense', 'transfer')` | Financial classification |
| `category` | `TEXT` | `NOT NULL` | Top-level financial category |
| `subcategory` | `TEXT` | Optional | Granular classification |
| `amount` | `NUMERIC(15, 2)` | `NOT NULL`, `CHECK (amount > 0)` | Positive monetary amount |
| `currency` | `TEXT` | `DEFAULT 'USD'` | Transaction currency |
| `description` | `TEXT` | Optional | User/bank statement line memo |
| `merchant_name` | `TEXT` | Optional | Vendor or merchant |
| `customer_name` | `TEXT` | Optional | Customer name (for income) |
| `supplier_name` | `TEXT` | Optional | Supplier name (for expense) |
| `payment_status` | `TEXT` | `NOT NULL`, `CHECK ('paid', 'pending', 'overdue', 'unknown')` | Payment status |
| `source` | `TEXT` | `NOT NULL`, `CHECK ('csv', 'sms', 'manual')` | Provenance source |
| `external_reference` | `TEXT` | Optional | External ID / CSV reference |
| `raw_text` | `TEXT` | Optional | Raw SMS text or original CSV string |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT now()` | Record creation timestamp |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT now()` | Auto-updated timestamp |

---

### 2.3 `financial_metrics`
Calculated summary metrics produced deterministically by the Financial Engine.

| Field | Type | Description |
|---|---|---|
| `id` | `UUID` | Primary key |
| `business_id` | `UUID` | Parent business reference |
| `period_start` / `period_end` | `DATE` | Metric period window |
| `revenue` / `expenses` / `profit` | `NUMERIC(15, 2)` | Aggregated financial totals |
| `profit_margin` | `NUMERIC(7, 4)` | Profitability ratio |
| `cash_inflow` / `cash_outflow` / `net_cash_flow` | `NUMERIC(15, 2)` | Cash flow statement metrics |
| `debt` / `receivables` / `payables` | `NUMERIC(15, 2)` | Balance sheet indicator metrics |
| `revenue_growth` / `expense_growth` | `NUMERIC(7, 4)` | Period-over-period growth rates |
| `health_score` | `NUMERIC(5, 2)` | Composite financial health score (`0..100`) |

---

### 2.4 `forecasts`
Statistical predictions produced by the Prediction Engine.

| Field | Type | Description |
|---|---|---|
| `id` | `UUID` | Primary key |
| `business_id` | `UUID` | Parent business reference |
| `forecast_type` | `TEXT` | `revenue`, `expenses`, `cash_flow`, `cash_balance` |
| `forecast_date` | `DATE` | Future target date |
| `predicted_value` | `NUMERIC(15, 2)` | Expected metric value |
| `lower_bound` / `upper_bound` | `NUMERIC(15, 2)` | Confidence interval bounds |
| `confidence` | `NUMERIC(5, 4)` | Statistical confidence (`0.0..1.0`) |
| `model_version` | `TEXT` | Algorithm / model version |

---

### 2.5 `alerts`
Automated risk, opportunity, and informational warnings.

| Field | Type | Description |
|---|---|---|
| `id` | `UUID` | Primary key |
| `business_id` | `UUID` | Parent business reference |
| `alert_type` | `TEXT` | `risk`, `opportunity`, `information` |
| `severity` | `TEXT` | `critical`, `high`, `medium`, `low` |
| `title` / `description` | `TEXT` | Human-readable title & summary |
| `recommendation` | `TEXT` | Practical action advice |
| `metric_name` / `metric_value` / `threshold_value` | `NUMERIC / TEXT` | Triggering metric details |
| `is_read` | `BOOLEAN` | Read status |

---

### 2.6 `ai_conversations`
History of interactive Qoder AI CFO chat sessions.

| Field | Type | Description |
|---|---|---|
| `id` | `UUID` | Primary key |
| `business_id` / `user_id` | `UUID` | Business and user context |
| `session_id` | `UUID` | Dialogue session grouping ID |
| `role` | `TEXT` | `user`, `assistant`, `system` |
| `message` | `TEXT` | Chat turn message content |

---

### 2.7 `simulations`
What-If scenario modeling and financial projection records.

| Field | Type | Description |
|---|---|---|
| `id` | `UUID` | Primary key |
| `business_id` / `user_id` | `UUID` | Business and user context |
| `name` | `TEXT` | Scenario name |
| `assumptions` | `JSONB` | Input parameters (e.g. price change, hiring) |
| `baseline_metrics` | `JSONB` | Starting financial metric state |
| `projected_metrics` | `JSONB` | Simulated metric output |
| `ai_analysis` | `TEXT` | Narrative analysis generated by Qoder AI |

---

## 3. Future Stage Integration Mapping

1. **Stage 1 (Current)**: Supabase database foundation, tables, indexes, RLS policies, and Dart domain models.
2. **Stage 2**: Authentication flow & business profile setup (`businesses`).
3. **Stage 3**: CSV Import engine & manual transaction entry (`transactions`).
4. **Stage 4**: Deterministic Financial Engine (`financial_metrics`).
5. **Stage 5**: Prediction engine & automated risk detection (`forecasts`, `alerts`).
6. **Stage 6**: Qoder AI CFO Edge Function & chat integration (`ai_conversations`).
7. **Stage 7**: What-If financial simulator (`simulations`) & optional Android SMS ingestion.
