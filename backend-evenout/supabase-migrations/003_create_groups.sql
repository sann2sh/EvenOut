-- ============================================================
-- 003: GROUPS TABLE
-- Expense groups with invite code for QR-based joining
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
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

COMMENT ON TABLE public.groups IS 'Expense groups with QR-code invite system';
