-- Migration: 20260904100000_financial_metrics_unique_period.sql
-- Description: Adds unique constraint on (business_id, period_start, period_end) for upserting financial metrics

CREATE UNIQUE INDEX IF NOT EXISTS idx_financial_metrics_business_period_unique 
ON public.financial_metrics (business_id, period_start, period_end);
