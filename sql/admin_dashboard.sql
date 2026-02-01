-- Add is_admin column to profiles table
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT FALSE;

-- Create a policy to allow admins to delete ANY article
CREATE POLICY "Admins can delete any article"
ON articles
FOR DELETE
USING (
  (SELECT is_admin FROM profiles WHERE id = auth.uid()) = TRUE
);

-- Create a policy to allow admins to delete ANY comment
CREATE POLICY "Admins can delete any comment"
ON comments
FOR DELETE
USING (
  (SELECT is_admin FROM profiles WHERE id = auth.uid()) = TRUE
);

-- Create a policy to allow admins to delete ANY mood diary
CREATE POLICY "Admins can delete any diary"
ON mood_diaries
FOR DELETE
USING (
  (SELECT is_admin FROM profiles WHERE id = auth.uid()) = TRUE
);

-- Create a policy to allow admins to delete ANY song
CREATE POLICY "Admins can delete any song"
ON songs
FOR DELETE
USING (
  (SELECT is_admin FROM profiles WHERE id = auth.uid()) = TRUE
);

-- OPTIONAL: Allow admins to VIEW hidden/private content if we had that logic (currently mostly public)
-- But generally, SELECT policies might need checking if we have restrictive select policies.
-- For MVP, most read policies are "public" or "authenticated", so admin can read them too.

-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- IMPORTANT: YOU MUST RUN THIS MANUALLY IN SUPABASE SQL EDITOR
-- TO SET YOURSELF AS ADMIN:
-- update profiles set is_admin = true where id = 'YOUR_USER_ID';
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
