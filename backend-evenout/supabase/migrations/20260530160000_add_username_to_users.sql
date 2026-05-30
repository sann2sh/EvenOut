-- Add unique username column to users table
ALTER TABLE public.users
ADD COLUMN username VARCHAR(50) UNIQUE;

-- Add index for fast username lookups/search
CREATE INDEX idx_users_username ON public.users (username);
