-- ============================================================
-- 009: AUDIT_LOGS TABLE
-- Immutable log of all data mutations for compliance/debugging
-- ============================================================

CREATE TABLE IF NOT EXISTS public.audit_logs (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id      UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  group_id      UUID REFERENCES public.groups(id) ON DELETE SET NULL,
  expense_id    UUID REFERENCES public.expenses(id) ON DELETE SET NULL,
  settlement_id UUID REFERENCES public.settlements(id) ON DELETE SET NULL,
  entity_type   TEXT NOT NULL,         -- e.g. 'expense', 'settlement', 'group', 'user'
  action        TEXT NOT NULL,         -- e.g. 'create', 'update', 'delete', 'settle'
  old_data      JSONB,
  new_data      JSONB,
  ip_address    TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.audit_logs IS 'Immutable audit trail for all data mutations';
