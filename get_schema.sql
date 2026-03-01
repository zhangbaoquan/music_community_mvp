SELECT 
    schemaname, 
    tablename, 
    tableowner, 
    rowsecurity 
FROM pg_tables 
WHERE tablename = 'app_logs';
