-- Create article_comment_likes table
create table public.article_comment_likes (
  id uuid default gen_random_uuid() primary key,
  comment_id uuid references public.article_comments(id) on delete cascade not null,
  user_id uuid references auth.users(id) not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(comment_id, user_id)
);

-- Enable RLS
alter table public.article_comment_likes enable row level security;

-- Policies
create policy "Comment likes are public."
  on public.article_comment_likes for select
  using ( true );

create policy "Users can insert their own likes."
  on public.article_comment_likes for insert
  with check ( auth.uid() = user_id );

create policy "Users can delete their own likes."
  on public.article_comment_likes for delete
  using ( auth.uid() = user_id );

-- Realtime
alter publication supabase_realtime add table public.article_comment_likes;
