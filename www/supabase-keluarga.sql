-- Jalankan SEKALI di Supabase > SQL Editor (setelah supabase.sql)
create table if not exists public.households (
  id uuid primary key default gen_random_uuid(),
  name text not null default 'Keluarga',
  owner uuid not null references auth.users(id) on delete cascade,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);
create table if not exists public.household_members (
  household_id uuid not null references public.households(id) on delete cascade,
  user_id uuid not null unique references auth.users(id) on delete cascade,
  email text not null,
  primary key (household_id, user_id)
);
create table if not exists public.household_invites (
  household_id uuid not null references public.households(id) on delete cascade,
  household_name text,
  email text not null,
  invited_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  primary key (household_id, email)
);
alter table public.households enable row level security;
alter table public.household_members enable row level security;
alter table public.household_invites enable row level security;

create or replace function public.is_member(h uuid) returns boolean
language sql security definer set search_path = public stable as
$$ select exists(select 1 from household_members where household_id = h and user_id = auth.uid()) $$;
create or replace function public.is_owner(h uuid) returns boolean
language sql security definer set search_path = public stable as
$$ select exists(select 1 from households where id = h and owner = auth.uid()) $$;
create or replace function public.has_invite(h uuid) returns boolean
language sql security definer set search_path = public stable as
$$ select exists(select 1 from household_invites where household_id = h and lower(email) = lower(auth.jwt()->>'email')) $$;

drop policy if exists "hh select" on public.households;
create policy "hh select" on public.households for select using (public.is_member(id) or owner = auth.uid());
drop policy if exists "hh insert" on public.households;
create policy "hh insert" on public.households for insert with check (owner = auth.uid());
drop policy if exists "hh update" on public.households;
create policy "hh update" on public.households for update using (public.is_member(id)) with check (public.is_member(id));
drop policy if exists "hh delete" on public.households;
create policy "hh delete" on public.households for delete using (owner = auth.uid());

drop policy if exists "mem select" on public.household_members;
create policy "mem select" on public.household_members for select using (public.is_member(household_id) or user_id = auth.uid());
drop policy if exists "mem insert" on public.household_members;
create policy "mem insert" on public.household_members for insert
  with check (user_id = auth.uid() and (public.is_owner(household_id) or public.has_invite(household_id)));
drop policy if exists "mem delete" on public.household_members;
create policy "mem delete" on public.household_members for delete using (user_id = auth.uid() or public.is_owner(household_id));

drop policy if exists "inv select" on public.household_invites;
create policy "inv select" on public.household_invites for select
  using (public.is_member(household_id) or lower(email) = lower(auth.jwt()->>'email'));
drop policy if exists "inv insert" on public.household_invites;
create policy "inv insert" on public.household_invites for insert
  with check (public.is_member(household_id) and invited_by = auth.uid());
drop policy if exists "inv delete" on public.household_invites;
create policy "inv delete" on public.household_invites for delete
  using (public.is_member(household_id) or lower(email) = lower(auth.jwt()->>'email'));

-- Hanya pemilik yang boleh mengubah nama atau pemilik grup (anggota hanya boleh mengubah data catatan)
create or replace function public.hh_guard() returns trigger language plpgsql as
$$ begin
  if (new.owner <> old.owner or new.name <> old.name or new.id <> old.id) and auth.uid() <> old.owner then
    raise exception 'Hanya pemilik yang boleh mengubah pengaturan grup';
  end if;
  return new;
end $$;
drop trigger if exists hh_guard on public.households;
create trigger hh_guard before update on public.households for each row execute function public.hh_guard();
