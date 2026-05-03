-- sql/admin_get_users.sql
-- 获取带有精确最近活跃时间的用户列表（结合 auth.users 表的 last_sign_in_at）

CREATE OR REPLACE FUNCTION admin_get_users()
RETURNS TABLE (
  id uuid,
  username text,
  email text,
  avatar_url text,
  signature text,
  status text,
  banned_until timestamptz,
  created_at timestamptz,
  updated_at timestamptz,
  last_sign_in_at timestamptz
) 
SECURITY DEFINER -- 允许函数访问 auth.users 表
SET search_path = public
AS $$
BEGIN
  -- 安全检查：仅限管理员调用
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND is_admin = true) THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  RETURN QUERY
  SELECT 
    p.id,
    p.username,
    p.email,
    p.avatar_url,
    p.signature,
    p.status,
    p.banned_until,
    u.created_at,
    p.updated_at,
    (
      -- 取以下所有可能发生活跃事件的最新时间
      SELECT MAX(t) FROM (
        VALUES 
          (u.last_sign_in_at),
          (p.updated_at),
          ((SELECT MAX(articles.created_at) FROM articles WHERE articles.user_id = p.id)),
          ((SELECT MAX(article_comments.created_at) FROM article_comments WHERE article_comments.user_id = p.id)),
          ((SELECT MAX(article_likes.created_at) FROM article_likes WHERE article_likes.user_id = p.id))
      ) AS v(t)
    ) AS last_sign_in_at
  FROM profiles p
  LEFT JOIN auth.users u ON p.id = u.id
  ORDER BY 10 DESC NULLS LAST; -- 按照第 10 列 (综合最后的活跃时间) 倒序排列
END;
$$ LANGUAGE plpgsql;
