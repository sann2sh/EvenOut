-- ============================================================
-- 002: FRIENDSHIPS TABLE
-- Tracks friend requests and relationships between users
-- ============================================================

CREATE TABLE IF NOT EXISTS public.friendships (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  requester_id  UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  addressee_id  UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  status        TEXT NOT NULL DEFAULT 'pending'
                CHECK (status IN ('pending', 'accepted', 'declined', 'blocked')),
  requested_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  responded_at  TIMESTAMPTZ,

  -- Prevent duplicate friendship requests (A->B and B->A)
  CONSTRAINT unique_friendship UNIQUE (requester_id, addressee_id),
  -- Prevent self-friendship
  CONSTRAINT no_self_friendship CHECK (requester_id <> addressee_id)
);

COMMENT ON TABLE public.friendships IS 'Friend requests and relationships between users';
