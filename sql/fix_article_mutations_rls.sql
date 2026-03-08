-- Fix RLS Policies for Article Mutations (Likes, Collections, Comment Likes)

-- 1. article_likes
ALTER TABLE public.article_likes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can insert their own likes" ON public.article_likes;
CREATE POLICY "Users can insert their own likes"
ON public.article_likes FOR INSERT TO authenticated
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own likes" ON public.article_likes;
CREATE POLICY "Users can delete their own likes"
ON public.article_likes FOR DELETE TO authenticated
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Anyone can view likes" ON public.article_likes;
CREATE POLICY "Anyone can view likes"
ON public.article_likes FOR SELECT TO public
USING (true);

-- 2. article_collections
ALTER TABLE public.article_collections ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can insert their own collections" ON public.article_collections;
CREATE POLICY "Users can insert their own collections"
ON public.article_collections FOR INSERT TO authenticated
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own collections" ON public.article_collections;
CREATE POLICY "Users can delete their own collections"
ON public.article_collections FOR DELETE TO authenticated
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Anyone can view collections" ON public.article_collections;
CREATE POLICY "Anyone can view collections"
ON public.article_collections FOR SELECT TO public
USING (true);

-- 3. article_comment_likes
ALTER TABLE public.article_comment_likes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can insert their own comment likes" ON public.article_comment_likes;
CREATE POLICY "Users can insert their own comment likes"
ON public.article_comment_likes FOR INSERT TO authenticated
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own comment likes" ON public.article_comment_likes;
CREATE POLICY "Users can delete their own comment likes"
ON public.article_comment_likes FOR DELETE TO authenticated
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Anyone can view comment likes" ON public.article_comment_likes;
CREATE POLICY "Anyone can view comment likes"
ON public.article_comment_likes FOR SELECT TO public
USING (true);
