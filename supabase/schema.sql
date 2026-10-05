-- Campus Event Manager - Supabase schema
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default 'Student',
  role text not null default 'student' check (role in ('student','admin')),
  created_at timestamptz not null default now()
);

create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  category text not null,
  event_date date not null,
  event_time text not null,
  venue text not null,
  capacity integer not null check (capacity > 0),
  description text not null,
  organizer text not null default 'Campus Event Team',
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.registrations (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(event_id, user_id)
);

alter table public.profiles enable row level security;
alter table public.events enable row level security;
alter table public.registrations enable row level security;

drop policy if exists "profiles own read" on public.profiles;
create policy "profiles own read" on public.profiles for select using (auth.uid() = id);
drop policy if exists "profiles own insert" on public.profiles;
create policy "profiles own insert" on public.profiles for insert with check (auth.uid() = id);
drop policy if exists "profiles own update" on public.profiles;
create policy "profiles own update" on public.profiles for update using (auth.uid() = id);

drop policy if exists "events public read" on public.events;
create policy "events public read" on public.events for select using (true);
drop policy if exists "admins insert events" on public.events;
create policy "admins insert events" on public.events for insert with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role='admin'));
drop policy if exists "admins update events" on public.events;
create policy "admins update events" on public.events for update using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role='admin'));
drop policy if exists "admins delete events" on public.events;
create policy "admins delete events" on public.events for delete using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role='admin'));

drop policy if exists "registrations own read" on public.registrations;
create policy "registrations own read" on public.registrations for select using (auth.uid() = user_id or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role='admin'));
drop policy if exists "registrations own insert" on public.registrations;
create policy "registrations own insert" on public.registrations for insert with check (auth.uid() = user_id);
drop policy if exists "registrations own delete" on public.registrations;
create policy "registrations own delete" on public.registrations for delete using (auth.uid() = user_id or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role='admin'));

create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles(id, full_name) values (new.id, coalesce(new.raw_user_meta_data->>'full_name','Student')) on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

insert into public.events (title,category,event_date,event_time,venue,capacity,description,organizer)
select * from (values
('Tech Symposium 2026','Technical','2026-10-10','10:00 AM','Main Auditorium',120,'A full-day technical symposium with coding, project expo and expert sessions.','Department of IT'),
('CodeSprint Challenge','Hackathon','2026-10-18','9:00 AM','Innovation Lab',80,'Build, pitch and solve real-world problems in a fast-paced coding challenge.','Coding Club'),
('Campus Cultural Fest','Cultural','2026-10-25','4:00 PM','Open Air Stage',500,'Music, dance, arts and performances celebrating campus talent.','Student Council'),
('Career & Placement Drive','Career','2026-11-02','10:30 AM','Seminar Hall',250,'Meet recruiters, attend career sessions and explore placement opportunities.','Placement Cell')
) as v(title,category,event_date,event_time,venue,capacity,description,organizer)
where not exists (select 1 from public.events);
