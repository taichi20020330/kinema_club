-- kinema_club 用の Supabase 初期設定
-- Supabase の SQL Editor に貼り付けて、そのまま Run してください。

-- 1. 映画のリクエストを入れる表
create table if not exists public.movies (
  id          uuid primary key default gen_random_uuid(),
  title       text not null check (char_length(title) between 1 and 80),
  year        text check (char_length(year) <= 60),
  note        text check (char_length(note) <= 300),
  image_path  text,
  by_name     text check (char_length(by_name) <= 20),
  created_by  text,
  votes       jsonb not null default '{}'::jsonb,   -- { 端末ID: 名前 }
  watched     boolean not null default false,
  created_at  timestamptz not null default now()
);

-- 2. ログインなしで誰でも読み書きできるようにする（友達内で使う前提）
alter table public.movies enable row level security;

drop policy if exists "movies read"   on public.movies;
drop policy if exists "movies insert" on public.movies;
drop policy if exists "movies update" on public.movies;
drop policy if exists "movies delete" on public.movies;

create policy "movies read"   on public.movies for select to anon using (true);
create policy "movies insert" on public.movies for insert to anon with check (true);
create policy "movies update" on public.movies for update to anon using (true) with check (true);
create policy "movies delete" on public.movies for delete to anon using (true);

-- 3. 他の人の投稿がすぐ画面に反映されるようにする
alter publication supabase_realtime add table public.movies;

-- 4. ポスター画像の置き場所（公開バケット、1枚5MBまで、画像のみ）
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('posters', 'posters', true, 5242880, array['image/jpeg','image/png','image/webp','image/gif'])
on conflict (id) do update set public = true, file_size_limit = 5242880,
  allowed_mime_types = array['image/jpeg','image/png','image/webp','image/gif'];

drop policy if exists "posters upload" on storage.objects;
drop policy if exists "posters read"   on storage.objects;
drop policy if exists "posters delete" on storage.objects;

create policy "posters upload" on storage.objects for insert to anon with check (bucket_id = 'posters');
create policy "posters read"   on storage.objects for select to anon using (bucket_id = 'posters');
create policy "posters delete" on storage.objects for delete to anon using (bucket_id = 'posters');
