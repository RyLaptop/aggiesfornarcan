-- Run once in the Supabase SQL editor.
create table if not exists petition_signatures (
  id bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  name text not null check (char_length(name) between 2 and 100),
  email text not null check (email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$' and char_length(email) <= 254),
  affiliation text not null check (affiliation in ('student','parent','former_student','faculty_staff','community')),
  class_year smallint check (class_year between 1950 and 2035),
  comment text check (char_length(comment) <= 500),
  heard_from text check (char_length(heard_from) <= 200),
  contact_ok boolean not null default false,
  esign_consent boolean not null check (esign_consent),  -- must be true
  consent_version text not null default 'v1'              -- bump when the consent wording changes
);

-- One signature per email, case-insensitive.
create unique index if not exists petition_email_uniq on petition_signatures (lower(email));

alter table petition_signatures enable row level security;

-- Public can insert only. No select/update/delete for anon, so emails stay private.
drop policy if exists "anon insert" on petition_signatures;
create policy "anon insert" on petition_signatures for insert to anon with check (true);

-- Required when "Automatically expose new tables" is off: the public form may insert, nothing else.
grant usage on schema public to anon;
grant insert on petition_signatures to anon;

-- Public count, nothing else.
create or replace function signature_count() returns bigint
language sql security definer set search_path = public as
$$ select count(*) from petition_signatures $$;
grant execute on function signature_count() to anon;

-- Migration for tables created before heard_from existed (run once):
-- alter table petition_signatures add column if not exists heard_from text check (char_length(heard_from) <= 200);
