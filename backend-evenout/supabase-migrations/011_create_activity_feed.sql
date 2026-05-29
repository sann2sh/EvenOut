-- ============================================================
-- 011: ACTIVITY_FEED TABLE
-- Timeline of group events for the activity feed UI
-- ============================================================

CREATE TABLE IF NOT EXISTS public.activity_feed (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id      UUID REFERENCES public.groups(id) ON DELETE SET NULL,
  actor_id      UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  expense_id    UUID REFERENCES public.expenses(id) ON DELETE SET NULL,
  settlement_id UUID REFERENCES public.settlements(id) ON DELETE SET NULL,
  action_type   TEXT NOT NULL,         -- e.g. 'expense_created', 'settlement_confirmed', 'member_joined'
  description   TEXT,
  metadata      JSONB,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.activity_feed IS 'Group activity timeline for the feed UI';
