-- ============================================================
-- 006: EXPENSE_SPLITS TABLE
-- Individual share allocations per expense per user
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

  -- Each user has one split per expense
  CONSTRAINT unique_expense_split UNIQUE (expense_id, user_id)
);

CREATE TRIGGER set_expense_splits_updated_at
  BEFORE UPDATE ON public.expense_splits
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

COMMENT ON TABLE public.expense_splits IS 'Per-user share allocations for each expense';
