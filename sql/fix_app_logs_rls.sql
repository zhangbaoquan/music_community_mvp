-- 1. Enable RLS
ALTER TABLE app_logs ENABLE ROW LEVEL SECURITY;

-- 2. Allow users to insert their own logs
DROP POLICY IF EXISTS "Users can insert their own logs" ON app_logs;
CREATE POLICY "Users can insert their own logs"
ON app_logs FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- 3. Allow admins to view all logs
DROP POLICY IF EXISTS "Admins can view all logs" ON app_logs;
CREATE POLICY "Admins can view all logs"
ON app_logs FOR SELECT
TO authenticated
USING (
  (SELECT is_admin FROM profiles WHERE id = auth.uid()) = TRUE
);

-- 4. Allow admins to delete any logs
DROP POLICY IF EXISTS "Admins can delete any logs" ON app_logs;
CREATE POLICY "Admins can delete any logs"
ON app_logs FOR DELETE
TO authenticated
USING (
  (SELECT is_admin FROM profiles WHERE id = auth.uid()) = TRUE
);

-- 5. Allow users to view their own logs (Optional)
DROP POLICY IF EXISTS "Users can view their own logs" ON app_logs;
CREATE POLICY "Users can view their own logs"
ON app_logs FOR SELECT
TO authenticated
USING (auth.uid() = user_id);
