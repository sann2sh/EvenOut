-- ============================================================
-- 010: NOTIFICATIONS TABLE
-- Push notification records for the "Duolingo" nudge engine
-- ============================================================

CREATE TABLE IF NOT EXISTS public.notifications (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  actor_id      UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  group_id      UUID REFERENCES public.groups(id) ON DELETE SET NULL,
  expense_id    UUID REFERENCES public.expenses(id) ON DELETE SET NULL,
  settlement_id UUID REFERENCES public.settlements(id) ON DELETE SET NULL,
  type          TEXT NOT NULL,         -- e.g. 'nudge', 'expense_added', 'settlement_received', 'group_invite'
  title         TEXT NOT NULL,
  message       TEXT NOT NULL,
  is_sent       BOOLEAN NOT NULL DEFAULT FALSE,
  is_read       BOOLEAN NOT NULL DEFAULT FALSE,
  scheduled_at  TIMESTAMPTZ,
  sent_at       TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.notifications IS 'Notification records for context-aware nudges and app events';
