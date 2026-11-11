-- 感想機能の追加（kinema_club）
-- Supabase の SQL Editor に貼り付けて Run してください。何度実行しても大丈夫です。

create table if not exists public.reviews (
  id          uuid primary key default gen_random_uuid(),
  movie_id    uuid not null references public.movies(id) on delete cascade,
  name        text check (char_length(name) <= 20),
  author_id   text,
  body        text not null check (char_length(body) between 1 and 1000),
  created_at  timestamptz not null default now()
);

alter table public.reviews enable row level security;

drop policy if exists "reviews read"   on public.reviews;
drop policy if exists "reviews insert" on public.reviews;
drop policy if exists "reviews delete" on public.reviews;

create policy "reviews read"   on public.reviews for select to anon using (true);
create policy "reviews insert" on public.reviews for insert to anon with check (true);
create policy "reviews delete" on public.reviews for delete to anon using (true);

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'reviews'
  ) then
    alter publication supabase_realtime add table public.reviews;
  end if;
end $$;

-- 一覧と感想をまとめて読み込めるよう、APIの設定を読み直す
notify pgrst, 'reload schema';
