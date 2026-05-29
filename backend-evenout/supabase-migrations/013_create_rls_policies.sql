-- ============================================================
-- 013: ROW-LEVEL SECURITY (RLS) POLICIES
-- Ensures users can only access data they're authorized for
-- ============================================================

-- Enable RLS on all tables
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

-- ======================== USERS ========================
-- Anyone authenticated can read user profiles (for search/display)
CREATE POLICY "users_select" ON public.users
  FOR SELECT USING (auth.role() = 'authenticated');

-- Users can only update their own profile
CREATE POLICY "users_update" ON public.users
  FOR UPDATE USING (auth.uid() = id);

-- Insert is handled by the trigger on auth.users, but allow service role
CREATE POLICY "users_insert" ON public.users
  FOR INSERT WITH CHECK (auth.uid() = id);

-- ======================== FRIENDSHIPS ========================
CREATE POLICY "friendships_select" ON public.friendships
  FOR SELECT USING (auth.uid() = requester_id OR auth.uid() = addressee_id);

CREATE POLICY "friendships_insert" ON public.friendships
  FOR INSERT WITH CHECK (auth.uid() = requester_id);

CREATE POLICY "friendships_update" ON public.friendships
  FOR UPDATE USING (auth.uid() = addressee_id);

-- ======================== GROUPS ========================
-- Users can see groups they belong to
CREATE POLICY "groups_select" ON public.groups
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.group_members gm
      WHERE gm.group_id = groups.id AND gm.user_id = auth.uid() AND gm.is_active = TRUE
    )
  );

CREATE POLICY "groups_insert" ON public.groups
  FOR INSERT WITH CHECK (auth.uid() = created_by);

-- Only group admins can update
CREATE POLICY "groups_update" ON public.groups
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.group_members gm
      WHERE gm.group_id = groups.id AND gm.user_id = auth.uid() AND gm.role = 'admin'
    )
  );

-- ======================== GROUP_MEMBERS ========================
CREATE POLICY "group_members_select" ON public.group_members
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.group_members gm2
      WHERE gm2.group_id = group_members.group_id AND gm2.user_id = auth.uid() AND gm2.is_active = TRUE
    )
  );

CREATE POLICY "group_members_insert" ON public.group_members
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "group_members_update" ON public.group_members
  FOR UPDATE USING (
    auth.uid() = user_id OR
    EXISTS (
      SELECT 1 FROM public.group_members gm2
      WHERE gm2.group_id = group_members.group_id AND gm2.user_id = auth.uid() AND gm2.role = 'admin'
    )
  );

-- ======================== EXPENSES ========================
CREATE POLICY "expenses_select" ON public.expenses
  FOR SELECT USING (
    paid_by = auth.uid() OR created_by = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.group_members gm
      WHERE gm.group_id = expenses.group_id AND gm.user_id = auth.uid() AND gm.is_active = TRUE
    )
  );

CREATE POLICY "expenses_insert" ON public.expenses
  FOR INSERT WITH CHECK (auth.uid() = created_by);

CREATE POLICY "expenses_update" ON public.expenses
  FOR UPDATE USING (auth.uid() = created_by);

-- ======================== EXPENSE_SPLITS ========================
CREATE POLICY "expense_splits_select" ON public.expense_splits
  FOR SELECT USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.expenses e
      JOIN public.group_members gm ON gm.group_id = e.group_id
      WHERE e.id = expense_splits.expense_id AND gm.user_id = auth.uid() AND gm.is_active = TRUE
    )
  );

CREATE POLICY "expense_splits_insert" ON public.expense_splits
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.expenses e WHERE e.id = expense_splits.expense_id AND e.created_by = auth.uid()
    )
  );

CREATE POLICY "expense_splits_update" ON public.expense_splits
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.expenses e WHERE e.id = expense_splits.expense_id AND e.created_by = auth.uid()
    )
  );

-- ======================== SETTLEMENTS ========================
CREATE POLICY "settlements_select" ON public.settlements
  FOR SELECT USING (
    payer_id = auth.uid() OR payee_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.group_members gm
      WHERE gm.group_id = settlements.group_id AND gm.user_id = auth.uid() AND gm.is_active = TRUE
    )
  );

CREATE POLICY "settlements_insert" ON public.settlements
  FOR INSERT WITH CHECK (auth.uid() = payer_id);

CREATE POLICY "settlements_update" ON public.settlements
  FOR UPDATE USING (auth.uid() = payer_id OR auth.uid() = payee_id);

-- ======================== RECEIPTS ========================
CREATE POLICY "receipts_select" ON public.receipts
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.expenses e WHERE e.id = receipts.expense_id AND (
        e.created_by = auth.uid() OR e.paid_by = auth.uid() OR
        EXISTS (
          SELECT 1 FROM public.group_members gm
          WHERE gm.group_id = e.group_id AND gm.user_id = auth.uid() AND gm.is_active = TRUE
        )
      )
    )
  );

CREATE POLICY "receipts_insert" ON public.receipts
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.expenses e WHERE e.id = receipts.expense_id AND e.created_by = auth.uid()
    )
  );

-- ======================== AUDIT_LOGS ========================
-- Read-only for group members; insert by service role only (from backend)
CREATE POLICY "audit_logs_select" ON public.audit_logs
  FOR SELECT USING (
    actor_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.group_members gm
      WHERE gm.group_id = audit_logs.group_id AND gm.user_id = auth.uid() AND gm.is_active = TRUE
    )
  );

-- ======================== NOTIFICATIONS ========================
CREATE POLICY "notifications_select" ON public.notifications
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "notifications_update" ON public.notifications
  FOR UPDATE USING (auth.uid() = user_id);

-- ======================== ACTIVITY_FEED ========================
CREATE POLICY "activity_feed_select" ON public.activity_feed
  FOR SELECT USING (
    actor_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.group_members gm
      WHERE gm.group_id = activity_feed.group_id AND gm.user_id = auth.uid() AND gm.is_active = TRUE
    )
  );
