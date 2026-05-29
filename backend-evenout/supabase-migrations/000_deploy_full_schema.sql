-- ============================================================
-- EVENOUT: FULL DATABASE DEPLOYMENT
-- Run this single file in Supabase SQL Editor to deploy
-- the complete database schema in one shot.
--
-- Order: Tables → View → RLS Policies → Indexes
-- ============================================================

BEGIN;

-- ============================================================
-- UTILITY FUNCTIONS
-- ============================================================

-- Auto-update updated_at on row modification
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Auto-create a public.users row when a new auth user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, display_name, avatar_url)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
    NEW.raw_user_meta_data->>'avatar_url'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ============================================================
-- 001: USERS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.users (
  id            UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  phone_number  TEXT UNIQUE,
  email         TEXT UNIQUE,
  display_name  TEXT,
  avatar_url    TEXT,
  split_score   INTEGER NOT NULL DEFAULT 500,
  timely_settlements  INTEGER NOT NULL DEFAULT 0,
  overdue_days_total  INTEGER NOT NULL DEFAULT 0,
  fcm_token     TEXT,
  is_active     BOOLEAN NOT NULL DEFAULT TRUE,
  last_seen_at  TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER set_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- ============================================================
-- 002: FRIENDSHIPS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.friendships (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  requester_id  UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  addressee_id  UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  status        TEXT NOT NULL DEFAULT 'pending'
                CHECK (status IN ('pending', 'accepted', 'declined', 'blocked')),
  requested_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  responded_at  TIMESTAMPTZ,
  CONSTRAINT unique_friendship UNIQUE (requester_id, addressee_id),
  CONSTRAINT no_self_friendship CHECK (requester_id <> addressee_id)
);


-- ============================================================
-- 003: GROUPS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.groups (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT NOT NULL,
  description   TEXT,
  avatar_url    TEXT,
  created_by    UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  invite_code   TEXT UNIQUE NOT NULL,
  invite_qr_url TEXT,
  is_archived   BOOLEAN NOT NULL DEFAULT FALSE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER set_groups_updated_at
  BEFORE UPDATE ON public.groups
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();


-- ============================================================
-- 004: GROUP_MEMBERS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.group_members (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id    UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  role        TEXT NOT NULL DEFAULT 'member'
              CHECK (role IN ('admin', 'member')),
  is_active   BOOLEAN NOT NULL DEFAULT TRUE,
  joined_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  left_at     TIMESTAMPTZ,
  CONSTRAINT unique_group_member UNIQUE (group_id, user_id)
);


-- ============================================================
-- 005: EXPENSES
-- ============================================================
CREATE TABLE IF NOT EXISTS public.expenses (
  id                UUID PRIMARY KEY,
  group_id          UUID REFERENCES public.groups(id) ON DELETE SET NULL,
  paid_by           UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  created_by        UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  title             TEXT NOT NULL,
  description       TEXT,
  category          TEXT,
  total_amount      NUMERIC(12, 2) NOT NULL CHECK (total_amount > 0),
  split_mode        TEXT NOT NULL DEFAULT 'equal'
                    CHECK (split_mode IN ('equal', 'exact', 'percentage', 'chaos_roulette')),
  is_deleted        BOOLEAN NOT NULL DEFAULT FALSE,
  version           INTEGER NOT NULL DEFAULT 1,
  expense_date      TIMESTAMPTZ,
  client_created_at TIMESTAMPTZ,
  synced_at         TIMESTAMPTZ DEFAULT NOW()
);


-- ============================================================
-- 006: EXPENSE_SPLITS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.expense_splits (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  expense_id  UUID NOT NULL REFERENCES public.expenses(id) ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  amount_owed NUMERIC(12, 2) NOT NULL CHECK (amount_owed >= 0),
  percentage  NUMERIC(5, 2),
  is_settled  BOOLEAN NOT NULL DEFAULT FALSE,
  settled_at  TIMESTAMPTZ,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_expense_split UNIQUE (expense_id, user_id)
);

CREATE TRIGGER set_expense_splits_updated_at
  BEFORE UPDATE ON public.expense_splits
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();


-- ============================================================
-- 007: SETTLEMENTS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.settlements (
  id                    UUID PRIMARY KEY,
  group_id              UUID REFERENCES public.groups(id) ON DELETE SET NULL,
  payer_id              UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  payee_id              UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  amount                NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
  status                TEXT NOT NULL DEFAULT 'pending'
                        CHECK (status IN ('pending', 'confirmed', 'rejected')),
  payment_method        TEXT,
  esewa_transaction_id  TEXT,
  note                  TEXT,
  version               INTEGER NOT NULL DEFAULT 1,
  client_created_at     TIMESTAMPTZ,
  confirmed_at          TIMESTAMPTZ,
  synced_at             TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT no_self_settlement CHECK (payer_id <> payee_id)
);


-- ============================================================
-- 008: RECEIPTS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.receipts (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  expense_id        UUID NOT NULL REFERENCES public.expenses(id) ON DELETE CASCADE UNIQUE,
  storage_path      TEXT,
  public_url        TEXT,
  raw_ocr_text      JSONB,
  parsed_line_items JSONB,
  ocr_status        TEXT NOT NULL DEFAULT 'pending'
                    CHECK (ocr_status IN ('pending', 'processing', 'completed', 'failed')),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- 009: AUDIT_LOGS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.audit_logs (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id      UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  group_id      UUID REFERENCES public.groups(id) ON DELETE SET NULL,
  expense_id    UUID REFERENCES public.expenses(id) ON DELETE SET NULL,
  settlement_id UUID REFERENCES public.settlements(id) ON DELETE SET NULL,
  entity_type   TEXT NOT NULL,
  action        TEXT NOT NULL,
  old_data      JSONB,
  new_data      JSONB,
  ip_address    TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- 010: NOTIFICATIONS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.notifications (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  actor_id      UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  group_id      UUID REFERENCES public.groups(id) ON DELETE SET NULL,
  expense_id    UUID REFERENCES public.expenses(id) ON DELETE SET NULL,
  settlement_id UUID REFERENCES public.settlements(id) ON DELETE SET NULL,
  type          TEXT NOT NULL,
  title         TEXT NOT NULL,
  message       TEXT NOT NULL,
  is_sent       BOOLEAN NOT NULL DEFAULT FALSE,
  is_read       BOOLEAN NOT NULL DEFAULT FALSE,
  scheduled_at  TIMESTAMPTZ,
  sent_at       TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- 011: ACTIVITY_FEED
-- ============================================================
CREATE TABLE IF NOT EXISTS public.activity_feed (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id      UUID REFERENCES public.groups(id) ON DELETE SET NULL,
  actor_id      UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  expense_id    UUID REFERENCES public.expenses(id) ON DELETE SET NULL,
  settlement_id UUID REFERENCES public.settlements(id) ON DELETE SET NULL,
  action_type   TEXT NOT NULL,
  description   TEXT,
  metadata      JSONB,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- 012: PEER_BALANCES VIEW
-- ============================================================
CREATE OR REPLACE VIEW public.peer_balances AS
WITH total_owed AS (
    SELECT 
        es.user_id AS debtor_id,
        e.paid_by AS creditor_id,
        e.group_id,
        SUM(es.amount_owed) AS amount
    FROM public.expense_splits es
    JOIN public.expenses e ON es.expense_id = e.id
    WHERE es.is_settled = FALSE AND e.is_deleted = FALSE
    GROUP BY es.user_id, e.paid_by, e.group_id
),
total_paid AS (
    SELECT 
        payer_id AS debtor_id,
        payee_id AS creditor_id,
        group_id,
        SUM(amount) AS amount
    FROM public.settlements
    WHERE status = 'confirmed'
    GROUP BY payer_id, payee_id, group_id
)
SELECT 
    COALESCE(o.debtor_id, p.debtor_id) AS user_id,
    COALESCE(o.creditor_id, p.creditor_id) AS counterpart_id,
    COALESCE(o.group_id, p.group_id) AS group_id,
    COALESCE(o.amount, 0) - COALESCE(p.amount, 0) AS net_debt
FROM total_owed o
FULL OUTER JOIN total_paid p 
ON o.debtor_id = p.debtor_id 
   AND o.creditor_id = p.creditor_id
   AND o.group_id IS NOT DISTINCT FROM p.group_id;


-- ============================================================
-- 013: ROW-LEVEL SECURITY POLICIES
-- ============================================================

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.friendships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expense_splits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.settlements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.receipts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_feed ENABLE ROW LEVEL SECURITY;

-- USERS
CREATE POLICY "users_select" ON public.users FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "users_update" ON public.users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "users_insert" ON public.users FOR INSERT WITH CHECK (auth.uid() = id);

-- FRIENDSHIPS
CREATE POLICY "friendships_select" ON public.friendships FOR SELECT USING (auth.uid() = requester_id OR auth.uid() = addressee_id);
CREATE POLICY "friendships_insert" ON public.friendships FOR INSERT WITH CHECK (auth.uid() = requester_id);
CREATE POLICY "friendships_update" ON public.friendships FOR UPDATE USING (auth.uid() = addressee_id);

-- GROUPS
CREATE POLICY "groups_select" ON public.groups FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.group_members gm WHERE gm.group_id = groups.id AND gm.user_id = auth.uid() AND gm.is_active = TRUE)
);
CREATE POLICY "groups_insert" ON public.groups FOR INSERT WITH CHECK (auth.uid() = created_by);
CREATE POLICY "groups_update" ON public.groups FOR UPDATE USING (
  EXISTS (SELECT 1 FROM public.group_members gm WHERE gm.group_id = groups.id AND gm.user_id = auth.uid() AND gm.role = 'admin')
);

-- GROUP_MEMBERS
CREATE POLICY "group_members_select" ON public.group_members FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.group_members gm2 WHERE gm2.group_id = group_members.group_id AND gm2.user_id = auth.uid() AND gm2.is_active = TRUE)
);
CREATE POLICY "group_members_insert" ON public.group_members FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "group_members_update" ON public.group_members FOR UPDATE USING (
  auth.uid() = user_id OR EXISTS (SELECT 1 FROM public.group_members gm2 WHERE gm2.group_id = group_members.group_id AND gm2.user_id = auth.uid() AND gm2.role = 'admin')
);

-- EXPENSES
CREATE POLICY "expenses_select" ON public.expenses FOR SELECT USING (
  paid_by = auth.uid() OR created_by = auth.uid() OR
  EXISTS (SELECT 1 FROM public.group_members gm WHERE gm.group_id = expenses.group_id AND gm.user_id = auth.uid() AND gm.is_active = TRUE)
);
CREATE POLICY "expenses_insert" ON public.expenses FOR INSERT WITH CHECK (auth.uid() = created_by);
CREATE POLICY "expenses_update" ON public.expenses FOR UPDATE USING (auth.uid() = created_by);

-- EXPENSE_SPLITS
CREATE POLICY "expense_splits_select" ON public.expense_splits FOR SELECT USING (
  user_id = auth.uid() OR EXISTS (
    SELECT 1 FROM public.expenses e JOIN public.group_members gm ON gm.group_id = e.group_id
    WHERE e.id = expense_splits.expense_id AND gm.user_id = auth.uid() AND gm.is_active = TRUE
  )
);
CREATE POLICY "expense_splits_insert" ON public.expense_splits FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM public.expenses e WHERE e.id = expense_splits.expense_id AND e.created_by = auth.uid())
);
CREATE POLICY "expense_splits_update" ON public.expense_splits FOR UPDATE USING (
  EXISTS (SELECT 1 FROM public.expenses e WHERE e.id = expense_splits.expense_id AND e.created_by = auth.uid())
);

-- SETTLEMENTS
CREATE POLICY "settlements_select" ON public.settlements FOR SELECT USING (
  payer_id = auth.uid() OR payee_id = auth.uid() OR
  EXISTS (SELECT 1 FROM public.group_members gm WHERE gm.group_id = settlements.group_id AND gm.user_id = auth.uid() AND gm.is_active = TRUE)
);
CREATE POLICY "settlements_insert" ON public.settlements FOR INSERT WITH CHECK (auth.uid() = payer_id);
CREATE POLICY "settlements_update" ON public.settlements FOR UPDATE USING (auth.uid() = payer_id OR auth.uid() = payee_id);

-- RECEIPTS
CREATE POLICY "receipts_select" ON public.receipts FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.expenses e WHERE e.id = receipts.expense_id AND (
    e.created_by = auth.uid() OR e.paid_by = auth.uid() OR
    EXISTS (SELECT 1 FROM public.group_members gm WHERE gm.group_id = e.group_id AND gm.user_id = auth.uid() AND gm.is_active = TRUE)
  ))
);
CREATE POLICY "receipts_insert" ON public.receipts FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM public.expenses e WHERE e.id = receipts.expense_id AND e.created_by = auth.uid())
);

-- AUDIT_LOGS (read-only for users, inserts by service role)
CREATE POLICY "audit_logs_select" ON public.audit_logs FOR SELECT USING (
  actor_id = auth.uid() OR EXISTS (SELECT 1 FROM public.group_members gm WHERE gm.group_id = audit_logs.group_id AND gm.user_id = auth.uid() AND gm.is_active = TRUE)
);

-- NOTIFICATIONS
CREATE POLICY "notifications_select" ON public.notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "notifications_update" ON public.notifications FOR UPDATE USING (auth.uid() = user_id);

-- ACTIVITY_FEED
CREATE POLICY "activity_feed_select" ON public.activity_feed FOR SELECT USING (
  actor_id = auth.uid() OR EXISTS (SELECT 1 FROM public.group_members gm WHERE gm.group_id = activity_feed.group_id AND gm.user_id = auth.uid() AND gm.is_active = TRUE)
);


-- ============================================================
-- 014: PERFORMANCE INDEXES
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_users_phone ON public.users(phone_number);
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_is_active ON public.users(is_active);

CREATE INDEX IF NOT EXISTS idx_friendships_requester ON public.friendships(requester_id);
CREATE INDEX IF NOT EXISTS idx_friendships_addressee ON public.friendships(addressee_id);
CREATE INDEX IF NOT EXISTS idx_friendships_status ON public.friendships(status);

CREATE INDEX IF NOT EXISTS idx_groups_created_by ON public.groups(created_by);
CREATE INDEX IF NOT EXISTS idx_groups_invite_code ON public.groups(invite_code);
CREATE INDEX IF NOT EXISTS idx_groups_is_archived ON public.groups(is_archived);

CREATE INDEX IF NOT EXISTS idx_group_members_group ON public.group_members(group_id);
CREATE INDEX IF NOT EXISTS idx_group_members_user ON public.group_members(user_id);
CREATE INDEX IF NOT EXISTS idx_group_members_active ON public.group_members(group_id, user_id, is_active);

CREATE INDEX IF NOT EXISTS idx_expenses_group ON public.expenses(group_id);
CREATE INDEX IF NOT EXISTS idx_expenses_paid_by ON public.expenses(paid_by);
CREATE INDEX IF NOT EXISTS idx_expenses_created_by ON public.expenses(created_by);
CREATE INDEX IF NOT EXISTS idx_expenses_not_deleted ON public.expenses(group_id) WHERE is_deleted = FALSE;

CREATE INDEX IF NOT EXISTS idx_expense_splits_expense ON public.expense_splits(expense_id);
CREATE INDEX IF NOT EXISTS idx_expense_splits_user ON public.expense_splits(user_id);
CREATE INDEX IF NOT EXISTS idx_expense_splits_unsettled ON public.expense_splits(user_id) WHERE is_settled = FALSE;

CREATE INDEX IF NOT EXISTS idx_settlements_group ON public.settlements(group_id);
CREATE INDEX IF NOT EXISTS idx_settlements_payer ON public.settlements(payer_id);
CREATE INDEX IF NOT EXISTS idx_settlements_payee ON public.settlements(payee_id);
CREATE INDEX IF NOT EXISTS idx_settlements_status ON public.settlements(status);
CREATE INDEX IF NOT EXISTS idx_settlements_confirmed ON public.settlements(payer_id, payee_id) WHERE status = 'confirmed';

CREATE INDEX IF NOT EXISTS idx_receipts_expense ON public.receipts(expense_id);
CREATE INDEX IF NOT EXISTS idx_receipts_ocr_status ON public.receipts(ocr_status);

CREATE INDEX IF NOT EXISTS idx_audit_logs_actor ON public.audit_logs(actor_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_group ON public.audit_logs(group_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created ON public.audit_logs(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON public.notifications(user_id) WHERE is_read = FALSE;
CREATE INDEX IF NOT EXISTS idx_notifications_unsent ON public.notifications(scheduled_at) WHERE is_sent = FALSE;

CREATE INDEX IF NOT EXISTS idx_activity_feed_group ON public.activity_feed(group_id);
CREATE INDEX IF NOT EXISTS idx_activity_feed_actor ON public.activity_feed(actor_id);
CREATE INDEX IF NOT EXISTS idx_activity_feed_created ON public.activity_feed(created_at DESC);

COMMIT;
