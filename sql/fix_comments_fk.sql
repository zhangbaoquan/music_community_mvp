-- Fix article_comments Foreign Key to reference public.profiles instead of auth.users
-- This allows PostgREST to join profiles in queries

-- 1. Drop the existing foreign key constraint (referencing auth.users)
-- Note: The default name is usually article_comments_user_id_fkey
ALTER TABLE public.article_comments
DROP CONSTRAINT IF EXISTS article_comments_user_id_fkey;

-- 2. Add the new foreign key constraint (referencing public.profiles)
ALTER TABLE public.article_comments
ADD CONSTRAINT article_comments_user_id_fkey
FOREIGN KEY (user_id)
REFERENCES public.profiles(id)
ON DELETE CASCADE;
