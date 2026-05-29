-- ============================================================
-- 004: GROUP_MEMBERS TABLE
-- Junction table linking users to groups with roles
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

  -- Each user can only be in a group once
  CONSTRAINT unique_group_member UNIQUE (group_id, user_id)
);

COMMENT ON TABLE public.group_members IS 'Group membership with admin/member roles';
