-- Migration: 20260904000000_stage1_foundation.sql
-- Description: Stage 1 — Core Database Schema & Row-Level Security Policies for Finora AI

-- Helper Trigger Function for updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 1. BUSINESSES TABLE
CREATE TABLE IF NOT EXISTS public.businesses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    industry TEXT,
    country TEXT,
    currency TEXT DEFAULT 'USD',
    fiscal_year_start_month INTEGER CHECK (fiscal_year_start_month BETWEEN 1 AND 12),
    starting_cash NUMERIC(15, 2) DEFAULT 0.00,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE OR REPLACE TRIGGER update_businesses_updated_at
BEFORE UPDATE ON public.businesses
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE INDEX IF NOT EXISTS idx_businesses_owner_id ON public.businesses(owner_id);

-- 2. TRANSACTIONS TABLE
CREATE TABLE IF NOT EXISTS public.transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    transaction_date TIMESTAMPTZ NOT NULL,
    transaction_type TEXT NOT NULL CHECK (transaction_type IN ('income', 'expense', 'transfer')),
    category TEXT NOT NULL,
    subcategory TEXT,
    amount NUMERIC(15, 2) NOT NULL CHECK (amount > 0),
    currency TEXT DEFAULT 'USD',
    description TEXT,
    merchant_name TEXT,
    customer_name TEXT,
    supplier_name TEXT,
    payment_status TEXT NOT NULL DEFAULT 'unknown' CHECK (payment_status IN ('paid', 'pending', 'overdue', 'unknown')),
    source TEXT NOT NULL DEFAULT 'manual' CHECK (source IN ('csv', 'sms', 'manual')),
    external_reference TEXT,
    raw_text TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE OR REPLACE TRIGGER update_transactions_updated_at
BEFORE UPDATE ON public.transactions
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE INDEX IF NOT EXISTS idx_transactions_business_id ON public.transactions(business_id);
CREATE INDEX IF NOT EXISTS idx_transactions_transaction_date ON public.transactions(transaction_date);
CREATE INDEX IF NOT EXISTS idx_transactions_business_date ON public.transactions(business_id, transaction_date DESC);

-- 3. FINANCIAL METRICS TABLE
CREATE TABLE IF NOT EXISTS public.financial_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    revenue NUMERIC(15, 2) DEFAULT 0.00,
    expenses NUMERIC(15, 2) DEFAULT 0.00,
    profit NUMERIC(15, 2) DEFAULT 0.00,
    profit_margin NUMERIC(7, 4) DEFAULT 0.0000,
    cash_inflow NUMERIC(15, 2) DEFAULT 0.00,
    cash_outflow NUMERIC(15, 2) DEFAULT 0.00,
    net_cash_flow NUMERIC(15, 2) DEFAULT 0.00,
    debt NUMERIC(15, 2) DEFAULT 0.00,
    receivables NUMERIC(15, 2) DEFAULT 0.00,
    payables NUMERIC(15, 2) DEFAULT 0.00,
    revenue_growth NUMERIC(7, 4) DEFAULT 0.0000,
    expense_growth NUMERIC(7, 4) DEFAULT 0.0000,
    health_score NUMERIC(5, 2) CHECK (health_score BETWEEN 0 AND 100),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE OR REPLACE TRIGGER update_financial_metrics_updated_at
BEFORE UPDATE ON public.financial_metrics
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE INDEX IF NOT EXISTS idx_financial_metrics_business_period ON public.financial_metrics(business_id, period_start, period_end);

-- 4. FORECASTS TABLE
CREATE TABLE IF NOT EXISTS public.forecasts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    forecast_type TEXT NOT NULL CHECK (forecast_type IN ('revenue', 'expenses', 'cash_flow', 'cash_balance')),
    forecast_date DATE NOT NULL,
    predicted_value NUMERIC(15, 2) NOT NULL,
    lower_bound NUMERIC(15, 2),
    upper_bound NUMERIC(15, 2),
    confidence NUMERIC(5, 4) CHECK (confidence BETWEEN 0 AND 1),
    model_version TEXT NOT NULL DEFAULT '1.0.0',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_forecasts_business_type_date ON public.forecasts(business_id, forecast_type, forecast_date);

-- 5. ALERTS TABLE
CREATE TABLE IF NOT EXISTS public.alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    alert_type TEXT NOT NULL CHECK (alert_type IN ('risk', 'opportunity', 'information')),
    severity TEXT NOT NULL CHECK (severity IN ('critical', 'high', 'medium', 'low')),
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    recommendation TEXT,
    metric_name TEXT,
    metric_value NUMERIC(15, 2),
    threshold_value NUMERIC(15, 2),
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_alerts_business_read ON public.alerts(business_id, is_read);

-- 6. AI CONVERSATIONS TABLE
CREATE TABLE IF NOT EXISTS public.ai_conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    session_id UUID NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    message TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ai_conversations_session ON public.ai_conversations(business_id, session_id, created_at);

-- 7. SIMULATIONS TABLE
CREATE TABLE IF NOT EXISTS public.simulations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    assumptions JSONB NOT NULL DEFAULT '{}'::jsonb,
    baseline_metrics JSONB NOT NULL DEFAULT '{}'::jsonb,
    projected_metrics JSONB NOT NULL DEFAULT '{}'::jsonb,
    ai_analysis TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_simulations_business ON public.simulations(business_id, created_at DESC);

-- ROW LEVEL SECURITY (RLS) POLICIES

-- Enable RLS on all tables
ALTER TABLE public.businesses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.financial_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.forecasts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.simulations ENABLE ROW LEVEL SECURITY;

-- Helper security function to check if current auth user owns a business
CREATE OR REPLACE FUNCTION public.is_business_owner(b_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.businesses
        WHERE id = b_id AND owner_id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Policies for businesses
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'businesses_owner_all' AND tablename = 'businesses') THEN
        CREATE POLICY businesses_owner_all ON public.businesses
            FOR ALL
            USING (owner_id = auth.uid())
            WITH CHECK (owner_id = auth.uid());
    END IF;
END $$;

-- Policies for transactions
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'transactions_owner_all' AND tablename = 'transactions') THEN
        CREATE POLICY transactions_owner_all ON public.transactions
            FOR ALL
            USING (public.is_business_owner(business_id))
            WITH CHECK (public.is_business_owner(business_id));
    END IF;
END $$;

-- Policies for financial_metrics
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'financial_metrics_owner_all' AND tablename = 'financial_metrics') THEN
        CREATE POLICY financial_metrics_owner_all ON public.financial_metrics
            FOR ALL
            USING (public.is_business_owner(business_id))
            WITH CHECK (public.is_business_owner(business_id));
    END IF;
END $$;

-- Policies for forecasts
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'forecasts_owner_all' AND tablename = 'forecasts') THEN
        CREATE POLICY forecasts_owner_all ON public.forecasts
            FOR ALL
            USING (public.is_business_owner(business_id))
            WITH CHECK (public.is_business_owner(business_id));
    END IF;
END $$;

-- Policies for alerts
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'alerts_owner_all' AND tablename = 'alerts') THEN
        CREATE POLICY alerts_owner_all ON public.alerts
            FOR ALL
            USING (public.is_business_owner(business_id))
            WITH CHECK (public.is_business_owner(business_id));
    END IF;
END $$;

-- Policies for ai_conversations
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'ai_conversations_owner_all' AND tablename = 'ai_conversations') THEN
        CREATE POLICY ai_conversations_owner_all ON public.ai_conversations
            FOR ALL
            USING (user_id = auth.uid() AND public.is_business_owner(business_id))
            WITH CHECK (user_id = auth.uid() AND public.is_business_owner(business_id));
    END IF;
END $$;

-- Policies for simulations
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'simulations_owner_all' AND tablename = 'simulations') THEN
        CREATE POLICY simulations_owner_all ON public.simulations
            FOR ALL
            USING (user_id = auth.uid() AND public.is_business_owner(business_id))
            WITH CHECK (user_id = auth.uid() AND public.is_business_owner(business_id));
    END IF;
END $$;
