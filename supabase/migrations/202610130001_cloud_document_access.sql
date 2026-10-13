create table if not exists public.app_users (
  id text primary key,
  email text not null,
  email_verified boolean not null default false,
  display_name text not null default '',
  photo_url text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.app_users
  add column if not exists email_verified boolean not null default false;

create table if not exists public.documents (
  id text primary key,
  owner_id text not null references public.app_users(id) on delete cascade,
  title text not null check (length(trim(title)) > 0),
  course text not null check (length(trim(course)) > 0),
  category text not null check (category in ('lesson', 'assignment', 'reference')),
  description text not null default '',
  link text not null default '',
  author text not null default '',
  semester text not null default '',
  tags text[] not null default '{}',
  attachment_name text not null default '',
  attachment_path text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.document_permissions (
  document_id text not null references public.documents(id) on delete cascade,
  user_id text not null references public.app_users(id) on delete cascade,
  access_level text not null check (access_level in ('view', 'edit')),
  granted_by text not null references public.app_users(id),
  created_at timestamptz not null default now(),
  primary key (document_id, user_id),
  check (granted_by <> user_id)
);

create index if not exists documents_owner_updated_idx
  on public.documents (owner_id, updated_at desc);
create index if not exists document_permissions_user_idx
  on public.document_permissions (user_id, document_id);
create unique index if not exists documents_attachment_path_uidx
  on public.documents (attachment_path)
  where attachment_path <> '';
create unique index if not exists app_users_email_lower_uidx
  on public.app_users (lower(email));

create or replace function public.current_firebase_uid()
returns text language sql stable
as $$ select nullif(auth.jwt() ->> 'sub', '') $$;

create or replace function public.can_read_document(target_id text)
returns boolean language sql stable security definer
set search_path = pg_catalog, public
as $$
  select exists (
    select 1 from public.documents d
    where d.id = target_id
      and (
        d.owner_id = public.current_firebase_uid()
        or exists (
          select 1 from public.document_permissions p
          where p.document_id = d.id
            and p.user_id = public.current_firebase_uid()
        )
      )
  )
$$;

create or replace function public.can_edit_document(target_id text)
returns boolean language sql stable security definer
set search_path = pg_catalog, public
as $$
  select exists (
    select 1 from public.documents d
    where d.id = target_id
      and (
        d.owner_id = public.current_firebase_uid()
        or exists (
          select 1 from public.document_permissions p
          where p.document_id = d.id
            and p.user_id = public.current_firebase_uid()
            and p.access_level = 'edit'
        )
      )
  )
$$;

create or replace function public.owns_document(target_id text)
returns boolean language sql stable security definer
set search_path = pg_catalog, public
as $$
  select exists (
    select 1 from public.documents d
    where d.id = target_id and d.owner_id = public.current_firebase_uid()
  )
$$;

create or replace function public.prevent_document_owner_change()
returns trigger language plpgsql
set search_path = pg_catalog, public
as $$
begin
  if new.owner_id <> old.owner_id then
    raise exception 'Document owner cannot be changed';
  end if;
  if (
    new.attachment_path is distinct from old.attachment_path
    or new.attachment_name is distinct from old.attachment_name
  )
     and old.owner_id <> public.current_firebase_uid() then
    raise exception 'Only the owner can replace an attachment';
  end if;
  return new;
end
$$;

drop trigger if exists documents_protect_owner on public.documents;
create trigger documents_protect_owner
before update on public.documents
for each row execute function public.prevent_document_owner_change();

create or replace function public.share_document(
  p_document_id text,
  p_email text,
  p_access_level text
)
returns table (user_id text, email text, display_name text, access_level text)
language plpgsql security definer
set search_path = pg_catalog, public
as $$
declare
  caller_id text := public.current_firebase_uid();
  recipient public.app_users%rowtype;
begin
  if caller_id is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if p_access_level not in ('view', 'edit') then
    raise exception 'Invalid access level' using errcode = '22023';
  end if;
  if not public.owns_document(p_document_id) then
    raise exception 'Only the document owner can share it' using errcode = '42501';
  end if;

  select u.* into recipient
  from public.app_users u
  where lower(u.email) = lower(trim(p_email))
    and u.email_verified
    and u.id <> caller_id
  limit 1;
  if recipient.id is null then
    raise exception 'No registered user found for that email' using errcode = 'P0002';
  end if;

  insert into public.document_permissions (
    document_id, user_id, access_level, granted_by
  ) values (p_document_id, recipient.id, p_access_level, caller_id)
  on conflict (document_id, user_id) do update
    set access_level = excluded.access_level,
        granted_by = excluded.granted_by;

  return query
  select recipient.id, recipient.email, recipient.display_name, p_access_level;
end
$$;

alter table public.app_users enable row level security;
alter table public.documents enable row level security;
alter table public.document_permissions enable row level security;

drop policy if exists app_users_select_self on public.app_users;
create policy app_users_select_self on public.app_users
for select to authenticated
using (id = public.current_firebase_uid());

drop policy if exists app_users_insert_self on public.app_users;
create policy app_users_insert_self on public.app_users
for insert to authenticated
with check (
  id = public.current_firebase_uid()
  and email = auth.jwt() ->> 'email'
  and email_verified = coalesce((auth.jwt() ->> 'email_verified')::boolean, false)
);

drop policy if exists app_users_update_self on public.app_users;
create policy app_users_update_self on public.app_users
for update to authenticated
using (id = public.current_firebase_uid())
with check (
  id = public.current_firebase_uid()
  and email = auth.jwt() ->> 'email'
  and email_verified = coalesce((auth.jwt() ->> 'email_verified')::boolean, false)
);

drop policy if exists documents_select_authorized on public.documents;
create policy documents_select_authorized on public.documents
for select to authenticated using (public.can_read_document(id));

drop policy if exists documents_insert_owner on public.documents;
create policy documents_insert_owner on public.documents
for insert to authenticated
with check (owner_id = public.current_firebase_uid());

drop policy if exists documents_update_editor on public.documents;
create policy documents_update_editor on public.documents
for update to authenticated
using (public.can_edit_document(id))
with check (public.can_edit_document(id));

drop policy if exists documents_delete_owner on public.documents;
create policy documents_delete_owner on public.documents
for delete to authenticated
using (owner_id = public.current_firebase_uid());

drop policy if exists permissions_select_participant on public.document_permissions;
create policy permissions_select_participant on public.document_permissions
for select to authenticated
using (
  user_id = public.current_firebase_uid()
  or public.owns_document(document_id)
);

grant usage on schema public to authenticated;
grant select, insert, update on public.app_users to authenticated;
grant select, insert, update, delete on public.documents to authenticated;
grant select on public.document_permissions to authenticated;
grant execute on function public.current_firebase_uid() to authenticated;
grant execute on function public.can_read_document(text) to authenticated;
grant execute on function public.can_edit_document(text) to authenticated;
grant execute on function public.owns_document(text) to authenticated;
revoke all on function public.share_document(text, text, text) from public, anon;
grant execute on function public.share_document(text, text, text) to authenticated;
revoke all on function public.can_read_document(text) from public, anon;
revoke all on function public.can_edit_document(text) from public, anon;
revoke all on function public.owns_document(text) from public, anon;